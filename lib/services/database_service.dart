import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/document_type.dart';
import '../models/scp_metadata.dart';
import '../models/scp_section.dart';
import '../models/redaction.dart';
import '../models/scp_log.dart';
import '../models/snapshot.dart';
import '../models/character.dart';
import '../models/bookmark.dart';
import '../models/template.dart';
//import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'novel_writer.db';
  static const int _dbVersion = 9;

  /// Helper to get accurate word count from content
  static int _getWordCount(String content) {
    if (content.trim().isEmpty) return 0;

    String textToCount = content;
    try {
      // Try to parse as JSON (Quill Delta)
      if (content.startsWith('{') || content.startsWith('[')) {
        final json = jsonDecode(content);
        final ops = json is Map ? json['ops'] as List : json as List;
        final buffer = StringBuffer();
        for (final op in ops) {
          if (op['insert'] is String) {
            buffer.write(op['insert']);
          }
        }
        textToCount = buffer.toString();
      }
    } catch (e) {
      // If parsing fails, fall back to raw content
      // print('Error parsing content for word count: $e');
    }

    return textToCount
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
  }

  // Web storage keys
  static const String _webBooksKey = 'books_data';
  static const String _webChaptersKey = 'chapters_data';
  static const String _webLogsKey = 'logs_data';
  static const String _webStatsKey = 'daily_stats_data';
  static const String _webNotesKey = 'notes_data';
  static const String _webSnapshotsKey = 'snapshots_data';
  static const String _webBookmarksKey = 'bookmarks_data';
  static const String _webCharactersKey = 'characters_data';
  static const String _webLocationsKey = 'locations_data';
  static const String _webTemplatesKey = 'templates_data';

  /// Get database instance (mobile only)
  static Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Database not used on web');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database (mobile only)
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create tables (mobile only)
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        description TEXT,
        coverImagePath TEXT,
        themeColor INTEGER,
        documentType TEXT,
        scpMetadata TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chapters (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        orderIndex INTEGER NOT NULL,
        wordCountGoal INTEGER,
        coverUrl TEXT,
        sectionType TEXT,
        redactions TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE scp_logs (
        id TEXT PRIMARY KEY,
        chapterId TEXT NOT NULL,
        type TEXT NOT NULL,
        entries TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        title TEXT,
        FOREIGN KEY (chapterId) REFERENCES chapters (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_stats (
        date TEXT PRIMARY KEY,
        wordCount INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        targetId TEXT NOT NULL,
        type TEXT NOT NULL,
        content TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE snapshots (
        id TEXT PRIMARY KEY,
        chapterId TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bookmarks (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        chapterId TEXT NOT NULL,
        title TEXT NOT NULL,
        position INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE,
        FOREIGN KEY (chapterId) REFERENCES chapters (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE characters (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        role TEXT,
        imageUrl TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE locations (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        imageUrl TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        content TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');
  }

  /// Upgrade database (mobile only)
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE chapters ADD COLUMN wordCountGoal INTEGER');
      await db.execute('ALTER TABLE chapters ADD COLUMN coverUrl TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE scp_logs (
          id TEXT PRIMARY KEY,
          chapterId TEXT NOT NULL,
          type TEXT NOT NULL,
          entries TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          title TEXT,
          FOREIGN KEY (chapterId) REFERENCES chapters (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE books ADD COLUMN themeColor INTEGER');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE daily_stats (
          date TEXT PRIMARY KEY,
          wordCount INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE notes (
          id TEXT PRIMARY KEY,
          targetId TEXT NOT NULL,
          type TEXT NOT NULL,
          content TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE snapshots (
          id TEXT PRIMARY KEY,
          chapterId TEXT NOT NULL,
          content TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          description TEXT
        )
      ''');
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE bookmarks (
          id TEXT PRIMARY KEY,
          bookId TEXT NOT NULL,
          chapterId TEXT NOT NULL,
          title TEXT NOT NULL,
          position INTEGER NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE,
          FOREIGN KEY (chapterId) REFERENCES chapters (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE characters (
          id TEXT PRIMARY KEY,
          bookId TEXT NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          role TEXT,
          imageUrl TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE locations (
          id TEXT PRIMARY KEY,
          bookId TEXT NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          imageUrl TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE templates (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          content TEXT NOT NULL,
          type TEXT NOT NULL
        )
      ''');
    }
  }

  // ... existing book/chapter methods ...

  /// Save a log
  static Future<void> saveLog(SCPLog log) async {
    if (kIsWeb) {
      await _saveLogWeb(log);
    } else {
      await _saveLogMobile(log);
    }
  }

  static Future<void> _saveLogWeb(SCPLog log) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getString(_webLogsKey) ?? '[]';
      final List<dynamic> logsList = jsonDecode(logsJson);

      final index = logsList.indexWhere((l) => l['id'] == log.id);
      final logMap = log.toJson();

      if (index >= 0) {
        logsList[index] = logMap;
      } else {
        logsList.add(logMap);
      }

      await prefs.setString(_webLogsKey, jsonEncode(logsList));
    } catch (e) {
      print('Error saving log to web: $e');
    }
  }

  static Future<void> _saveLogMobile(SCPLog log) async {
    final db = await database;
    await db.insert('scp_logs', {
      'id': log.id,
      'chapterId': log.chapterId,
      'type': log.type,
      'entries': jsonEncode(log.entries.map((e) => e.toJson()).toList()),
      'createdAt': log.createdAt.toIso8601String(),
      'title': log.title,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get logs for a chapter
  static Future<List<SCPLog>> getLogsForChapter(String chapterId) async {
    if (kIsWeb) {
      return await _getLogsForChapterWeb(chapterId);
    } else {
      return await _getLogsForChapterMobile(chapterId);
    }
  }

  static Future<List<SCPLog>> _getLogsForChapterWeb(String chapterId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getString(_webLogsKey) ?? '[]';
      final List<dynamic> logsList = jsonDecode(logsJson);

      return logsList
          .where((l) => l['chapterId'] == chapterId)
          .map((l) => SCPLog.fromJson(l))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error getting logs for chapter web: $e');
      return [];
    }
  }

  static Future<List<SCPLog>> _getLogsForChapterMobile(String chapterId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scp_logs',
      where: 'chapterId = ?',
      whereArgs: [chapterId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return SCPLog(
        id: maps[i]['id'],
        chapterId: maps[i]['chapterId'],
        type: maps[i]['type'],
        entries: (jsonDecode(maps[i]['entries']) as List)
            .map((e) => LogEntry.fromJson(e))
            .toList(),
        createdAt: DateTime.parse(maps[i]['createdAt']),
        title: maps[i]['title'],
      );
    });
  }

  /// Delete a log
  static Future<void> deleteLog(String logId) async {
    if (kIsWeb) {
      await _deleteLogWeb(logId);
    } else {
      await _deleteLogMobile(logId);
    }
  }

  static Future<void> _deleteLogWeb(String logId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getString(_webLogsKey) ?? '[]';
      final List<dynamic> logsList = jsonDecode(logsJson);

      logsList.removeWhere((l) => l['id'] == logId);
      await prefs.setString(_webLogsKey, jsonEncode(logsList));
    } catch (e) {
      print('Error deleting log web: $e');
    }
  }

  static Future<void> _deleteLogMobile(String logId) async {
    final db = await database;
    await db.delete('scp_logs', where: 'id = ?', whereArgs: [logId]);
  }

  /// Save a book
  static Future<void> saveBook(Book book) async {
    if (kIsWeb) {
      await _saveBookWeb(book);
    } else {
      await _saveBookMobile(book);
    }
  }

  static Future<void> _saveBookWeb(Book book) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = prefs.getString(_webBooksKey) ?? '[]';
      final booksList = List<Map<String, dynamic>>.from(jsonDecode(booksJson));

      // Remove existing book if present
      booksList.removeWhere((b) => b['id'] == book.id);

      // Add updated book
      booksList.add({
        'id': book.id,
        'title': book.title,
        'author': book.author,
        'description': book.description,
        'coverUrl': book.coverUrl,
        'themeColor': book.themeColor,
        'tags': jsonEncode(book.tags),
        'createdAt': book.createdAt.toIso8601String(),
        'updatedAt': book.updatedAt.toIso8601String(),
        'documentType': book.documentType.name,
        'scpMetadata': book.scpMetadata?.toJsonString(),
      });

      await prefs.setString(_webBooksKey, jsonEncode(booksList));
      print('Saved book to web storage: ${book.id}');

      // Save chapters
      for (final chapter in book.chapters) {
        await saveChapter(book.id, chapter);
      }
    } catch (e) {
      print('Error saving book to web: $e');
      rethrow;
    }
  }

  static Future<void> _saveBookMobile(Book book) async {
    final db = await database;

    await db.insert('books', {
      'id': book.id,
      'title': book.title,
      'author': book.author,
      'description': book.description,
      'coverImagePath': book.coverUrl,
      'themeColor': book.themeColor,
      'createdAt': book.createdAt.toIso8601String(),
      'updatedAt': book.updatedAt.toIso8601String(),
      'documentType': book.documentType.name,
      'scpMetadata': book.scpMetadata?.toJsonString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    for (final chapter in book.chapters) {
      await saveChapter(book.id, chapter);
    }
  }

  /// Save a chapter
  static Future<void> saveChapter(String bookId, Chapter chapter) async {
    if (kIsWeb) {
      await _saveChapterWeb(bookId, chapter);
    } else {
      await _saveChapterMobile(bookId, chapter);
    }
  }

  static Future<void> _saveChapterWeb(String bookId, Chapter chapter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chaptersJson = prefs.getString(_webChaptersKey) ?? '[]';
      final chaptersList = List<Map<String, dynamic>>.from(
        jsonDecode(chaptersJson),
      );

      // Remove existing chapter if present
      chaptersList.removeWhere((c) => c['id'] == chapter.id);

      // Serialize redactions
      final redactionsJson = chapter.redactions
          ?.map((r) => r.toJson())
          .toList();

      // Add updated chapter
      chaptersList.add({
        'id': chapter.id,
        'bookId': bookId,
        'title': chapter.title,
        'content': chapter.content,
        'order': chapter.order,
        'wordCountGoal': chapter.wordCountGoal,
        'coverUrl': chapter.coverUrl,
        'createdAt': chapter.createdAt.toIso8601String(),
        'updatedAt': chapter.updatedAt.toIso8601String(),
        'sectionType': chapter.sectionType?.name,
        'redactions': redactionsJson != null
            ? jsonEncode(redactionsJson)
            : null,
      });

      await prefs.setString(_webChaptersKey, jsonEncode(chaptersList));
      print('Saved chapter to web storage: ${chapter.id}');
    } catch (e) {
      print('Error saving chapter to web: $e');
      rethrow;
    }
  }

  static Future<void> _saveChapterMobile(String bookId, Chapter chapter) async {
    final db = await database;

    await db.insert('chapters', {
      'id': chapter.id,
      'bookId': bookId,
      'title': chapter.title,
      'content': chapter.content,
      'orderIndex': chapter.order,
      'wordCountGoal': chapter.wordCountGoal,
      'coverUrl': chapter.coverUrl,
      'createdAt': chapter.createdAt.toIso8601String(),
      'updatedAt': chapter.updatedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get all books
  static Future<List<Book>> getAllBooks() async {
    if (kIsWeb) {
      return await _getAllBooksWeb();
    } else {
      return await _getAllBooksMobile();
    }
  }

  static Future<List<Book>> _getAllBooksWeb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = prefs.getString(_webBooksKey) ?? '[]';
      final booksList = List<Map<String, dynamic>>.from(jsonDecode(booksJson));

      final books = <Book>[];
      for (final bookMap in booksList) {
        final chapters = await getChapters(bookMap['id'] as String);

        // Parse document type
        final rawType = bookMap['documentType'] as String?;
        final documentType = rawType != null
            ? DocumentType.fromString(rawType)
            : DocumentType.novel;
        print(
          'DEBUG: Book ${bookMap['id']} raw type: "$rawType" -> $documentType',
        );

        // Parse SCP metadata if present
        SCPMetadata? scpMetadata;
        if (bookMap['scpMetadata'] != null) {
          scpMetadata = SCPMetadata.fromJsonString(
            bookMap['scpMetadata'] as String,
          );
        }

        final tags = bookMap['tags'] != null
            ? List<String>.from(jsonDecode(bookMap['tags'] as String))
            : <String>[];

        books.add(
          Book(
            id: bookMap['id'] as String,
            title: bookMap['title'] as String,
            author: bookMap['author'] as String,
            description: bookMap['description'] as String?,
            coverUrl: bookMap['coverUrl'] as String?,
            themeColor: bookMap['themeColor'] as int?,
            chapters: chapters,
            createdAt: DateTime.parse(bookMap['createdAt'] as String),
            updatedAt: DateTime.parse(bookMap['updatedAt'] as String),
            documentType: documentType,
            scpMetadata: scpMetadata,
            tags: tags,
          ),
        );
      }

      // Sort by updatedAt descending
      books.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      print('Loaded ${books.length} books from web storage');
      return books;
    } catch (e) {
      print('Error loading books from web: $e');
      return [];
    }
  }

  static Future<List<Book>> _getAllBooksMobile() async {
    final db = await database;
    final bookMaps = await db.query('books', orderBy: 'updatedAt DESC');

    final books = <Book>[];
    for (final bookMap in bookMaps) {
      final chapters = await getChapters(bookMap['id'] as String);

      final rawType = bookMap['documentType'] as String?;
      final documentType = rawType != null
          ? DocumentType.fromString(rawType)
          : DocumentType.novel;

      SCPMetadata? scpMetadata;
      if (bookMap['scpMetadata'] != null) {
        scpMetadata = SCPMetadata.fromJsonString(
          bookMap['scpMetadata'] as String,
        );
      }

      books.add(
        Book(
          id: bookMap['id'] as String,
          title: bookMap['title'] as String,
          author: bookMap['author'] as String,
          description: bookMap['description'] as String?,
          coverUrl: bookMap['coverImagePath'] as String?,
          themeColor: bookMap['themeColor'] as int?,
          chapters: chapters,
          createdAt: DateTime.parse(bookMap['createdAt'] as String),
          updatedAt: DateTime.parse(bookMap['updatedAt'] as String),
          documentType: documentType,
          scpMetadata: scpMetadata,
        ),
      );
    }

    return books;
  }

  /// Get chapters for a book
  static Future<List<Chapter>> getChapters(String bookId) async {
    if (kIsWeb) {
      return await _getChaptersWeb(bookId);
    } else {
      return await _getChaptersMobile(bookId);
    }
  }

  static Future<List<Chapter>> _getChaptersWeb(String bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chaptersJson = prefs.getString(_webChaptersKey) ?? '[]';
      final chaptersList = List<Map<String, dynamic>>.from(
        jsonDecode(chaptersJson),
      );

      final chapters = chaptersList.where((c) => c['bookId'] == bookId).map((
        map,
      ) {
        // Parse section type
        SCPSectionType? sectionType;
        if (map['sectionType'] != null) {
          sectionType = SCPSectionType.fromString(map['sectionType'] as String);
        }

        // Parse redactions
        List<Redaction>? redactions;
        if (map['redactions'] != null) {
          final redactionsJson =
              jsonDecode(map['redactions'] as String) as List;
          redactions = redactionsJson
              .map((r) => Redaction.fromJson(r as Map<String, dynamic>))
              .toList();
        }

        return Chapter(
          id: map['id'] as String,
          title: map['title'] as String,
          content: map['content'] as String,
          order: map['order'] as int,
          wordCountGoal: map['wordCountGoal'] as int?,
          coverUrl: map['coverUrl'] as String?,
          createdAt: DateTime.parse(map['createdAt'] as String),
          updatedAt: DateTime.parse(map['updatedAt'] as String),
          sectionType: sectionType,
          redactions: redactions,
        );
      }).toList();

      // Sort by order
      chapters.sort((a, b) => a.order.compareTo(b.order));
      for (final c in chapters) {
        print('Loaded chapter ${c.id} content: ${c.content}');
      }
      return chapters;
    } catch (e) {
      print('Error loading chapters from web: $e');
      return [];
    }
  }

  static Future<List<Chapter>> _getChaptersMobile(String bookId) async {
    final db = await database;
    final chapterMaps = await db.query(
      'chapters',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'orderIndex ASC',
    );

    return chapterMaps
        .map(
          (map) => Chapter(
            id: map['id'] as String,
            title: map['title'] as String,
            content: map['content'] as String,
            order: map['orderIndex'] as int,
            wordCountGoal: map['wordCountGoal'] as int?,
            coverUrl: map['coverUrl'] as String?,
            createdAt: DateTime.parse(map['createdAt'] as String),
            updatedAt: DateTime.parse(map['updatedAt'] as String),
          ),
        )
        .toList();
  }

  /// Update book
  static Future<void> updateBook(Book book) async {
    if (kIsWeb) {
      await _updateBookWeb(book);
    } else {
      await _updateBookMobile(book);
    }
  }

  static Future<void> _updateBookWeb(Book book) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = prefs.getString(_webBooksKey) ?? '[]';
      final booksList = List<Map<String, dynamic>>.from(jsonDecode(booksJson));

      final index = booksList.indexWhere((b) => b['id'] == book.id);
      if (index != -1) {
        booksList[index] = {
          'id': book.id,
          'title': book.title,
          'author': book.author,
          'description': book.description,
          'coverUrl': book.coverUrl,
          'tags': jsonEncode(book.tags),
          'createdAt': booksList[index]['createdAt'],
          'updatedAt': DateTime.now().toIso8601String(),
          'documentType': book.documentType.name,
          'scpMetadata': book.scpMetadata?.toJsonString(),
        };
        await prefs.setString(_webBooksKey, jsonEncode(booksList));
        print('Updated book in web storage: ${book.id}');
      } else {
        print('Book not found for update: ${book.id}');
      }
    } catch (e) {
      print('Error updating book in web: $e');
      rethrow;
    }
  }

  static Future<void> _updateBookMobile(Book book) async {
    final db = await database;

    await db.update(
      'books',
      {
        'title': book.title,
        'author': book.author,
        'description': book.description,
        'coverImagePath': book.coverUrl,
        'themeColor': book.themeColor,
        'documentType': book.documentType.name,
        'scpMetadata': book.scpMetadata?.toJsonString(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  /// Update chapter
  static Future<void> updateChapter(Chapter chapter) async {
    if (kIsWeb) {
      await _updateChapterWeb(chapter);
    } else {
      await _updateChapterMobile(chapter);
    }
  }

  static Future<void> _updateChapterWeb(Chapter chapter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chaptersJson = prefs.getString(_webChaptersKey) ?? '[]';
      final chaptersList = List<Map<String, dynamic>>.from(
        jsonDecode(chaptersJson),
      );

      final index = chaptersList.indexWhere((c) => c['id'] == chapter.id);
      if (index != -1) {
        final bookId = chaptersList[index]['bookId'];
        chaptersList[index] = {
          'id': chapter.id,
          'bookId': bookId,
          'title': chapter.title,
          'content': chapter.content,
          'order': chapter.order,
          'wordCountGoal': chapter.wordCountGoal,
          'coverUrl': chapter.coverUrl,
          'createdAt': chaptersList[index]['createdAt'],
          'updatedAt': DateTime.now().toIso8601String(),
          'sectionType': chapter.sectionType?.name,
          'redactions': chapter.redactions != null
              ? jsonEncode(chapter.redactions!.map((r) => r.toJson()).toList())
              : null,
        };
        await prefs.setString(_webChaptersKey, jsonEncode(chaptersList));

        // Track word count progress
        final oldContent = chaptersList[index]['content'] as String;
        final oldWords = oldContent.trim().isEmpty
            ? 0
            : _getWordCount(oldContent);
        final newWords = _getWordCount(chapter.content);
        final diff = newWords - oldWords;
        if (diff != 0) {
          await recordDailyProgress(diff);
        }

        print(
          '!!! UPDATED CHAPTER IN DB !!!: ${chapter.id} with content length: ${chapter.content.length}',
        );
        print('Updated chapter in web storage: ${chapter.id}');
      } else {
        print('Chapter not found for update: ${chapter.id}');
      }
    } catch (e) {
      print('Error updating chapter in web: $e');
      rethrow;
    }
  }

  static Future<void> _updateChapterMobile(Chapter chapter) async {
    final db = await database;

    // Get old content for word count tracking
    final List<Map<String, dynamic>> maps = await db.query(
      'chapters',
      columns: ['content'],
      where: 'id = ?',
      whereArgs: [chapter.id],
    );

    if (maps.isNotEmpty) {
      final oldContent = maps.first['content'] as String;
      final oldWords = oldContent.trim().isEmpty
          ? 0
          : _getWordCount(oldContent);
      final newWords = _getWordCount(chapter.content);
      final diff = newWords - oldWords;
      if (diff != 0) {
        await recordDailyProgress(diff);
      }
    }

    await db.update(
      'chapters',
      {
        'title': chapter.title,
        'content': chapter.content,
        'wordCountGoal': chapter.wordCountGoal,
        'coverUrl': chapter.coverUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [chapter.id],
    );
  }

  /// Delete book
  static Future<void> deleteBook(String bookId) async {
    if (kIsWeb) {
      await _deleteBookWeb(bookId);
    } else {
      await _deleteBookMobile(bookId);
    }
  }

  static Future<void> _deleteBookWeb(String bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Delete book
      final booksJson = prefs.getString(_webBooksKey) ?? '[]';
      final booksList = List<Map<String, dynamic>>.from(jsonDecode(booksJson));
      booksList.removeWhere((b) => b['id'] == bookId);
      await prefs.setString(_webBooksKey, jsonEncode(booksList));

      // Delete chapters
      final chaptersJson = prefs.getString(_webChaptersKey) ?? '[]';
      final chaptersList = List<Map<String, dynamic>>.from(
        jsonDecode(chaptersJson),
      );
      chaptersList.removeWhere((c) => c['bookId'] == bookId);
      await prefs.setString(_webChaptersKey, jsonEncode(chaptersList));
      print('Deleted book from web storage: $bookId');
    } catch (e) {
      print('Error deleting book from web: $e');
      rethrow;
    }
  }

  static Future<void> _deleteBookMobile(String bookId) async {
    final db = await database;
    await db.delete('books', where: 'id = ?', whereArgs: [bookId]);
  }

  /// Delete chapter
  static Future<void> deleteChapter(String chapterId) async {
    if (kIsWeb) {
      await _deleteChapterWeb(chapterId);
    } else {
      await _deleteChapterMobile(chapterId);
    }
  }

  static Future<void> _deleteChapterWeb(String chapterId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chaptersJson = prefs.getString(_webChaptersKey) ?? '[]';
      final chaptersList = List<Map<String, dynamic>>.from(
        jsonDecode(chaptersJson),
      );
      chaptersList.removeWhere((c) => c['id'] == chapterId);
      await prefs.setString(_webChaptersKey, jsonEncode(chaptersList));
      print('Deleted chapter from web storage: $chapterId');
    } catch (e) {
      print('Error deleting chapter from web: $e');
      rethrow;
    }
  }

  /// Record daily progress
  static Future<void> recordDailyProgress(int wordCount) async {
    if (kIsWeb) {
      await _recordDailyProgressWeb(wordCount);
    } else {
      await _recordDailyProgressMobile(wordCount);
    }
  }

  static Future<void> _recordDailyProgressWeb(int wordCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_webStatsKey) ?? '{}';
      final Map<String, dynamic> stats = jsonDecode(statsJson);

      final today = DateTime.now().toIso8601String().split('T')[0];
      final currentCount = stats[today] as int? ?? 0;

      stats[today] = currentCount + wordCount;

      await prefs.setString(_webStatsKey, jsonEncode(stats));
    } catch (e) {
      print('Error recording stats web: $e');
    }
  }

  static Future<void> _recordDailyProgressMobile(int wordCount) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Check if entry exists
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_stats',
      where: 'date = ?',
      whereArgs: [today],
    );

    if (maps.isNotEmpty) {
      final currentCount = maps.first['wordCount'] as int;
      await db.update(
        'daily_stats',
        {'wordCount': currentCount + wordCount},
        where: 'date = ?',
        whereArgs: [today],
      );
    } else {
      await db.insert('daily_stats', {'date': today, 'wordCount': wordCount});
    }
  }

  /// Get daily stats
  static Future<Map<DateTime, int>> getDailyStats() async {
    if (kIsWeb) {
      return await _getDailyStatsWeb();
    } else {
      return await _getDailyStatsMobile();
    }
  }

  static Future<Map<DateTime, int>> _getDailyStatsWeb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_webStatsKey) ?? '{}';
      final Map<String, dynamic> stats = jsonDecode(statsJson);

      final result = <DateTime, int>{};
      stats.forEach((key, value) {
        result[DateTime.parse(key)] = value as int;
      });
      return result;
    } catch (e) {
      print('Error getting stats web: $e');
      return {};
    }
  }

  static Future<Map<DateTime, int>> _getDailyStatsMobile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('daily_stats');

    final result = <DateTime, int>{};
    for (final map in maps) {
      result[DateTime.parse(map['date'] as String)] = map['wordCount'] as int;
    }
    return result;
  }

  static Future<void> _deleteChapterMobile(String chapterId) async {
    final db = await database;
    await db.delete('chapters', where: 'id = ?', whereArgs: [chapterId]);
  }

  /// Initialize with sample data if database is empty
  /// Get note content
  static Future<String?> getNote(String targetId, String type) async {
    if (kIsWeb) {
      return await _getNoteWeb(targetId, type);
    } else {
      return await _getNoteMobile(targetId, type);
    }
  }

  static Future<String?> _getNoteMobile(String targetId, String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      columns: ['content'],
      where: 'targetId = ? AND type = ?',
      whereArgs: [targetId, type],
    );
    if (maps.isNotEmpty) {
      return maps.first['content'] as String?;
    }
    return null;
  }

  // --- Snapshots ---

  static Future<void> saveSnapshot(ChapterSnapshot snapshot) async {
    if (kIsWeb) {
      await _saveSnapshotWeb(snapshot);
    } else {
      await _saveSnapshotMobile(snapshot);
    }
  }

  static Future<void> _saveSnapshotWeb(ChapterSnapshot snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final snapshotsJson = prefs.getString(_webSnapshotsKey) ?? '[]';
      final snapshotsList = List<Map<String, dynamic>>.from(
        jsonDecode(snapshotsJson),
      );

      snapshotsList.add(snapshot.toMap());

      await prefs.setString(_webSnapshotsKey, jsonEncode(snapshotsList));
    } catch (e) {
      print('Error saving snapshot web: $e');
    }
  }

  static Future<void> _saveSnapshotMobile(ChapterSnapshot snapshot) async {
    final db = await database;
    await db.insert(
      'snapshots',
      snapshot.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<ChapterSnapshot>> getSnapshots(String chapterId) async {
    if (kIsWeb) {
      return await _getSnapshotsWeb(chapterId);
    } else {
      return await _getSnapshotsMobile(chapterId);
    }
  }

  static Future<List<ChapterSnapshot>> _getSnapshotsWeb(
    String chapterId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final snapshotsJson = prefs.getString(_webSnapshotsKey) ?? '[]';
      final snapshotsList = List<Map<String, dynamic>>.from(
        jsonDecode(snapshotsJson),
      );

      final snapshots = snapshotsList
          .where((s) => s['chapterId'] == chapterId)
          .map((s) => ChapterSnapshot.fromMap(s))
          .toList();

      snapshots.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return snapshots;
    } catch (e) {
      print('Error getting snapshots web: $e');
      return [];
    }
  }

  static Future<List<ChapterSnapshot>> _getSnapshotsMobile(
    String chapterId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'snapshots',
      where: 'chapterId = ?',
      whereArgs: [chapterId],
      orderBy: 'timestamp DESC',
    );

    return maps.map((m) => ChapterSnapshot.fromMap(m)).toList();
  }

  static Future<void> deleteSnapshot(String snapshotId) async {
    if (kIsWeb) {
      await _deleteSnapshotWeb(snapshotId);
    } else {
      await _deleteSnapshotMobile(snapshotId);
    }
  }

  static Future<void> _deleteSnapshotWeb(String snapshotId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final snapshotsJson = prefs.getString(_webSnapshotsKey) ?? '[]';
      final snapshotsList = List<Map<String, dynamic>>.from(
        jsonDecode(snapshotsJson),
      );

      snapshotsList.removeWhere((s) => s['id'] == snapshotId);
      await prefs.setString(_webSnapshotsKey, jsonEncode(snapshotsList));
    } catch (e) {
      print('Error deleting snapshot web: $e');
    }
  }

  static Future<void> _deleteSnapshotMobile(String snapshotId) async {
    final db = await database;
    await db.delete('snapshots', where: 'id = ?', whereArgs: [snapshotId]);
  }

  static Future<String?> _getNoteWeb(String targetId, String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_webNotesKey) ?? '[]';
      final List<dynamic> notesList = jsonDecode(notesJson);

      final note = notesList.firstWhere(
        (n) => n['targetId'] == targetId && n['type'] == type,
        orElse: () => null,
      );

      return note?['content'] as String?;
    } catch (e) {
      print('Error getting note web: $e');
      return null;
    }
  }

  /// Save note content
  static Future<void> saveNote(
    String targetId,
    String type,
    String content,
  ) async {
    if (kIsWeb) {
      await saveNoteWeb(targetId, type, content);
    } else {
      await _saveNoteMobile(targetId, type, content);
    }
  }

  static Future<void> _saveNoteMobile(
    String targetId,
    String type,
    String content,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Check if exists
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'targetId = ? AND type = ?',
      whereArgs: [targetId, type],
    );

    if (maps.isNotEmpty) {
      await db.update(
        'notes',
        {'content': content, 'updatedAt': now},
        where: 'targetId = ? AND type = ?',
        whereArgs: [targetId, type],
      );
    } else {
      await db.insert('notes', {
        'id': '${targetId}_$type', // Simple ID generation
        'targetId': targetId,
        'type': type,
        'content': content,
        'createdAt': now,
        'updatedAt': now,
      });
    }
  }

  static Future<void> saveNoteWeb(
    String targetId,
    String type,
    String content,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_webNotesKey) ?? '[]';
      final List<Map<String, dynamic>> notesList =
          List<Map<String, dynamic>>.from(jsonDecode(notesJson));

      final index = notesList.indexWhere(
        (n) => n['targetId'] == targetId && n['type'] == type,
      );

      final now = DateTime.now().toIso8601String();

      if (index != -1) {
        notesList[index]['content'] = content;
        notesList[index]['updatedAt'] = now;
      } else {
        notesList.add({
          'id': '${targetId}_$type',
          'targetId': targetId,
          'type': type,
          'content': content,
          'createdAt': now,
          'updatedAt': now,
        });
      }

      await prefs.setString(_webNotesKey, jsonEncode(notesList));
    } catch (e) {
      print('Error saving note web: $e');
    }
  }

  // Character Operations
  static Future<void> saveCharacter(Character character) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_webCharactersKey) ?? '[]';
      final List<dynamic> list = jsonDecode(data);
      final index = list.indexWhere((item) => item['id'] == character.id);
      if (index >= 0) {
        list[index] = character.toJson();
      } else {
        list.add(character.toJson());
      }
      await prefs.setString(_webCharactersKey, jsonEncode(list));
    } else {
      final db = await database;
      await db.insert(
        'characters',
        character.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<List<Character>> getCharacters(String bookId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_webCharactersKey) ?? '[]';
      final List<dynamic> list = jsonDecode(data);
      return list
          .where((item) => item['bookId'] == bookId)
          .map((item) => Character.fromJson(item))
          .toList();
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'characters',
        where: 'bookId = ?',
        whereArgs: [bookId],
      );
      return maps.map((map) => Character.fromJson(map)).toList();
    }
  }

  static Future<void> deleteCharacter(String id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_webCharactersKey) ?? '[]';
      final List<dynamic> list = jsonDecode(data);
      list.removeWhere((item) => item['id'] == id);
      await prefs.setString(_webCharactersKey, jsonEncode(list));
    } else {
      final db = await database;
      await db.delete('characters', where: 'id = ?', whereArgs: [id]);
    }
  }

  // Location Operations
  static Future<void> saveLocation(Location location) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_webLocationsKey) ?? '[]';
      final List<dynamic> list = jsonDecode(data);
      final index = list.indexWhere((item) => item['id'] == location.id);
      if (index >= 0) {
        list[index] = location.toJson();
      } else {
        list.add(location.toJson());
      }
      await prefs.setString(_webLocationsKey, jsonEncode(list));
    } else {
      final db = await database;
      await db.insert(
        'locations',
        location.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<List<Location>> getLocations(String bookId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_webLocationsKey) ?? '[]';
      final List<dynamic> list = jsonDecode(data);
      return list
          .where((item) => item['bookId'] == bookId)
          .map((item) => Location.fromJson(item))
          .toList();
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'locations',
        where: 'bookId = ?',
        whereArgs: [bookId],
      );
      return maps.map((map) => Location.fromJson(map)).toList();
    }
  }

  static Future<void> deleteLocation(String id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_webLocationsKey) ?? '[]';
      final List<dynamic> list = jsonDecode(data);
      list.removeWhere((item) => item['id'] == id);
      await prefs.setString(_webLocationsKey, jsonEncode(list));
    } else {
      final db = await database;
      await db.delete('locations', where: 'id = ?', whereArgs: [id]);
    }
  }

  // Bookmark Operations
  static Future<void> saveBookmark(Bookmark bookmark) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_webBookmarksKey) ?? '[]';
      final List<dynamic> list = jsonDecode(data);
      final index = list.indexWhere((item) => item['id'] == bookmark.id);
      if (index >= 0) {
        list[index] = bookmark.toJson();
      } else {
        list.add(bookmark.toJson());
      }
      await prefs.setString(_webBookmarksKey, jsonEncode(list));
    } else {
      final db = await database;
      await db.insert(
        'bookmarks',
        bookmark.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<List<Bookmark>> getBookmarks(String bookId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_webBookmarksKey) ?? '[]';
      final List<dynamic> list = jsonDecode(data);
      return list
          .where((item) => item['bookId'] == bookId)
          .map((item) => Bookmark.fromJson(item))
          .toList();
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'bookmarks',
        where: 'bookId = ?',
        whereArgs: [bookId],
      );
      return maps.map((map) => Bookmark.fromJson(map)).toList();
    }
  }

  static Future<void> deleteBookmark(String id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_webBookmarksKey) ?? '[]';
      final List<dynamic> list = jsonDecode(data);
      list.removeWhere((item) => item['id'] == id);
      await prefs.setString(_webBookmarksKey, jsonEncode(list));
    } else {
      final db = await database;
      await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
    }
  }

  // --- Template Operations ---

  static Future<void> saveTemplate(Template template) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_webTemplatesKey) ?? '[]';
      final List<dynamic> list = jsonDecode(data);
      final index = list.indexWhere((item) => item['id'] == template.id);
      if (index >= 0) {
        list[index] = template.toJson();
      } else {
        list.add(template.toJson());
      }
      await prefs.setString(_webTemplatesKey, jsonEncode(list));
    } else {
      final db = await database;
      await db.insert(
        'templates',
        template.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<List<Template>> getAllTemplates() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_webTemplatesKey) ?? '[]';
      final List<dynamic> list = jsonDecode(data);
      return list.map((item) => Template.fromJson(item)).toList();
    } else {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('templates');
      return maps.map((map) => Template.fromJson(map)).toList();
    }
  }

  static Future<void> deleteTemplate(String id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_webTemplatesKey) ?? '[]';
      final List<dynamic> list = jsonDecode(data);
      list.removeWhere((item) => item['id'] == id);
      await prefs.setString(_webTemplatesKey, jsonEncode(list));
    } else {
      final db = await database;
      await db.delete('templates', where: 'id = ?', whereArgs: [id]);
    }
  }

  static Future<void> initializeSampleData() async {
    final books = await getAllBooks();
    if (books.isEmpty) {
      for (final book in Book.getMockBooks()) {
        await saveBook(book);
      }
    }

    final templates = await getAllTemplates();
    if (templates.isEmpty) {
      await saveTemplate(
        const Template(
          id: 'default-novel',
          name: 'Standard Novel',
          description: 'A basic structure for many-chapter novels.',
          content: '# Prologue\n\n# Chapter 1',
          type: DocumentType.novel,
        ),
      );
      await saveTemplate(
        const Template(
          id: 'default-scp',
          name: 'SCP Basic',
          description: 'Traditional SCP Foundation entry format.',
          content:
              '**Item #:** SCP-XXXX\n\n**Object Class:** Safe\n\n**Special Containment Procedures:** [REDACTED]',
          type: DocumentType.scp,
        ),
      );
    }
  }
}
