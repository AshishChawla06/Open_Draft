import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class BackupService {
  static const String _backupVersion = '1.0';

  /// Create a full backup of the library
  static Future<void> createBackup() async {
    try {
      final backupData = <String, dynamic>{
        'version': _backupVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': kIsWeb ? 'web' : 'mobile/desktop',
      };

      if (kIsWeb) {
        await _backupWeb(backupData);
      } else {
        await _backupMobile(backupData);
      }

      // Convert to JSON
      final jsonString = jsonEncode(backupData);
      final jsonBytes = utf8.encode(jsonString);

      // Create ZIP archive
      final archive = Archive();
      archive.addFile(
        ArchiveFile('open_draft_data.json', jsonBytes.length, jsonBytes),
      );

      // Future: Add images/assets to archive if needed

      final encoder = ZipEncoder();
      final zipBytes = encoder.encode(archive);

      if (zipBytes == null) {
        throw Exception('Failed to create backup archive');
      }

      // Save File
      final fileName =
          'opendraft_backup_${DateTime.now().millisecondsSinceEpoch}.zip';

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(zipBytes);
        await Share.shareXFiles([
          XFile(file.path),
        ], subject: 'OpenDraft Backup');
      } else {
        String? outputFile;
        try {
          outputFile = await FilePicker.platform.saveFile(
            dialogTitle: 'Save Backup',
            fileName: fileName,
            bytes: Uint8List.fromList(zipBytes),
            type: FileType.custom,
            allowedExtensions: ['zip'],
          );
        } catch (e) {
          // Fallback for Windows if saveFile is not implemented
          if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
            final String? selectedDirectory = await FilePicker.platform
                .getDirectoryPath(dialogTitle: 'Select Destination Folder');
            if (selectedDirectory != null) {
              outputFile =
                  '$selectedDirectory${Platform.pathSeparator}$fileName';
            }
          } else {
            rethrow;
          }
        }

        if (outputFile != null && !kIsWeb) {
          final file = File(outputFile);
          await file.writeAsBytes(zipBytes);
        }
      }
    } catch (e) {
      debugPrint('Backup failed: $e');
      rethrow;
    }
  }

  static Future<void> _backupWeb(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final webData = <String, dynamic>{};

    for (final key in keys) {
      // Only backup our app's data keys (filtering generic prefs if any)
      if (key.endsWith('_data')) {
        webData[key] = prefs.get(key);
      }
    }
    data['web_storage'] = webData;
  }

  static Future<void> _backupMobile(Map<String, dynamic> data) async {
    final db = await DatabaseService.database;

    // List of tables to backup
    final tables = [
      'books',
      'chapters',
      'scp_logs',
      'daily_stats',
      'notes',
      'snapshots',
      'bookmarks',
      'characters',
      'locations',
      'templates',
    ];

    for (final table in tables) {
      final records = await db.query(table);
      data[table] = records; // list of maps
    }
  }

  /// Restore library from a backup file
  static Future<void> restoreBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: true, // Needed for Web
      );

      if (result != null) {
        List<int>? bytes;
        if (kIsWeb) {
          bytes = result.files.single.bytes;
        } else {
          final path = result.files.single.path;
          if (path != null) {
            bytes = await File(path).readAsBytes();
          }
        }

        if (bytes != null) {
          await _processRestore(bytes);
        }
      }
    } catch (e) {
      debugPrint('Restore failed: $e');
      rethrow;
    }
  }

  static Future<void> _processRestore(List<int> bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final jsonFile = archive.findFile('open_draft_data.json');

    if (jsonFile == null) {
      throw Exception('Invalid backup: properties file missing');
    }

    final jsonString = utf8.decode(jsonFile.content);
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    if (kIsWeb) {
      await _restoreWeb(data);
    } else {
      await _restoreMobile(data);
    }
  }

  static Future<void> _restoreWeb(Map<String, dynamic> data) async {
    // If backup is from web, use 'web_storage'
    // If from mobile, we might need to convert table data to JSON storage structure
    // For now, let's assume same-platform restore or 'web_storage' key exists

    if (data.containsKey('web_storage')) {
      final prefs = await SharedPreferences.getInstance();
      final webData = data['web_storage'] as Map<String, dynamic>;
      for (final entry in webData.entries) {
        if (entry.value is String) {
          await prefs.setString(entry.key, entry.value);
        }
      }
    } else {
      // Import from Mobile structure to Web (Not implemented for MVP yet)
      throw Exception(
        'Cross-platform restore (Mobile -> Web) requires migration logic.',
      );
    }
  }

  static Future<void> _restoreMobile(Map<String, dynamic> data) async {
    final db = await DatabaseService.database;

    // Transaction for safety
    await db.transaction((txn) async {
      // Clear existing data? Or Merge?
      // Strategy: Clear and Replace (Full Restore)

      final tables = [
        'books',
        'chapters',
        'scp_logs',
        'daily_stats',
        'notes',
        'snapshots',
        'bookmarks',
        'characters',
        'locations',
        'templates',
      ];

      // 1. Clear tables
      // Order matters for Foreign Keys?
      // SQLite usually disables FK checks via pragma if needed, or delete children first.
      // Child tables: chapters, scp_logs, characters...
      // Parent: books.

      await txn.delete('scp_logs');
      await txn.delete('notes');
      await txn.delete('snapshots');
      await txn.delete('bookmarks');
      await txn.delete('characters');
      await txn.delete('locations');
      await txn.delete('chapters');
      await txn.delete('books');
      await txn.delete('templates');
      await txn.delete('daily_stats');

      // 2. Insert Data
      for (final table in tables) {
        if (data.containsKey(table)) {
          final records = data[table] as List;
          for (final record in records) {
            await txn.insert(table, record as Map<String, dynamic>);
          }
        }
      }
    });
  }
}
