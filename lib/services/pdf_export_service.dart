import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/book.dart';

import 'dart:convert';

class PdfExportService {
  /// Generate PDF bytes for a book
  static Future<Uint8List> exportToPdf(Book book) async {
    final pdf = pw.Document();

    // Load font if necessary, or use standard fonts
    // For now, we use standard fonts effectively handled by pw.Theme

    // Title Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  book.title,
                  style: pw.TextStyle(
                    fontSize: 40,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'By ${book.author}',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
                if (book.description != null &&
                    book.description!.isNotEmpty) ...[
                  pw.SizedBox(height: 40),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                    child: pw.Text(
                      book.description!,
                      style: const pw.TextStyle(fontSize: 14),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );

    // Chapters
    for (final chapter in book.chapters) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      chapter.title,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Divider(),
                    pw.SizedBox(height: 20),
                  ],
                ),
              ),
              ..._parseContent(chapter.content),
            ];
          },
        ),
      );
    }

    return await pdf.save();
  }

  static List<pw.Widget> _parseContent(String content) {
    if (content.trim().isEmpty) return [];

    final widgets = <pw.Widget>[];

    try {
      if (content.startsWith('{') || content.startsWith('[')) {
        final json = jsonDecode(content);
        final ops = json is Map ? json['ops'] as List : json as List;

        final buffer = StringBuffer();

        // Simple Delta parser ensuring we handle blocks properly
        // This is a basic implementation. For rich text, we'd need more complex logic.
        // We accumulate text and flush on newlines to create Paragraphs.

        for (final op in ops) {
          if (op['insert'] is String) {
            buffer.write(op['insert']);
          }
        }

        final cleanText = buffer.toString();
        final paragraphs = cleanText.split('\n\n');

        for (final p in paragraphs) {
          if (p.trim().isNotEmpty) {
            widgets.add(
              pw.Paragraph(
                text: p.trim(),
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 5),
              ),
            );
            widgets.add(pw.SizedBox(height: 10));
          }
        }
      } else {
        // Raw text
        final paragraphs = content.split('\n\n');
        for (final p in paragraphs) {
          if (p.trim().isNotEmpty) {
            widgets.add(
              pw.Paragraph(
                text: p.trim(),
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 5),
              ),
            );
            widgets.add(pw.SizedBox(height: 10));
          }
        }
      }
    } catch (e) {
      widgets.add(pw.Paragraph(text: content));
    }

    return widgets;
  }
}
