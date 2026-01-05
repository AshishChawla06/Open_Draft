import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../models/chapter.dart';
import '../models/npc.dart';
import '../models/location.dart';
import '../models/magic_item.dart';
import '../models/adventure_note.dart';
import '../models/encounter.dart';
import '../services/dnd_export_service.dart';
import '../../services/database_service.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_background.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class DnDExportPreviewScreen extends StatefulWidget {
  final Book book;

  const DnDExportPreviewScreen({super.key, required this.book});

  @override
  State<DnDExportPreviewScreen> createState() => _DnDExportPreviewScreenState();
}

class _DnDExportPreviewScreenState extends State<DnDExportPreviewScreen> {
  DnDExportTheme _theme = DnDExportTheme.parchment;
  bool _isLoading = true;

  List<Chapter> _chapters = [];
  List<Npc> _npcs = [];
  List<Location> _locations = [];
  List<MagicItem> _items = [];
  List<AdventureNote> _notes = [];
  List<Encounter> _encounters = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final bookId = widget.book.id;

    final results = await Future.wait([
      DatabaseService.getChapters(bookId),
      DatabaseService.getDndNpcs(bookId),
      DatabaseService.getDndLocations(bookId),
      DatabaseService.getDndMagicItems(bookId),
      DatabaseService.getDndNotes(bookId),

      DatabaseService.getDndEncounters(bookId),
    ]);

    if (mounted) {
      setState(() {
        _chapters = results[0] as List<Chapter>;
        _npcs = results[1] as List<Npc>;
        _locations = results[2] as List<Location>;
        _items = results[3] as List<MagicItem>;
        _notes = results[4] as List<AdventureNote>;
        _encounters = results[5] as List<Encounter>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const GlassBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Export Preview'),
          actions: [
            DropdownButton<DnDExportTheme>(
              value: _theme,
              dropdownColor: Colors.grey[900],
              underline: const SizedBox(),
              items: DnDExportTheme.values.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(
                    t.name.toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _theme = val);
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return Row(
                children: [
                  Expanded(
                    child: _buildPreviewPane('GM VERSION', DnDExportMode.gm),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _buildPreviewPane(
                      'PLAYER VERSION',
                      DnDExportMode.player,
                    ),
                  ),
                ],
              );
            } else {
              return DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'GM Version'),
                        Tab(text: 'Player Version'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildPreviewPane('GM VERSION', DnDExportMode.gm),
                          _buildPreviewPane(
                            'PLAYER VERSION',
                            DnDExportMode.player,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildPreviewPane(String label, DnDExportMode mode) {
    final html = DnDExportService.exportAdventureToHtml(
      book: widget.book,
      chapters: _chapters,
      npcs: _npcs,
      locations: _locations,
      items: _items,
      notes: _notes,
      encounters: _encounters,
      mode: mode,
      theme: _theme,
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          width: double.infinity,
          color: Colors.black26,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              child: HtmlWidget(html, textStyle: const TextStyle(fontSize: 14)),
            ),
          ),
        ),
      ],
    );
  }
}
