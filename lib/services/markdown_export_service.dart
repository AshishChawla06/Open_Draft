import '../models/book.dart';
import '../models/document_type.dart';
import 'dart:convert';

class MarkdownExportService {
  /// Export a book to Markdown format
  static String exportToMarkdown(Book book) {
    final buffer = StringBuffer();

    // Title and metadata
    buffer.writeln('# ${book.title}');
    buffer.writeln();
    buffer.writeln('**Author:** ${book.author}');
    buffer.writeln();

    if (book.description != null && book.description!.isNotEmpty) {
      buffer.writeln('## Description');
      buffer.writeln();
      buffer.writeln(book.description);
      buffer.writeln();
    }

    // SCP-specific metadata
    if (book.documentType == DocumentType.scp && book.scpMetadata != null) {
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln('**Item #:** ${book.scpMetadata!.itemNumber}');
      buffer.writeln();
      buffer.writeln('**Object Class:** ${book.scpMetadata!.objectClass}');
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }

    // Chapters
    for (final chapter in book.chapters) {
      buffer.writeln('## ${chapter.title}');
      buffer.writeln();

      // Convert Quill Delta to plain text if needed
      String content = chapter.content;
      try {
        if (content.startsWith('{') || content.startsWith('[')) {
          final json = jsonDecode(content);
          final ops = json is Map ? json['ops'] as List : json as List;
          final textBuffer = StringBuffer();
          for (final op in ops) {
            if (op['insert'] is String) {
              textBuffer.write(op['insert']);
            }
          }
          content = textBuffer.toString();
        }
      } catch (e) {
        // If parsing fails, use raw content
      }

      buffer.writeln(content);
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Export a book to HTML format
  static String exportToHTML(Book book) {
    final buffer = StringBuffer();

    // HTML header
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln(
      '  <meta name="viewport" content="width=device-width, initial-scale=1.0">',
    );
    buffer.writeln('  <title>${_escapeHtml(book.title)}</title>');
    buffer.writeln('  <style>');
    buffer.writeln(
      '    body { font-family: Georgia, serif; max-width: 800px; margin: 0 auto; padding: 20px; line-height: 1.6; }',
    );
    buffer.writeln(
      '    h1 { color: #333; border-bottom: 2px solid #333; padding-bottom: 10px; }',
    );
    buffer.writeln('    h2 { color: #555; margin-top: 40px; }');
    buffer.writeln(
      '    .metadata { background: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0; }',
    );
    buffer.writeln('    .chapter { margin-top: 30px; }');
    buffer.writeln(
      '    hr { border: none; border-top: 1px solid #ddd; margin: 40px 0; }',
    );
    if (book.documentType == DocumentType.scp) {
      buffer.writeln('    body { background: #111; color: #ddd; }');
      buffer.writeln('    h1, h2 { color: #f44; }');
      buffer.writeln(
        '    .metadata { background: #222; border: 1px solid #f44; }',
      );
    }
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    // Title
    buffer.writeln('  <h1>${_escapeHtml(book.title)}</h1>');
    buffer.writeln('  <div class="metadata">');
    buffer.writeln(
      '    <p><strong>Author:</strong> ${_escapeHtml(book.author)}</p>',
    );

    if (book.description != null && book.description!.isNotEmpty) {
      buffer.writeln(
        '    <p><strong>Description:</strong> ${_escapeHtml(book.description!)}</p>',
      );
    }

    // SCP metadata
    if (book.documentType == DocumentType.scp && book.scpMetadata != null) {
      buffer.writeln(
        '    <p><strong>Item #:</strong> ${_escapeHtml(book.scpMetadata!.itemNumber)}</p>',
      );
      buffer.writeln(
        '    <p><strong>Object Class:</strong> ${_escapeHtml(book.scpMetadata!.objectClass)}</p>',
      );
    }

    buffer.writeln('  </div>');

    // Chapters
    for (final chapter in book.chapters) {
      buffer.writeln('  <div class="chapter">');
      buffer.writeln('    <h2>${_escapeHtml(chapter.title)}</h2>');

      // Convert Quill Delta to plain text if needed
      String content = chapter.content;
      try {
        if (content.startsWith('{') || content.startsWith('[')) {
          final json = jsonDecode(content);
          final ops = json is Map ? json['ops'] as List : json as List;
          final textBuffer = StringBuffer();
          for (final op in ops) {
            if (op['insert'] is String) {
              textBuffer.write(op['insert']);
            }
          }
          content = textBuffer.toString();
        }
      } catch (e) {
        // If parsing fails, use raw content
      }

      // Convert paragraphs to HTML
      final paragraphs = content.split('\n\n');
      for (final paragraph in paragraphs) {
        if (paragraph.trim().isNotEmpty) {
          buffer.writeln('    <p>${_escapeHtml(paragraph.trim())}</p>');
        }
      }

      buffer.writeln('  </div>');
      buffer.writeln('  <hr>');
    }

    // HTML footer
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }
}
