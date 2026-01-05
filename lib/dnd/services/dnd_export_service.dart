import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/book.dart';
import '../../models/chapter.dart';
import '../models/encounter.dart';
import '../models/npc.dart';
import '../models/location.dart';
import '../models/magic_item.dart';
import '../models/adventure_note.dart';

enum DnDExportMode { gm, player }

enum DnDExportFormat { pdf, html }

enum DnDExportTheme { srdClean, parchment, darkArcana, glassmorphic }

class DnDExportService {
  /// Export D&D adventure to PDF with theme and mode options
  static Future<List<int>> exportAdventureToPdf({
    required Book book,
    required List<Chapter> chapters,
    List<Encounter>? encounters,
    List<Npc>? npcs,
    List<Location>? locations,
    List<MagicItem>? items,
    List<AdventureNote>? notes,
    DnDExportMode mode = DnDExportMode.gm,
    DnDExportTheme theme = DnDExportTheme.parchment,
  }) async {
    final pdf = pw.Document();

    // Theme colors
    final themeColors = _getThemeColors(theme);

    // Title Page
    pdf.addPage(
      pw.Page(
        pageTheme: _getPageTheme(theme),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 100),
            pw.Text(
              book.title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 42,
                fontWeight: pw.FontWeight.bold,
                color: themeColors['title'],
              ),
            ),
            pw.SizedBox(height: 20),
            if (book.author.isNotEmpty)
              pw.Text(
                'By ${book.author}',
                style: pw.TextStyle(
                  fontSize: 18,
                  color: themeColors['subtitle'],
                ),
              ),
            pw.SizedBox(height: 10),
            pw.Text(
              mode == DnDExportMode.gm
                  ? "DUNGEON MASTER'S VERSION"
                  : "PLAYER'S VERSION",
              style: pw.TextStyle(
                fontSize: 14,
                fontStyle: pw.FontStyle.italic,
                color: themeColors['accent'],
              ),
            ),
          ],
        ),
      ),
    );

    // Chapter Content
    for (final chapter in chapters) {
      pdf.addPage(
        pw.Page(
          pageTheme: _getPageTheme(theme),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Chapter Title
              pw.Text(
                chapter.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: themeColors['heading'],
                ),
              ),
              pw.Divider(color: themeColors['divider']),
              pw.SizedBox(height: 10),

              // Chapter Content (QuillDelta to text)
              pw.Text(
                _deltaToPlainText(chapter.content),
                style: pw.TextStyle(fontSize: 12, color: themeColors['body']),
              ),
            ],
          ),
        ),
      );
    }

    // Encounters Section
    if (encounters != null && encounters.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageTheme: _getPageTheme(theme),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ENCOUNTERS',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: themeColors['heading'],
                ),
              ),
              pw.Divider(color: themeColors['divider']),
              ...encounters.map(
                (encounter) =>
                    _buildEncounterSection(encounter, mode, themeColors),
              ),
            ],
          ),
        ),
      );
    }

    // NPCs Section
    if (npcs != null && npcs.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageTheme: _getPageTheme(theme),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'NON-PLAYER CHARACTERS',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: themeColors['heading'],
                ),
              ),
              pw.Divider(color: themeColors['divider']),
              ...npcs.map((npc) => _buildNpcSection(npc, mode, themeColors)),
            ],
          ),
        ),
      );
    }

    // Locations Section
    if (locations != null && locations.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageTheme: _getPageTheme(theme),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'LOCATIONS',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: themeColors['heading'],
                ),
              ),
              pw.Divider(color: themeColors['divider']),
              ...locations.map(
                (loc) => _buildLocationSection(loc, mode, themeColors),
              ),
            ],
          ),
        ),
      );
    }

    // Items Section
    if (items != null && items.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageTheme: _getPageTheme(theme),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MAGIC ITEMS',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: themeColors['heading'],
                ),
              ),
              pw.Divider(color: themeColors['divider']),
              ...items.map(
                (item) => _buildItemSection(item, mode, themeColors),
              ),
            ],
          ),
        ),
      );
    }

    // Notes Section
    if (notes != null && notes.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageTheme: _getPageTheme(theme),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ADVENTURE NOTES',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: themeColors['heading'],
                ),
              ),
              pw.Divider(color: themeColors['divider']),
              ...notes.map(
                (note) => _buildNoteSection(note, mode, themeColors),
              ),
            ],
          ),
        ),
      );
    }

    return pdf.save();
  }

  /// Convert QuillDelta JSON to plain text
  static String _deltaToPlainText(String deltaJson) {
    try {
      final data = jsonDecode(deltaJson);
      final ops = data['ops'] as List;
      final buffer = StringBuffer();

      for (final op in ops) {
        if (op['insert'] is String) {
          buffer.write(op['insert']);
        }
      }

      return buffer.toString().trim();
    } catch (e) {
      return '';
    }
  }

  /// Get theme colors
  static Map<String, PdfColor> _getThemeColors(DnDExportTheme theme) {
    switch (theme) {
      case DnDExportTheme.parchment:
        return {
          'title': PdfColors.brown900,
          'heading': PdfColors.brown800,
          'subtitle': PdfColors.brown700,
          'body': PdfColors.brown900,
          'accent': PdfColors.deepOrange700,
          'divider': PdfColors.brown300,
        };
      case DnDExportTheme.darkArcana:
        return {
          'title': PdfColors.purple900,
          'heading': PdfColors.deepPurple800,
          'subtitle': PdfColors.purple700,
          'body': PdfColors.grey900,
          'accent': PdfColors.purple400,
          'divider': PdfColors.purple200,
        };
      case DnDExportTheme.srdClean:
        return {
          'title': PdfColors.black,
          'heading': PdfColors.grey900,
          'subtitle': PdfColors.grey700,
          'body': PdfColors.black,
          'accent': PdfColors.blue700,
          'divider': PdfColors.grey400,
        };
      case DnDExportTheme.glassmorphic:
        return {
          'title': PdfColors.blue900,
          'heading': PdfColors.blue800,
          'subtitle': PdfColors.blue600,
          'body': PdfColors.grey900,
          'accent': PdfColors.cyan500,
          'divider': PdfColors.blue200,
        };
    }
  }

  /// Get page theme with background
  static pw.PageTheme _getPageTheme(DnDExportTheme theme) {
    PdfColor bgColor;

    switch (theme) {
      case DnDExportTheme.parchment:
        bgColor = PdfColor.fromHex('#F4E8D8'); // Parchment color
        break;
      case DnDExportTheme.darkArcana:
        bgColor = PdfColor.fromHex('#1A1A2E');
        break;
      default:
        bgColor = PdfColors.white;
    }

    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      buildBackground: (context) => pw.Container(color: bgColor),
    );
  }

  /// Build encounter section for PDF
  static pw.Widget _buildEncounterSection(
    Encounter encounter,
    DnDExportMode mode,
    Map<String, PdfColor> colors,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            encounter.title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: colors['heading'],
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Environment: ${encounter.environment} | Difficulty: ${encounter.difficultyRating}',
            style: pw.TextStyle(fontSize: 10, color: colors['subtitle']),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Monsters: ${encounter.monsters.length} (Total XP: ${encounter.totalXp})',
            style: pw.TextStyle(fontSize: 10, color: colors['body']),
          ),
          if (encounter.notes.isNotEmpty && mode == DnDExportMode.gm) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'GM Notes: ${encounter.notes}',
              style: pw.TextStyle(
                fontSize: 9,
                fontStyle: pw.FontStyle.italic,
                color: colors['accent'],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build NPC section for PDF
  static pw.Widget _buildNpcSection(
    Npc npc,
    DnDExportMode mode,
    Map<String, PdfColor> colors,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            npc.name,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: colors['heading'],
            ),
          ),
          if (npc.role.isNotEmpty)
            pw.Text(
              npc.role,
              style: pw.TextStyle(
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
                color: colors['subtitle'],
              ),
            ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${npc.race} ${npc.characterClass}${npc.alignment.isNotEmpty ? " • $npc.alignment}" : ""}',
            style: pw.TextStyle(fontSize: 10, color: colors['body']),
          ),
          if (npc.appearance.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Appearance: ${npc.appearance}',
              style: pw.TextStyle(fontSize: 9, color: colors['body']),
            ),
          ],
          if (mode == DnDExportMode.gm && npc.backstory.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Backstory: ${npc.backstory}',
              style: pw.TextStyle(
                fontSize: 9,
                fontStyle: pw.FontStyle.italic,
                color: colors['accent'],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build Location section for PDF
  static pw.Widget _buildLocationSection(
    Location loc,
    DnDExportMode mode,
    Map<String, PdfColor> colors,
  ) {
    final isRedacted = loc.redactions != null && loc.redactions!.isNotEmpty;
    if (isRedacted && mode == DnDExportMode.player) return pw.SizedBox();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            loc.name,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: colors['heading'],
            ),
          ),
          pw.Text(
            '${loc.environment} • ${loc.region}',
            style: pw.TextStyle(fontSize: 10, color: colors['subtitle']),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            loc.description,
            style: pw.TextStyle(fontSize: 10, color: colors['body']),
          ),
          if (loc.rooms.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Areas/Rooms:',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: colors['heading'],
              ),
            ),
            ...loc.rooms.map(
              (room) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 10, top: 2),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      room.name,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: colors['body'],
                      ),
                    ),
                    pw.Text(
                      room.description,
                      style: pw.TextStyle(fontSize: 9, color: colors['body']),
                    ),
                    if (mode == DnDExportMode.gm && room.secrets.isNotEmpty)
                      pw.Text(
                        'Secret: ${room.secrets}',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontStyle: pw.FontStyle.italic,
                          color: colors['accent'],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build Magic Item section for PDF
  static pw.Widget _buildItemSection(
    MagicItem item,
    DnDExportMode mode,
    Map<String, PdfColor> colors,
  ) {
    final isRedacted = item.redactions != null && item.redactions!.isNotEmpty;
    if (isRedacted && mode == DnDExportMode.player) return pw.SizedBox();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            item.name,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: colors['heading'],
            ),
          ),
          pw.Text(
            '${item.rarity} ${item.type}${item.requiresAttunement ? " (Requires Attunement)" : ""}',
            style: pw.TextStyle(fontSize: 10, color: colors['subtitle']),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            item.effects,
            style: pw.TextStyle(fontSize: 10, color: colors['body']),
          ),
          if (item.mechanics.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Mechanics: ${item.mechanics}',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: colors['body'],
              ),
            ),
          ],
          if (mode == DnDExportMode.gm && item.lore.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Lore: ${item.lore}',
              style: pw.TextStyle(
                fontSize: 9,
                fontStyle: pw.FontStyle.italic,
                color: colors['accent'],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build Note section for PDF
  static pw.Widget _buildNoteSection(
    AdventureNote note,
    DnDExportMode mode,
    Map<String, PdfColor> colors,
  ) {
    final isRedacted = note.redactions != null && note.redactions!.isNotEmpty;
    if (isRedacted && mode == DnDExportMode.player) return pw.SizedBox();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            note.title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: colors['heading'],
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            note.content,
            style: pw.TextStyle(fontSize: 10, color: colors['body']),
          ),
        ],
      ),
    );
  }

  /// Export to HTML
  static String exportAdventureToHtml({
    required Book book,
    required List<Chapter> chapters,
    List<Encounter>? encounters,
    List<Npc>? npcs,
    List<Location>? locations,
    List<MagicItem>? items,
    List<AdventureNote>? notes,
    DnDExportMode mode = DnDExportMode.gm,
    DnDExportTheme theme = DnDExportTheme.parchment,
  }) {
    final themeClass = theme.name;
    final buffer = StringBuffer();

    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln(
      '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
    );
    buffer.writeln('<title>${book.title}</title>');
    buffer.writeln(_getThemeStyles(theme));
    buffer.writeln('</head>');
    buffer.writeln('<body class="$themeClass">');
    buffer.writeln('<div class="export-container">');

    // Title
    buffer.writeln('<div class="title-page">');
    buffer.writeln('<h1>${book.title}</h1>');
    if (book.author.isNotEmpty) {
      buffer.writeln('<p class="author">By ${book.author}</p>');
    }
    buffer.writeln(
      '<p class="mode">${mode == DnDExportMode.gm ? "Dungeon Master's Version" : "Player's Version"}</p>',
    );
    buffer.writeln('</div>');

    // Chapters
    for (final chapter in chapters) {
      buffer.writeln('<div class="chapter">');
      buffer.writeln('<h2>${chapter.title}</h2>');
      buffer.writeln(
        '<div class="content">${_deltaToPlainText(chapter.content)}</div>',
      );
      buffer.writeln('</div>');
    }

    // Encounters
    if (encounters != null && encounters.isNotEmpty) {
      buffer.writeln('<div class="section encounters">');
      buffer.writeln('<h2>Encounters</h2>');
      for (final encounter in encounters) {
        buffer.writeln('<div class="encounter">');
        buffer.writeln('<h3>${encounter.title}</h3>');
        buffer.writeln(
          '<p><strong>Environment:</strong> ${encounter.environment} | <strong>Difficulty:</strong> ${encounter.difficultyRating}</p>',
        );
        buffer.writeln(
          '<p><strong>Monsters:</strong> ${encounter.monsters.length} (Total XP: ${encounter.totalXp})</p>',
        );
        if (mode == DnDExportMode.gm && encounter.notes.isNotEmpty) {
          buffer.writeln('<p class="gm-notes">${encounter.notes}</p>');
        }
        buffer.writeln('</div>');
      }
      buffer.writeln('</div>');
    }

    // Locations
    if (locations != null && locations.isNotEmpty) {
      buffer.writeln('<div class="section locations">');
      buffer.writeln('<h2>Locations</h2>');
      for (final loc in locations) {
        final isRedacted = loc.redactions != null && loc.redactions!.isNotEmpty;
        if (isRedacted && mode == DnDExportMode.player) continue;

        buffer.writeln('<div class="location">');
        buffer.writeln('<h3>${loc.name}</h3>');
        buffer.writeln(
          '<p class="subtitle">${loc.environment} • ${loc.region}</p>',
        );
        buffer.writeln('<p>${loc.description}</p>');
        if (loc.rooms.isNotEmpty) {
          buffer.writeln('<h4>Rooms/Areas</h4>');
          buffer.writeln('<ul>');
          for (final room in loc.rooms) {
            buffer.writeln('<li>');
            buffer.writeln(
              '<strong>${room.name}</strong>: ${room.description}',
            );
            if (mode == DnDExportMode.gm && room.secrets.isNotEmpty) {
              buffer.writeln('<p class="gm-notes">Secret: ${room.secrets}</p>');
            }
            buffer.writeln('</li>');
          }
          buffer.writeln('</ul>');
        }
        buffer.writeln('</div>');
      }
      buffer.writeln('</div>');
    }

    // NPCs
    if (npcs != null && npcs.isNotEmpty) {
      buffer.writeln('<div class="section npcs">');
      buffer.writeln('<h2>NPCs</h2>');
      for (final npc in npcs) {
        buffer.writeln('<div class="npc">');
        buffer.writeln('<h3>${npc.name}</h3>');
        buffer.writeln(
          '<p class="subtitle">${npc.race} ${npc.characterClass} | ${npc.alignment}</p>',
        );
        if (npc.role.isNotEmpty) {
          buffer.writeln('<p><strong>Role:</strong> ${npc.role}</p>');
        }
        if (npc.appearance.isNotEmpty) {
          buffer.writeln(
            '<p><strong>Appearance:</strong> ${npc.appearance}</p>',
          );
        }
        if (mode == DnDExportMode.gm && npc.backstory.isNotEmpty) {
          buffer.writeln(
            '<p class="gm-notes"><strong>Backstory:</strong> ${npc.backstory}</p>',
          );
        }
        buffer.writeln('</div>');
      }
      buffer.writeln('</div>');
    }

    // Magic Items
    if (items != null && items.isNotEmpty) {
      buffer.writeln('<div class="section items">');
      buffer.writeln('<h2>Magic Items</h2>');
      for (final item in items) {
        final isRedacted =
            item.redactions != null && item.redactions!.isNotEmpty;
        if (isRedacted && mode == DnDExportMode.player) continue;

        buffer.writeln('<div class="item">');
        buffer.writeln('<h3>${item.name}</h3>');
        buffer.writeln(
          '<p class="subtitle">${item.rarity} ${item.type}${item.requiresAttunement ? " (Requires Attunement)" : ""}</p>',
        );
        buffer.writeln('<p>${item.effects}</p>');
        if (item.mechanics.isNotEmpty) {
          buffer.writeln(
            '<p><strong>Mechanics:</strong> ${item.mechanics}</p>',
          );
        }
        if (mode == DnDExportMode.gm && item.lore.isNotEmpty) {
          buffer.writeln(
            '<p class="gm-notes"><strong>Lore:</strong> ${item.lore}</p>',
          );
        }
        buffer.writeln('</div>');
      }
      buffer.writeln('</div>');
    }

    // Notes
    if (notes != null && notes.isNotEmpty) {
      buffer.writeln('<div class="section notes">');
      buffer.writeln('<h2>Adventure Notes</h2>');
      for (final note in notes) {
        final isRedacted =
            note.redactions != null && note.redactions!.isNotEmpty;
        if (isRedacted && mode == DnDExportMode.player) continue;

        buffer.writeln('<div class="note">');
        buffer.writeln('<h3>${note.title}</h3>');
        buffer.writeln('<p>${note.content}</p>');
        buffer.writeln('</div>');
      }
      buffer.writeln('</div>');
    }

    buffer.writeln('</div>'); // end export-container
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  /// Get CSS styles for theme
  static String _getThemeStyles(DnDExportTheme theme) {
    String bgColor, textColor, headingColor, accentColor;

    switch (theme) {
      case DnDExportTheme.parchment:
        bgColor = '#F4E8D8';
        textColor = '#3E2723';
        headingColor = '#5D4037';
        accentColor = '#D84315';
        break;
      case DnDExportTheme.darkArcana:
        bgColor = '#1A1A2E';
        textColor = '#E0E0E0';
        headingColor = '#9C27B0';
        accentColor = '#BA68C8';
        break;
      case DnDExportTheme.glassmorphic:
        bgColor = 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)';
        textColor = '#FFFFFF';
        headingColor = '#FFFFFF';
        accentColor = '#00BCD4';
        break;
      default:
        bgColor = '#FFFFFF';
        textColor = '#000000';
        headingColor = '#333333';
        accentColor = '#1976D2';
    }

    // Add fallback for gradients
    final displayBg = theme == DnDExportTheme.glassmorphic
        ? 'background: #667eea; background: $bgColor;'
        : 'background-color: $bgColor;';

    return '''
    <style>
      * { box-sizing: border-box; }
      body {
        margin: 0;
        padding: 0;
        $displayBg
        color: $textColor;
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        line-height: 1.6;
        min-height: 100vh;
      }
      .export-container {
        max-width: 900px;
        margin: 0 auto;
        padding: 40px 20px;
        background: rgba(255,255,255,0.05);
        backdrop-filter: blur(10px);
        box-shadow: 0 8px 32px rgba(0,0,0,0.1);
        min-height: 100vh;
      }
      @media screen and (max-width: 600px) {
        .export-container { padding: 20px 15px; }
      }
      .title-page {
        text-align: center;
        margin-bottom: 60px;
        padding: 40px;
        background: rgba(0,0,0,0.05);
        border-radius: 24px;
      }
      h1 {
        font-size: 3em;
        color: $headingColor;
        margin-bottom: 20px;
        text-transform: uppercase;
        letter-spacing: 2px;
      }
      h2 {
        font-size: 2em;
        color: $headingColor;
        border-bottom: 2px solid $accentColor;
        padding-bottom: 10px;
        margin-top: 40px;
      }
      h3 {
        font-size: 1.5em;
        color: $headingColor;
        margin-top: 20px;
      }
      .author {
        font-size: 1.2em;
        font-style: italic;
      }
      .mode {
        font-size: 0.9em;
        color: $accentColor;
        font-weight: bold;
      }
      .chapter {
        margin-bottom: 40px;
        page-break-after: always;
      }
      .encounter, .npc, .location, .item, .note {
        background: rgba(255,255,255,0.05);
        padding: 20px;
        margin: 20px 0;
        border-left: 4px solid $accentColor;
        border-radius: 0 16px 16px 0;
      }
      .gm-notes {
        font-style: italic;
        color: $accentColor;
        font-size: 0.9em;
        background: rgba(0,0,0,0.1);
        padding: 10px;
        margin: 5px 0;
        border-radius: 8px;
      }
      .subtitle {
        font-size: 0.9em;
        opacity: 0.8;
        font-style: italic;
      }
    </style>
    ''';
  }
}
