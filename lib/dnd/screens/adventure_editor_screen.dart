import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:logger/logger.dart';

import 'package:provider/provider.dart';

import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_background.dart';
import '../../widgets/integrated_action_bar.dart';
import '../../widgets/chapters_sidebar.dart';
import '../../widgets/logo_header.dart';
import '../widgets/encounters_tab.dart';
import '../widgets/npcs_tab.dart';
import '../widgets/locations_tab.dart';
import '../widgets/items_tab.dart';
import '../widgets/notes_tab.dart';
import '../services/dnd_export_service.dart';
import 'dnd_export_preview_screen.dart';
import '../../services/export_service.dart';

class AdventureEditorScreen extends StatefulWidget {
  final Book book;
  final Chapter chapter;

  const AdventureEditorScreen({
    super.key,
    required this.book,
    required this.chapter,
  });

  @override
  State<AdventureEditorScreen> createState() => _AdventureEditorScreenState();
}

class _AdventureEditorScreenState extends State<AdventureEditorScreen> {
  final Logger _logger = Logger();
  late quill.QuillController _quillController;
  late TextEditingController _titleController;
  bool _hasUnsavedChanges = false;
  bool _showChapters = false;
  bool _showMetadataPanel = true;
  bool _showNotes = false;
  bool _isDistractionFree = false;
  late Chapter _chapter;
  Timer? _saveDebounce;
  late FocusNode _focusNode;
  EditorMode currentMode = EditorMode.write;
  bool _isLoadingChapters = false;
  List<Chapter> _chapterList = [];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _chapter = widget.chapter;
    _titleController = TextEditingController(text: _chapter.title);
    _initQuillController();
    _loadChapters();

    // Apply specific theme for Adventure directly if needed, or rely on Book theme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ThemeService>(
          context,
          listen: false,
        ).setSeedColor(const Color(0xFF5D4037));
      }
    });

    _titleController.addListener(() {
      if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
      _debouncedSave();
    });
  }

  Future<void> _loadChapters() async {
    setState(() => _isLoadingChapters = true);
    try {
      final chapters = await DatabaseService.getChapters(widget.book.id);
      if (mounted) {
        setState(() {
          _chapterList = chapters;
          _isLoadingChapters = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingChapters = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _focusNode.dispose();
    _saveDebounce?.cancel();
    super.dispose();
  }

  void _initQuillController() {
    try {
      if (_chapter.content.isEmpty) {
        _quillController = quill.QuillController.basic();
      } else {
        try {
          final contentJson = jsonDecode(_chapter.content);
          final ops = contentJson['ops'] as List;
          _quillController = quill.QuillController(
            document: quill.Document.fromJson(ops),
            selection: const TextSelection.collapsed(offset: 0),
          );
        } catch (e) {
          _quillController = quill.QuillController.basic();
        }
      }

      _quillController.document.changes.listen((event) {
        if (!_hasUnsavedChanges && mounted) {
          setState(() => _hasUnsavedChanges = true);
        }
        _debouncedSave();
      });
    } catch (e) {
      _quillController = quill.QuillController.basic();
    }
  }

  void _debouncedSave() {
    if (_saveDebounce?.isActive ?? false) _saveDebounce!.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 1000), _saveChapter);
  }

  Future<void> _saveChapter() async {
    try {
      final deltaOps = _quillController.document.toDelta().toJson();
      final content = jsonEncode({'ops': deltaOps});

      final updatedChapter = _chapter.copyWith(
        title: _titleController.text.trim(),
        content: content,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.updateChapter(updatedChapter);

      if (mounted) {
        setState(() {
          _chapter = updatedChapter;
          _hasUnsavedChanges = false;
        });
      }
    } catch (e) {
      _logger.e('Error saving chapter: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          return DefaultTabController(
            length:
                7, // Write, Outline, Encounters, NPCs, Locations, Items, Notes
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: true,
              appBar: _isDistractionFree ? null : _buildAppBar(),
              drawer: isMobile
                  ? Drawer(
                      child: ChaptersSidebar(
                        book: widget.book,
                        currentChapterId: _chapter.id,
                        onClose: () => Navigator.pop(context),
                      ),
                    )
                  : null,
              floatingActionButton: _buildFab(isMobile),
              body: Row(
                children: [
                  // Left Sidebar: Chapters (Only visible in Write/Outline modes usually,
                  // but let's keep it contextual or controlled by the toggle)
                  if (_showChapters && !isMobile && !_isDistractionFree)
                    Padding(
                      padding: const EdgeInsets.only(top: kToolbarHeight + 8),
                      child: GlassContainer(
                        width: 280,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        opacity: 0.1,
                        child: ChaptersSidebar(
                          book: widget.book,
                          currentChapterId: _chapter.id,
                          onClose: () => setState(() => _showChapters = false),
                        ),
                      ),
                    ),

                  // Main Content Area
                  Expanded(
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            if (!_isDistractionFree)
                              const SizedBox(height: kToolbarHeight + 16),

                            // Floating Quill Toolbar
                            if (currentMode == EditorMode.edit &&
                                !_isDistractionFree)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  8,
                                  24,
                                  8,
                                ),
                                child: GlassContainer(
                                  borderRadius: BorderRadius.circular(12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: quill.QuillSimpleToolbar(
                                    controller: _quillController,
                                  ),
                                ),
                              ),

                            // Tab Bar (Custom Glass Design)
                            if (!_isDistractionFree)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: GlassContainer(
                                  height: 48,
                                  borderRadius: BorderRadius.circular(16),
                                  opacity: 0.1,
                                  child: TabBar(
                                    indicator: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.2),
                                    ),
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    splashBorderRadius: BorderRadius.circular(
                                      16,
                                    ),
                                    dividerColor: Colors.transparent,
                                    labelColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    unselectedLabelColor: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                    tabs: const [
                                      Tab(text: 'Write'),
                                      Tab(text: 'Outline'),
                                      Tab(text: 'Encounters'),
                                      Tab(text: 'NPCs'),
                                      Tab(text: 'Locations'),
                                      Tab(text: 'Items'),
                                      Tab(text: 'Notes'),
                                    ],
                                  ),
                                ),
                              ),

                            if (!_isDistractionFree) const SizedBox(height: 16),

                            // Tab Views
                            Expanded(
                              child: TabBarView(
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  // 1. Write Tab
                                  Container(
                                    margin: _isDistractionFree
                                        ? EdgeInsets.zero
                                        : const EdgeInsets.fromLTRB(
                                            16,
                                            0,
                                            16,
                                            16,
                                          ),
                                    child: GlassContainer(
                                      borderRadius: _isDistractionFree
                                          ? BorderRadius.zero
                                          : BorderRadius.circular(24),
                                      opacity: _isDistractionFree ? 0 : 0.05,
                                      child: _buildEditor(),
                                    ),
                                  ),

                                  // 2. Outline Tab
                                  Container(
                                    margin: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      16,
                                    ),
                                    child: GlassContainer(
                                      borderRadius: BorderRadius.circular(24),
                                      opacity: 0.05,
                                      child: _isLoadingChapters
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                          : _chapterList.isEmpty
                                          ? const Center(
                                              child: Text("No chapters found"),
                                            )
                                          : ListView.builder(
                                              itemCount: _chapterList.length,
                                              itemBuilder: (context, index) {
                                                final ch = _chapterList[index];
                                                return ListTile(
                                                  leading: const Icon(
                                                    Icons.menu_book,
                                                  ),
                                                  title: Text(ch.title),
                                                  selected:
                                                      ch.id == _chapter.id,
                                                  onTap: () async {
                                                    if (ch.id == _chapter.id)
                                                      return;

                                                    // Auto-save current chapter before switching
                                                    await _saveChapter();

                                                    if (mounted) {
                                                      setState(() {
                                                        _chapter = ch;
                                                        _titleController.text =
                                                            ch.title;
                                                      });
                                                      _initQuillController();
                                                    }
                                                  },
                                                );
                                              },
                                            ),
                                    ),
                                  ),

                                  // 3. Encounters Tab
                                  Container(
                                    margin: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      16,
                                    ),
                                    child: EncountersTab(
                                      chapter: _chapter,
                                      onEncounterUpdate: (encounter) async {
                                        await DatabaseService.saveDndEncounter(
                                          encounter,
                                        );
                                      },
                                      onEncounterDelete: (encounterId) async {
                                        await DatabaseService.deleteDndEncounter(
                                          encounterId,
                                        );
                                      },
                                    ),
                                  ),

                                  // 4. NPCs Tab
                                  NpcsTab(book: widget.book),

                                  // 5. Locations Tab
                                  LocationsTab(book: widget.book),

                                  // 6. Items Tab
                                  ItemsTab(book: widget.book),

                                  // 7. Notes Tab
                                  NotesTab(book: widget.book),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Integrated Action Bar (Floating)
                        Positioned(
                          bottom: 24,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: IntegratedActionBar(
                              currentMode: currentMode,
                              isDistractionFree: _isDistractionFree,
                              isNotesOpen: _showNotes,
                              hasUnsavedChanges: _hasUnsavedChanges,
                              onModeChanged: (mode) {
                                setState(() {
                                  currentMode = mode;
                                  if (mode == EditorMode.write) {
                                    _isDistractionFree = true;
                                  } else if (mode == EditorMode.edit) {
                                    _isDistractionFree = false;
                                  } else if (mode == EditorMode.view) {
                                    _isDistractionFree = false;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DnDExportPreviewScreen(
                                              book: widget.book,
                                            ),
                                      ),
                                    );
                                  } else if (mode == EditorMode.notes) {
                                    _showNotes = !_showNotes;
                                  } else if (mode == EditorMode.share) {
                                    _showExportDialog();
                                  }
                                });
                              },
                              onInfoPressed: () {
                                setState(
                                  () =>
                                      _showMetadataPanel = !_showMetadataPanel,
                                );
                              },
                              onShowOutline: () {
                                setState(() => _showChapters = !_showChapters);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right Sidebar (Metadata)
                  if (!_isDistractionFree && _showMetadataPanel)
                    Padding(
                      padding: const EdgeInsets.only(top: kToolbarHeight + 8),
                      child: GlassContainer(
                        width: 300,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                        ),
                        opacity: 0.1,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Adventure Metadata",
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              _buildMetadataItem("Title", widget.book.title),
                              _buildMetadataItem("Author", widget.book.author),
                              _buildMetadataItem(
                                "Created",
                                widget.book.createdAt.toString(),
                              ),
                              _buildMetadataItem(
                                "Last Modified",
                                widget.book.updatedAt.toString(),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "Word Count",
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${_quillController.document.length} characters",
                                style: const TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          const LogoHeader(size: 32, showText: false),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ADVENTURE',
                style: const TextStyle(
                  color: Color(0xFFD7CCC8),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 2.0,
                ),
              ),
              Text(widget.book.title, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        // Title Input
        Padding(
          padding: const EdgeInsets.all(24),
          child: TextField(
            controller: _titleController,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Merriweather',
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Scene Title',
              hintStyle: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),

        // Editor
        Expanded(
          child: Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: Theme.of(context).colorScheme.primary,
                selectionColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
                selectionHandleColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            child: quill.QuillEditor.basic(
              controller: _quillController,
              focusNode: _focusNode,
            ),
          ),
        ),
      ],
    );
  }

  void _showExportDialog() {
    DnDExportFormat selectedFormat = DnDExportFormat.pdf;
    DnDExportMode selectedMode = DnDExportMode.gm;
    DnDExportTheme selectedTheme = DnDExportTheme.parchment;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Export Adventure'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<DnDExportFormat>(
                value: selectedFormat,
                decoration: const InputDecoration(labelText: 'Format'),
                items: DnDExportFormat.values.map((f) {
                  return DropdownMenuItem(
                    value: f,
                    child: Text(f.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) => setDialogState(() => selectedFormat = val!),
              ),
              DropdownButtonFormField<DnDExportMode>(
                value: selectedMode,
                decoration: const InputDecoration(labelText: 'Version'),
                items: DnDExportMode.values.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(
                      m == DnDExportMode.gm ? 'Game Master' : 'Player',
                    ),
                  );
                }).toList(),
                onChanged: (val) => setDialogState(() => selectedMode = val!),
              ),
              DropdownButtonFormField<DnDExportTheme>(
                value: selectedTheme,
                decoration: const InputDecoration(labelText: 'Theme'),
                items: DnDExportTheme.values.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(t.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) => setDialogState(() => selectedTheme = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Exporting...')));

                try {
                  final chapters = await DatabaseService.getChapters(
                    widget.book.id,
                  );
                  final npcs = await DatabaseService.getDndNpcs(widget.book.id);
                  final locations = await DatabaseService.getDndLocations(
                    widget.book.id,
                  );
                  final items = await DatabaseService.getDndMagicItems(
                    widget.book.id,
                  );
                  final notes = await DatabaseService.getDndNotes(
                    widget.book.id,
                  );
                  final encounters = await DatabaseService.getDndEncounters(
                    widget.book.id,
                  );

                  if (selectedFormat == DnDExportFormat.pdf) {
                    await DnDExportService.exportAdventureToPdf(
                      book: widget.book,
                      chapters: chapters,
                      npcs: npcs,
                      locations: locations,
                      items: items,
                      notes: notes,
                      encounters: encounters,
                      mode: selectedMode,
                      theme: selectedTheme,
                    );
                  } else {
                    final html = DnDExportService.exportAdventureToHtml(
                      book: widget.book,
                      chapters: chapters,
                      npcs: npcs,
                      locations: locations,
                      items: items,
                      notes: notes,
                      encounters: encounters,
                      mode: selectedMode,
                      theme: selectedTheme,
                    );
                    // Use standard export service for HTML file saving
                    await ExportService.saveFile(
                      widget.book.title,
                      '.html',
                      Uint8List.fromList(utf8.encode(html)),
                    );
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export Successful!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Export Failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Export'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget? _buildFab(bool isMobile) {
    if (!isMobile) return null;

    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Quick Create',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text('Add NPC'),
                  onTap: () {
                    Navigator.pop(context);
                    // Open NPC Tab
                    DefaultTabController.of(context).animateTo(3);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_location),
                  title: const Text('Add Location'),
                  onTap: () {
                    Navigator.pop(context);
                    // Open Location Tab
                    DefaultTabController.of(context).animateTo(4);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.note_add),
                  title: const Text('Add Note'),
                  onTap: () {
                    Navigator.pop(context);
                    // Open Note Tab
                    DefaultTabController.of(context).animateTo(6);
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: const Icon(Icons.add),
    );
  }
}
