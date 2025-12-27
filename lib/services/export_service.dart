import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/book.dart';
import '../models/chapter.dart';

enum ExportFormat { markdown, plainText, html, docx, pdf }

class ExportService {
  /// Export book to the specified format and share/save the file
  static Future<void> exportBook(Book book, ExportFormat format) async {
    final StringBuffer buffer = StringBuffer();
    final String extension = _getExtension(format);

    // Title & Metadata
    if (format == ExportFormat.html || format == ExportFormat.docx) {
      buffer.writeln(_getHtmlHeader(book));
    } else {
      buffer.writeln('# ${book.title}');
      buffer.writeln('By ${book.author}');
      if (book.description != null) {
        buffer.writeln('\n${book.description}');
      }
      buffer.writeln('\n---\n');
    }

    // Chapters
    for (final chapter in book.chapters) {
      if (format == ExportFormat.html || format == ExportFormat.docx) {
        buffer.writeln(_convertChapterToHtml(chapter));
      } else {
        buffer.writeln('## ${chapter.title}\n');
        buffer.writeln(_convertContent(chapter.content, format));
        buffer.writeln('\n');
      }
    }

    // Footer
    if (format == ExportFormat.html || format == ExportFormat.docx) {
      buffer.writeln(_getHtmlFooter());
    }

    // Save & Share
    try {
      final directory = await getApplicationDocumentsDirectory();
      final safeTitle = book.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final file = File('${directory.path}/$safeTitle$extension');

      await file.writeAsString(buffer.toString());

      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Export: ${book.title}');
    } catch (e) {
      print('Error exporting book: $e');
      rethrow;
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

  static String _convertContent(String content, ExportFormat format) {
    if (content.trim().isEmpty) return '';

    try {
      if (content.startsWith('{') || content.startsWith('[')) {
        final json = jsonDecode(content);
        final ops = json is Map ? json['ops'] as List : json as List;

        final buffer = StringBuffer();
        for (final op in ops) {
          if (op['insert'] is String) {
            final text = op['insert'] as String;
            if (format == ExportFormat.markdown) {
              // Basic Markdown processing
              if (op['attributes'] != null) {
                final attrs = op['attributes'] as Map;
                if (attrs['bold'] == true) {
                  buffer.write('**$text**');
                } else if (attrs['italic'] == true) {
                  buffer.write('*$text*');
                } else if (attrs['header'] != null) {
                  buffer.write('\n# $text');
                } else {
                  buffer.write(text);
                }
              } else {
                buffer.write(text);
              }
            } else {
              // Plain text
              buffer.write(text);
            }
          }
        }
        return buffer.toString();
      }
    } catch (e) {
      print('Error parsing delta: $e');
    }

    // Fallback: return raw content
    return content;
  }

  static String _getHtmlHeader(Book book) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${book.title}</title>
    <style>
        body { font-family: serif; max-width: 800px; margin: 0 auto; padding: 20px; line-height: 1.6; }
        h1 { text-align: center; }
        .author { text-align: center; font-style: italic; margin-bottom: 40px; }
        .chapter-title { margin-top: 40px; page-break-before: always; }
    </style>
</head>
<body>
    <h1>${book.title}</h1>
    <div class="author">By ${book.author}</div>
    ${book.description != null ? '<p>${book.description}</p>' : ''}
    <hr>
''';
  }

  static String _getHtmlFooter() {
    return '</body></html>';
  }

  static String _convertChapterToHtml(Chapter chapter) {
    final buffer = StringBuffer();
    buffer.writeln('<h2 class="chapter-title">${chapter.title}</h2>');

    // Html conversion logic for Delta
    // Ideally use vsc_quill_delta_to_html, but here we do a basic pass
    buffer.writeln('<div class="chapter-content">');

    try {
      if (chapter.content.startsWith('{') || chapter.content.startsWith('[')) {
        final json = jsonDecode(chapter.content);
        final ops = json is Map ? json['ops'] as List : json as List;

        for (final op in ops) {
          if (op['insert'] is String) {
            var text = op['insert'] as String;

            // Escape HTML
            text = text
                .replaceAll('&', '&amp;')
                .replaceAll('<', '&lt;')
                .replaceAll('>', '&gt;')
                .replaceAll('\n', '<br>');

            if (op['attributes'] != null) {
              final attrs = op['attributes'] as Map;
              if (attrs['bold'] == true) text = '<b>$text</b>';
              if (attrs['italic'] == true) text = '<i>$text</i>';
              // Add more styles as needed
            }
            buffer.write(text);
          }
        }
      } else {
        buffer.write(chapter.content);
      }
    } catch (e) {
      buffer.write(chapter.content);
    }

    buffer.writeln('</div>');
    return buffer.toString();
  }
}
