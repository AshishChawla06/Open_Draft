import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/book.dart';
import 'markdown_export_service.dart';
import 'pdf_export_service.dart';
import 'web/web_saver.dart';

enum ExportFormat { markdown, plainText, html, docx, pdf }

class ExportService {
  /// Export book to the specified format and share/save the file
  static Future<void> exportBook(Book book, ExportFormat format) async {
    final String extension = _getExtension(format);
    List<int> dataBytes;

    // Generate Content
    if (format == ExportFormat.pdf) {
      dataBytes = await PdfExportService.exportToPdf(book);
    } else {
      String content = '';
      switch (format) {
        case ExportFormat.markdown:
          content = MarkdownExportService.exportToMarkdown(book);
          break;
        case ExportFormat.plainText:
          // Use Markdown export but strip headers if needed, or just use markdown text as base
          // For now, raw markdown is acceptable as 'Source Text', or specifically parse for plain text
          // Re-using markdown is a safe fallback for plain text in MVP
          content = MarkdownExportService.exportToMarkdown(book);
          break;
        case ExportFormat.html:
          content = MarkdownExportService.exportToHTML(book);
          break;
        case ExportFormat.docx:
          // DOCX hack: Export as HTML with .docx extension (Word handles this gracefully)
          content = MarkdownExportService.exportToHTML(book);
          break;
        default:
          content = '';
      }
      dataBytes = utf8.encode(content);
    }

    // Save File
    await _saveFile(book.title, extension, Uint8List.fromList(dataBytes));
  }

  static Future<void> _saveFile(
    String title,
    String extension,
    Uint8List bytes,
  ) async {
    final safeTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final fileName = '$safeTitle$extension';

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // Mobile: Share sheet
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], subject: 'Export: $title');
    } else {
      // Desktop & Web: File Picker (Save As)
      String? outputFile;

      if (kIsWeb) {
        // Web Export (Direct Download)
        saveFileWeb(bytes, fileName);
        return;
      }

      // Known issue: saveFile is not implemented on Windows/Web for some file_picker versions
      // So we force directory picker on Windows/Linux to avoid UnimplementedError
      if (Platform.isWindows || Platform.isLinux) {
        final String? selectedDirectory = await FilePicker.platform
            .getDirectoryPath(dialogTitle: 'Select Destination Folder');
        if (selectedDirectory != null) {
          outputFile = '$selectedDirectory${Platform.pathSeparator}$fileName';
        }
      } else {
        try {
          outputFile = await FilePicker.platform.saveFile(
            dialogTitle: 'Export $title',
            fileName: fileName,
            bytes: bytes,
            type: FileType.any,
          );
        } catch (e) {
          rethrow;
        }
      }

      if (outputFile != null) {
        // Desktop: saveFile returns path, we must write
        if (!kIsWeb) {
          final file = File(outputFile);
          await file.writeAsBytes(bytes);
        }
      } else {
        // User canceled
      }
    }
  }

  static String _getExtension(ExportFormat format) {
    switch (format) {
      case ExportFormat.markdown:
        return '.md';
      case ExportFormat.plainText:
        return '.txt';
      case ExportFormat.html:
        return '.html';
      case ExportFormat.docx:
        return '.docx';
      case ExportFormat.pdf:
        return '.pdf';
    }
  }
}
