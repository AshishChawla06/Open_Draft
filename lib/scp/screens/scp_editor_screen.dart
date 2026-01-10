import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart' as quill_delta;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';
import '../../services/image_service.dart';
import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../services/database_service.dart';
import '../../models/scp_log.dart';

import '../widgets/scp_metadata_panel.dart';
import '../widgets/log_editor.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';
import '../../widgets/chapters_sidebar.dart';
import '../../widgets/notes_sidebar.dart';
import '../../services/validation_service.dart';
import '../../widgets/template_selection_dialog.dart';
import '../../models/template.dart';
import '../../models/snapshot.dart';
import '../../screens/history_screen.dart';
import 'package:uuid/uuid.dart';
import '../../screens/reader_screen.dart';
import '../../widgets/logo_header.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_background.dart';
import '../../widgets/integrated_action_bar.dart';
import '../../screens/export_screen.dart';
import '../../models/redaction.dart';
import '../../widgets/advanced_redactor_overlay.dart';

class SCPEditorScreen extends StatefulWidget {
  final Book book;
  final Chapter chapter;

  const SCPEditorScreen({super.key, required this.book, required this.chapter});

  @override
  State<SCPEditorScreen> createState() => _SCPEditorScreenState();
}

class _SCPEditorScreenState extends State<SCPEditorScreen> {
  final Logger _logger = Logger();
  late quill.QuillController _quillController;
  late TextEditingController _titleController;
  bool _hasUnsavedChanges = false;
  bool _showMetadataPanel = true;
  bool _showChapters = false;
  bool _showNotes = false;
  bool _isDistractionFree = false;
  bool _isToolbarCollapsed = false;
  late Chapter _chapter;
  late Book _book;
  Timer? _saveDebounce;
  late FocusNode _focusNode;
  List<SCPLog> _logs = [];

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _focusNode.dispose();
    _saveDebounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _chapter = widget.chapter;
    _book = widget.book;

    // Apply book theme if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_book.themeColor != null) {
        Provider.of<ThemeService>(
          context,
          listen: false,
        ).setSeedColor(Color(_book.themeColor!));
      }
    });

    _logger.d('SCPEditorScreen init. ID: ${_chapter.id}');
    _logger.d('Content length: ${_chapter.content.length}');

    _titleController = TextEditingController(text: _chapter.title);
    _initQuillController();
    _loadLogs();

    _titleController.addListener(() {
      if (!_hasUnsavedChanges) {
        setState(() => _hasUnsavedChanges = true);
      }
      _debouncedSave();
    });
  }

  Future<void> _loadLogs() async {
    try {
      final logs = await DatabaseService.getLogsForChapter(_chapter.id);
      if (mounted) {
        setState(() => _logs = logs);
      }
    } catch (e) {
      _logger.e('Error loading logs: $e');
    }
  }

  void _addNewLog(String type) {
    if (_chapter.id.isEmpty) return;

    final newLog = SCPLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chapterId: _chapter.id,
      type: type,
      entries: [],
      createdAt: DateTime.now(),
    );

    setState(() => _logs.add(newLog));
    DatabaseService.saveLog(newLog);
  }

  void _updateLog(SCPLog updatedLog) {
    final index = _logs.indexWhere((l) => l.id == updatedLog.id);
    if (index != -1) {
      setState(() => _logs[index] = updatedLog);
      DatabaseService.saveLog(updatedLog);
    }
  }

  void _deleteLog(String logId) {
    setState(() => _logs.removeWhere((l) => l.id == logId));
    DatabaseService.deleteLog(logId);
  }

  Future<void> _reloadBookMetadata() async {
    try {
      final books = await DatabaseService.getAllBooks();
      final updatedBook = books.firstWhere((b) => b.id == _book.id);
      if (mounted) {
        setState(() {
          _book = updatedBook;
        });
      }
    } catch (e) {
      _logger.e('Error reloading book metadata: $e');
    }
  }

  void _debouncedSave() {
    if (_saveDebounce?.isActive ?? false) _saveDebounce!.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 1000), _saveChapter);
  }

  void _applyRedaction(Color color) {
    final controller = _quillController;
    if (!controller.selection.isValid) return;

    if (color == Colors.transparent) {
      controller.formatSelection(
        quill.Attribute.clone(quill.Attribute.color, null),
      );
      controller.formatSelection(
        quill.Attribute.clone(quill.Attribute.background, null),
      );
      return;
    }

    // For redaction, we want the text to be the same color as the background
    // If the chosen color is too close to the theme background, it might be invisible as a block.
    // However, traditionally SCP redactions are solid blocks.
    final colorHex =
        '#${(color.a * 255).toInt().toRadixString(16).padLeft(2, '0')}${(color.r * 255).toInt().toRadixString(16).padLeft(2, '0')}${(color.g * 255).toInt().toRadixString(16).padLeft(2, '0')}${(color.b * 255).toInt().toRadixString(16).padLeft(2, '0')}'
            .toUpperCase();
    controller.formatSelection(quill.ColorAttribute(colorHex));
    controller.formatSelection(quill.BackgroundAttribute(colorHex));
  }

  Future<void> _pickAddendumImage() async {
    final image = await ImageService.pickImage();
    if (image != null) {
      final savedPath = await ImageService.saveImage(
        image,
        _chapter.id,
        category: 'sections',
      );
      if (savedPath != null) {
        setState(() {
          _chapter = _chapter.copyWith(coverUrl: savedPath);
          _hasUnsavedChanges = true;
        });
        _saveChapter();
      }
    }
  }

  void _removeAddendumImage() {
    if (_chapter.coverUrl != null) {
      ImageService.deleteImage(_chapter.coverUrl!);
      setState(() {
        _chapter = _chapter.copyWith(coverUrl: ''); // Empty string to clear
        _hasUnsavedChanges = true;
      });
      _saveChapter();
    }
  }

  void _initQuillController() {
    try {
      if (_chapter.content.isEmpty) {
        _logger.d('Initializing editor with empty content');
        _quillController = quill.QuillController.basic();
      } else {
        _logger.d(
          'Initializing editor with content length: ${_chapter.content.length}',
        );
        try {
          final contentJson = jsonDecode(_chapter.content);
          final ops = contentJson['ops'] as List;
          _quillController = quill.QuillController(
            document: quill.Document.fromJson(ops),
            selection: const TextSelection.collapsed(offset: 0),
          );
        } catch (e) {
          _logger.e('JSON decode failed: $e');
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
      _logger.e('Error initializing Quill controller: $e');
      _quillController = quill.QuillController.basic();
    }
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

  void _addOverlayRedaction() {
    final newRedaction = Redaction(
      start: DateTime.now().millisecondsSinceEpoch,
      end: DateTime.now().millisecondsSinceEpoch,
      displayMode: 'overlay',
      style: 'bar',
      x: 150,
      y: 150,
      width: 200,
      height: 60,
    );

    setState(() {
      _chapter = _chapter.copyWith(
        redactions: [...(_chapter.redactions ?? []), newRedaction],
      );
      _hasUnsavedChanges = true;
    });
    _debouncedSave();
  }

  void _runValidation() async {
    final result = ValidationService.validateBook(widget.book);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.isValid ? Icons.check_circle : Icons.warning_amber_rounded,
              color: result.isValid ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(result.isValid ? 'Validation Passed' : 'Validation Issues'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.isValid)
              const Text('This document meets all structure requirements.')
            else ...[
              if (result.errors.isNotEmpty) ...[
                const Text(
                  'Errors:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                ...result.errors.map((e) => Text('• $e')),
                const SizedBox(height: 8),
              ],
              if (result.warnings.isNotEmpty) ...[
                const Text(
                  'Warnings:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                ...result.warnings.map((e) => Text('• $e')),
              ],
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _setWordCountGoal() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(
          text: _chapter.wordCountGoal?.toString() ?? '',
        );
        return AlertDialog(
          title: const Text('Set Word Count Goal'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Target Word Count',
              hintText: 'e.g., 1000',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final goal = int.tryParse(controller.text);
                setState(() {
                  _chapter = _chapter.copyWith(wordCountGoal: goal);
                  _hasUnsavedChanges = true;
                });
                _saveChapter();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: _isDistractionFree ? null : _buildAppBar(),
        body: Row(
          children: [
            // Left Sidebar: Chapters
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
                    currentChapterId: widget.chapter.id,
                    onClose: () => setState(() => _showChapters = false),
                  ),
                ),
              ),

            // Main Content (Editor)
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      if (!_isDistractionFree)
                        const SizedBox(height: kToolbarHeight + 16),
                      Expanded(
                        child: Container(
                          margin: _isDistractionFree
                              ? EdgeInsets.zero
                              : const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: GlassContainer(
                            borderRadius: _isDistractionFree
                                ? BorderRadius.zero
                                : BorderRadius.circular(24),
                            opacity: _isDistractionFree ? 0 : 0.05,
                            child: _buildEditor(),
                          ),
                        ),
                      ),
                    ],
                  ),

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
                      onModeChanged: (mode) {
                        switch (mode) {
                          case EditorMode.write:
                            setState(() {
                              _isDistractionFree = !_isDistractionFree;
                              if (_isDistractionFree) {
                                _showNotes = false;
                                _showChapters = false;
                                _showMetadataPanel = false;
                              }
                            });
                            break;
                          case EditorMode.edit:
                            if (_isDistractionFree) {
                              setState(() => _isDistractionFree = false);
                            } else {
                              setState(
                                () =>
                                    _isToolbarCollapsed = !_isToolbarCollapsed,
                              );
                            }
                            break;
                          case EditorMode.notes:
                            setState(() {
                              _showNotes = !_showNotes;
                              if (_showNotes) {
                                _showChapters = false;
                                _showMetadataPanel = false;
                              }
                            });
                            break;
                          case EditorMode.view:
                            _saveChapter().then((_) {
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReaderScreen(
                                      book: widget.book,
                                      chapter: _chapter,
                                    ),
                                  ),
                                );
                              }
                            });
                            break;
                          case EditorMode.share:
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ExportScreen(book: widget.book),
                              ),
                            );
                            break;
                        }
                      },
                    ),
                  ),

                  // Advanced Redactor Overlays
                  ...(_chapter.redactions ?? [])
                      .where((r) => r.displayMode == 'overlay')
                      .map(
                        (redaction) => AdvancedRedactorOverlay(
                          key: ValueKey(
                            redaction.start,
                          ), // Use start as temporary stable key
                          redaction: redaction,
                          onUpdate: (updated) {
                            setState(() {
                              final index = _chapter.redactions!.indexWhere(
                                (r) => r.start == redaction.start,
                              );
                              if (index != -1) {
                                _chapter.redactions![index] = updated;
                                _hasUnsavedChanges = true;
                              }
                            });
                            _debouncedSave();
                          },
                          onDelete: () {
                            setState(() {
                              _chapter.redactions!.removeWhere(
                                (r) => r.start == redaction.start,
                              );
                              _hasUnsavedChanges = true;
                            });
                            _debouncedSave();
                          },
                        ),
                      ),

                  // Distraction Free Exit Button (Now removed as IntegratedActionBar handles it, or keep as fallback)
                ],
              ),
            ),

            // Right Sidebar: Metadata OR Notes
            if (!_isDistractionFree)
              if (_showMetadataPanel)
                Padding(
                  padding: const EdgeInsets.only(top: kToolbarHeight + 8),
                  child: GlassContainer(
                    width: 320,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                    opacity: 0.1,
                    child: SCPMetadataPanel(
                      book: _book,
                      onUpdate: _reloadBookMetadata,
                    ),
                  ),
                )
              else if (_showNotes)
                Padding(
                  padding: const EdgeInsets.only(top: kToolbarHeight + 8),
                  child: GlassContainer(
                    width: 300,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                    opacity: 0.1,
                    child: NotesSidebar(
                      bookId: widget.book.id,
                      chapterId: widget.chapter.id,
                      onClose: () => setState(() => _showNotes = false),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final colorScheme = Theme.of(context).colorScheme;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _book.scpMetadata?.itemNumber ?? 'SCP-XXXX',
                  style: const TextStyle(
                    color: Color(0xFFFF4444),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Courier Prime',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.chapter.title,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            if (value == 'goal') {
              _setWordCountGoal();
            } else if (value == 'preview') {
              await _saveChapter();
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ReaderScreen(book: widget.book, chapter: _chapter),
                  ),
                );
              }
            } else if (value == 'validate') {
              _runValidation();
            } else if (value == 'template') {
              _insertTemplate();
            } else if (value == 'save_version') {
              _saveSnapshot();
            } else if (value == 'history') {
              _viewHistory();
            } else if (value == 'redact_overlay') {
              _addOverlayRedaction();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'goal',
              child: Row(
                children: [
                  Icon(Icons.flag_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Set Goal'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'preview',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('Reader Mode'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'validate',
              child: Row(
                children: [
                  Icon(Icons.fact_check_outlined),
                  SizedBox(width: 8),
                  Text('Validate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'template',
              child: Row(
                children: [
                  Icon(Icons.format_paint_outlined),
                  SizedBox(width: 8),
                  Text('Insert Template'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'save_version',
              child: Row(
                children: [
                  Icon(Icons.save_as),
                  SizedBox(width: 8),
                  Text('Save Version'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  Icon(Icons.history, size: 20),
                  SizedBox(width: 12),
                  Text('History'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'redact_overlay',
              child: Row(
                children: [
                  Icon(Icons.layers_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Add Redactor Overlay'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scpRed = const Color(0xFFFF4444);

    return Column(
      children: [
        // Editor & Logs Area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CustomScrollView(
              slivers: [
                if (!_isDistractionFree)
                  SliverToBoxAdapter(
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: _isToolbarCollapsed
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      secondChild: const SizedBox(height: 16),
                      firstChild: Column(
                        children: [
                          // Custom Toolbar Row
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Text(
                                    'TOOLS:',
                                    style: TextStyle(
                                      color: const Color(
                                        0xFFFF4444,
                                      ).withValues(alpha: 0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<Color>(
                                    icon: const Icon(
                                      Icons.auto_fix_high,
                                      color: Color(0xFFFF4444),
                                    ),
                                    tooltip: 'Redaction Tools',
                                    onSelected: (value) {
                                      _applyRedaction(value);
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: Colors.black,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 16,
                                              height: 16,
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                border: Border.all(
                                                  color: Colors.white24,
                                                ),
                                              ),
                                              margin: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                            ),
                                            const Text('Black Block'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: Colors.white,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 16,
                                              height: 16,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.all(
                                                  color: Colors.black26,
                                                ),
                                              ),
                                              margin: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                            ),
                                            const Text('White Block'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: Colors.grey,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 16,
                                              height: 16,
                                              color: Colors.grey,
                                              margin: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                            ),
                                            const Text('Gray Block'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: Colors.transparent,
                                        child: Row(
                                          children: [
                                            Icon(Icons.close, size: 16),
                                            SizedBox(width: 8),
                                            Text('Clear Redaction'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Quill Toolbar
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFF333333)),
                                ),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: quill.QuillSimpleToolbar(
                                  controller: _quillController,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      if (!_isDistractionFree) ...[
                        TextField(
                          controller: _titleController,
                          scrollPadding: EdgeInsets.zero,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: const Color(0xFFFF4444), // SCP Red
                                fontFamily: 'Courier Prime',
                                fontWeight: FontWeight.bold,
                              ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Containment Procedures Title',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                          ),
                        ),
                        const Divider(color: Color(0xFFFF4444)),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _pickAddendumImage,
                            icon: const Icon(Icons.add_a_photo, size: 18),
                            label: const Text('Add Image to Addendum'),
                            style: TextButton.styleFrom(
                              foregroundColor: scpRed,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Quill Editor
                      Theme(
                        data: Theme.of(context).copyWith(
                          textSelectionTheme: const TextSelectionThemeData(
                            cursorColor: Color(0xFFFF4444),
                            selectionColor: Color(0x44FF4444),
                            selectionHandleColor: Color(0xFFFF4444),
                          ),
                        ),
                        child: quill.QuillEditor.basic(
                          controller: _quillController,
                          focusNode: _focusNode,
                        ),
                      ),

                      if (_chapter.coverUrl != null &&
                          _chapter.coverUrl!.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? Image.network(
                                      _chapter.coverUrl!,
                                      width: double.infinity,
                                      fit: BoxFit.fitWidth,
                                    )
                                  : Image.file(
                                      File(_chapter.coverUrl!),
                                      width: double.infinity,
                                      fit: BoxFit.fitWidth,
                                    ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                  onPressed: _removeAddendumImage,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 48),

                      if (!_isDistractionFree) ...[
                        const Divider(color: Color(0xFF333333)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ATTACHED LOGS & ADDENDA',
                              style: TextStyle(
                                color: Color(0xFFFF4444),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: Color(0xFFFF4444),
                              ),
                              tooltip: 'Add Log',
                              onSelected: _addNewLog,
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'interview',
                                  child: Text('Interview Log'),
                                ),
                                const PopupMenuItem(
                                  value: 'incident',
                                  child: Text('Incident Report'),
                                ),
                                const PopupMenuItem(
                                  value: 'test',
                                  child: Text('Test Record'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),

                if (!_isDistractionFree) ...[
                  if (_logs.isEmpty)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No logs attached.',
                            style: TextStyle(color: Colors.white24),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final log = _logs[index];
                        return LogEditor(
                          key: ValueKey(log.id),
                          log: log,
                          onUpdate: (updated) => _updateLog(updated),
                          onDelete: () => _deleteLog(log.id),
                        );
                      }, childCount: _logs.length),
                    ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _insertTemplate() async {
    final Template? selectedTemplate = await showDialog<Template>(
      context: context,
      builder: (context) =>
          TemplateSelectionDialog(documentType: widget.book.documentType),
    );

    if (selectedTemplate != null && mounted) {
      try {
        final contentJson = jsonDecode(selectedTemplate.content);
        final List<dynamic> ops = contentJson is Map
            ? contentJson['ops']
            : contentJson;
        final delta = quill_delta.Delta.fromJson(ops);

        final index = _quillController.selection.baseOffset;
        final length = _quillController.document.length;
        final safeIndex = (index < 0 || index > length) ? length - 1 : index;

        _quillController.document.compose(
          quill_delta.Delta()
            ..retain(safeIndex)
            ..concat(delta),
          quill.ChangeSource.local,
        );
      } catch (e) {
        _logger.e('Error inserting template: $e');
        // Fallback to simple insert
        final index = _quillController.selection.baseOffset;
        final length = _quillController.document.length;
        final safeIndex = (index < 0 || index > length) ? length - 1 : index;
        _quillController.document.insert(safeIndex, selectedTemplate.content);
      }
    }
  }

  Future<void> _saveSnapshot() async {
    final descriptionController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Version'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Create a snapshot of the current state?'),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g. Major rewrite',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _saveChapter(); // Ensure current changes are saved to DB first

      final snapshot = ChapterSnapshot(
        id: const Uuid().v4(),
        chapterId: _chapter.id,
        content: _chapter.content,
        timestamp: DateTime.now(),
        description: descriptionController.text.trim(),
      );

      await DatabaseService.saveSnapshot(snapshot);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Version saved')));
      }
    }
  }

  Future<void> _viewHistory() async {
    final updatedChapter = await Navigator.push<Chapter>(
      context,
      MaterialPageRoute(builder: (context) => HistoryScreen(chapter: _chapter)),
    );

    if (updatedChapter != null && mounted) {
      setState(() {
        _chapter = updatedChapter;
        // Reload content into editor
        try {
          final json = jsonDecode(_chapter.content);
          _quillController.document = quill.Document.fromJson(json);
        } catch (e) {
          _quillController.document = quill.Document()
            ..insert(0, _chapter.content);
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Version restored')));
    }
  }
}
