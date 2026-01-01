import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import 'dart:async';
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
  bool _isToolbarCollapsed = false;
  late Chapter _chapter;
  Timer? _saveDebounce;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _chapter = widget.chapter;
    _titleController = TextEditingController(text: _chapter.title);
    _initQuillController();

    // Apply specific theme for Adventure directly if needed, or rely on Book theme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // DnD Theme (Dark Brown / Parchment)
      Provider.of<ThemeService>(
        context,
        listen: false,
      ).setSeedColor(const Color(0xFF5D4037));
    });

    _titleController.addListener(() {
      if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
      _debouncedSave();
    });
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
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: _isDistractionFree ? null : _buildAppBar(),
          body: Row(
            children: [
              // Left Sidebar: Chapters (Only visible in Write/Outline modes usually,
              // but let's keep it contextual or controlled by the toggle)
              if (_showChapters && !_isDistractionFree)
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

                        // Tab Bar (Custom Glass Design)
                        if (!_isDistractionFree)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: GlassContainer(
                              height: 48,
                              borderRadius: BorderRadius.circular(24),
                              opacity: 0.1,
                              child: TabBar(
                                indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.2),
                                ),
                                dividerColor: Colors.transparent,
                                labelColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                unselectedLabelColor: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                                tabs: const [
                                  Tab(text: 'Write'),
                                  Tab(text: 'Outline'),
                                  Tab(text: 'Encounters'),
                                ],
                              ),
                            ),
                          ),

                        if (!_isDistractionFree) const SizedBox(height: 16),

                        // Tab Views
                        Expanded(
                          child: TabBarView(
                            physics:
                                const NeverScrollableScrollPhysics(), // Prevent swipe
                            children: [
                              // 1. Write Tab
                              Container(
                                margin: _isDistractionFree
                                    ? EdgeInsets.zero
                                    : const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: GlassContainer(
                                  borderRadius: _isDistractionFree
                                      ? BorderRadius.zero
                                      : BorderRadius.circular(24),
                                  opacity: _isDistractionFree ? 0 : 0.05,
                                  child: _buildEditor(), // Existing editor
                                ),
                              ),

                              // 2. Outline Tab (Placeholder for now)
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
                                  child: const Center(
                                    child: Text("Outline View (Coming Soon)"),
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
                                child: const Center(
                                  child: Text("Encounters UI Loading..."),
                                ),
                                // We will replace this with EncountersTab widget shortly
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Integrated Action Bar (Floating)
                    Positioned(
                      top: _isDistractionFree
                          ? (MediaQuery.of(context).padding.top + 16)
                          : (MediaQuery.of(context).padding.top +
                                kToolbarHeight +
                                16),
                      right: 16,
                      child: IntegratedActionBar(
                        currentMode: _isDistractionFree
                            ? EditorMode.write
                            : EditorMode.edit,
                        isNotesOpen: _showNotes,
                        isToolbarOpen: !_isToolbarCollapsed,
                        isDistractionFree: _isDistractionFree,
                        hasUnsavedChanges: _hasUnsavedChanges,
                        onShowOutline: () =>
                            setState(() => _showChapters = !_showChapters),
                        onInfoPressed: () => setState(
                          () => _showMetadataPanel = !_showMetadataPanel,
                        ),
                        // ... (keeping existing logic for onModeChanged)
                        onModeChanged: (mode) {
                          if (mode == EditorMode.write) {
                            setState(
                              () => _isDistractionFree = !_isDistractionFree,
                            );
                          } else if (mode == EditorMode.notes) {
                            setState(() => _showNotes = !_showNotes);
                          }
                          // Extended logic handled in existing method if needed
                        },
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
                    child: Center(
                      child: Text(
                        "Adventure Metadata\n(Coming Soon)",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFD7CCC8)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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
}
