import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/book.dart';
import '../models/chapter.dart';

class EpubExportService {
  /// Export a book to EPUB format
  static Future<void> exportToEpub(Book book) async {
    final archive = Archive();

    // Add mimetype file (must be first and uncompressed)
    archive.addFile(
      ArchiveFile('mimetype', 20, 'application/epub+zip'.codeUnits)
        ..compress = false,
    );

    // Add META-INF/container.xml
    final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

    archive.addFile(
      ArchiveFile(
        'META-INF/container.xml',
        containerXml.length,
        containerXml.codeUnits,
      ),
    );

    // Add OEBPS/content.opf (package document)
    final contentOpf = _generateContentOpf(book);
    archive.addFile(
      ArchiveFile('OEBPS/content.opf', contentOpf.length, contentOpf.codeUnits),
    );

    // Add OEBPS/toc.ncx (navigation)
    final tocNcx = _generateTocNcx(book);
    archive.addFile(
      ArchiveFile('OEBPS/toc.ncx', tocNcx.length, tocNcx.codeUnits),
    );

    // Add title page
    final titlePage = _generateTitlePage(book);
    archive.addFile(
      ArchiveFile('OEBPS/title.xhtml', titlePage.length, titlePage.codeUnits),
    );

    // Add chapters
    for (int i = 0; i < book.chapters.length; i++) {
      final chapter = book.chapters[i];
      final chapterHtml = _generateChapterHtml(chapter);
      archive.addFile(
        ArchiveFile(
          'OEBPS/chapter${i + 1}.xhtml',
          chapterHtml.length,
          chapterHtml.codeUnits,
        ),
      );
    }

    // Add basic CSS
    final css = _generateCss();
    archive.addFile(
      ArchiveFile('OEBPS/stylesheet.css', css.length, css.codeUnits),
    );

    // Save and share the EPUB
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/${book.title}.epub');
    final encoder = ZipEncoder();
    final bytes = encoder.encode(archive);
    await file.writeAsBytes(bytes!);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: book.title,
      text: 'EPUB exported from Novel Writer',
    );
  }

  static String _generateContentOpf(Book book) {
    final chapters = book.chapters
        .map((ch) {
          final id = 'chapter${ch.order}';
          return '<item id="$id" href="$id.xhtml" media-type="application/xhtml+xml"/>';
        })
        .join('\n    ');

    final spine = book.chapters
        .map((ch) {
          return '<itemref idref="chapter${ch.order}"/>';
        })
        .join('\n    ');

    return '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>${_escapeXml(book.title)}</dc:title>
    <dc:creator>${_escapeXml(book.author)}</dc:creator>
    <dc:language>en</dc:language>
    <dc:identifier id="bookid">urn:uuid:${book.id}</dc:identifier>
    ${book.description != null ? '<dc:description>${_escapeXml(book.description!)}</dc:description>' : ''}
    <meta property="dcterms:modified">${DateTime.now().toIso8601String()}</meta>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="title" href="title.xhtml" media-type="application/xhtml+xml"/>
    <item id="stylesheet" href="stylesheet.css" media-type="text/css"/>
    $chapters
  </manifest>
  <spine toc="ncx">
    <itemref idref="title"/>
    $spine
  </spine>
</package>''';
  }

  static String _generateTocNcx(Book book) {
    final navPoints = book.chapters
        .map((ch) {
          return '''
    <navPoint id="chapter${ch.order}" playOrder="${ch.order + 1}">
      <navLabel>
        <text>Chapter ${ch.order}: ${_escapeXml(ch.title)}</text>
      </navLabel>
      <content src="chapter${ch.order}.xhtml"/>
    </navPoint>''';
        })
        .join('\n');

    return '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="urn:uuid:${book.id}"/>
    <meta name="dtb:depth" content="1"/>
    <meta name="dtb:totalPageCount" content="0"/>
    <meta name="dtb:maxPageNumber" content="0"/>
  </head>
  <docTitle>
    <text>${_escapeXml(book.title)}</text>
  </docTitle>
  <navMap>
    <navPoint id="title" playOrder="1">
      <navLabel>
        <text>Title Page</text>
      </navLabel>
      <content src="title.xhtml"/>
    </navPoint>$navPoints
  </navMap>
</ncx>''';
  }

  static String _generateTitlePage(Book book) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>${_escapeXml(book.title)}</title>
  <link rel="stylesheet" type="text/css" href="stylesheet.css"/>
</head>
<body>
  <div class="title-page">
    <h1>${_escapeXml(book.title)}</h1>
    <h2>by ${_escapeXml(book.author)}</h2>
    ${book.description != null ? '<p class="description">${_escapeXml(book.description!)}</p>' : ''}
  </div>
</body>
</html>''';
  }

  static String _generateChapterHtml(Chapter chapter) {
    final paragraphs = chapter.content
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .map((p) => '<p>${_escapeXml(p.trim())}</p>')
        .join('\n    ');

    return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Chapter ${chapter.order}: ${_escapeXml(chapter.title)}</title>
  <link rel="stylesheet" type="text/css" href="stylesheet.css"/>
</head>
<body>
  <div class="chapter">
    <h1>Chapter ${chapter.order}</h1>
    <h2>${_escapeXml(chapter.title)}</h2>
    $paragraphs
  </div>
</body>
</html>''';
  }

  static String _generateCss() {
    return '''
body {
  font-family: Georgia, serif;
  line-height: 1.6;
  margin: 2em;
}

.title-page {
  text-align: center;
  margin-top: 30%;
}

.title-page h1 {
  font-size: 2.5em;
  margin-bottom: 0.5em;
}

.title-page h2 {
  font-size: 1.5em;
  font-weight: normal;
  margin-bottom: 2em;
}

.description {
  font-style: italic;
  max-width: 600px;
  margin: 2em auto;
}

.chapter h1 {
  font-size: 1.2em;
  text-align: center;
  margin-top: 2em;
}

.chapter h2 {
  font-size: 1.8em;
  text-align: center;
  margin-bottom: 2em;
}

p {
  text-indent: 1.5em;
  margin: 0;
}

p:first-of-type {
  text-indent: 0;
}
''';
  }

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
