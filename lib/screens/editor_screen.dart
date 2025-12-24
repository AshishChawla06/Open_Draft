import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../models/book.dart';
import '../models/chapter.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';
import '../widgets/glass_container.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/validation_service.dart';
import '../widgets/notes_sidebar.dart';
import '../widgets/template_selection_dialog.dart';
import '../models/template.dart';
import '../widgets/chapters_sidebar.dart';
import '../models/snapshot.dart';
import 'history_screen.dart';
import 'package:uuid/uuid.dart';
import 'reader_screen.dart';
import '../widgets/grammar_panel.dart';
import '../models/bookmark.dart';

class EditorScreen extends StatefulWidget {
  final Book book;
  final Chapter chapter;

  const EditorScreen({super.key, required this.book, required this.chapter});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController _titleController;
  late quill.QuillController _quillController;
  late Chapter _chapter;
  late Book _book;

  bool _hasUnsavedChanges = false;
  Timer? _autosaveTimer;

  bool _isSaving = false;
  bool _showNotes = false;
  bool _showChapters = false;
  bool _showGrammar = false;
  bool _showBookmarks = false;
  bool _isDistractionFree = false;

  @override
  void initState() {
    super.initState();
    _chapter = widget.chapter;
    _book = widget.book;
    _titleController = TextEditingController(text: _chapter.title);

    _initQuillController();

    _titleController.addListener(_onTextChanged);
    _quillController.document.changes.listen((event) {
      _onTextChanged();
    });
  }

  void _initQuillController() {
    try {
      print('Initializing editor with content: ${_chapter.content}');
      if (_chapter.content.isNotEmpty) {
        if (_chapter.content.startsWith('[') ||
            _chapter.content.startsWith('{')) {
          try {
            final json = jsonDecode(_chapter.content);
            print('Decoded JSON: $json');
            print('JSON type: ${json.runtimeType}');

            // The saved format is {"ops": [...]}
            // Extract the ops list for Document.fromJson
            final ops = json is Map ? json['ops'] : json;
            _quillController = quill.QuillController(
              document: quill.Document.fromJson(ops),
              selection: const TextSelection.collapsed(offset: 0),
            );
            print('Successfully loaded Quill document from JSON');
          } catch (e, stackTrace) {
            print('ERROR loading Quill document: $e');
            print('Stack trace: $stackTrace');
            // Fallback to plain text
            _quillController = quill.QuillController(
              document: quill.Document()..insert(0, _chapter.content),
              selection: const TextSelection.collapsed(offset: 0),
            );
          }
        } else {
          _quillController = quill.QuillController(
            document: quill.Document()..insert(0, _chapter.content),
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
      } else {
        print('Content is empty, creating basic controller');
        _quillController = quill.QuillController.basic();
      }
    } catch (e, stackTrace) {
      print('ERROR in _initQuillController: $e');
      print('Stack trace: $stackTrace');
      _quillController = quill.QuillController(
        document: quill.Document()..insert(0, _chapter.content),
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  void _onTextChanged() {
    print('!!! TEXT CHANGED !!! hasUnsavedChanges: $_hasUnsavedChanges');
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }

    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 2), _saveChapter);
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _saveChapter() async {
    if (!mounted) return;

    setState(() => _isSaving = true);

    try {
      final deltaOps = _quillController.document.toDelta().toJson();
      // Wrap delta operations in the format expected by Document.fromJson
      final content = jsonEncode({'ops': deltaOps});
      print('!!! SAVING CONTENT !!!: $content'); // Distinct debug log
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
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  void _runValidation() {
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

  Future<void> _insertTemplate() async {
    final Template? selectedTemplate = await showDialog<Template>(
      context: context,
      builder: (context) =>
          TemplateSelectionDialog(documentType: widget.book.documentType),
    );

    if (selectedTemplate != null && mounted) {
      // Decode content
      final contentList = jsonDecode(selectedTemplate.content) as List;

      final index = _quillController.selection.baseOffset;
      final length = _quillController.document.length;

      // If document is empty or just has a newline
      final safeIndex = (index < 0 || index > length) ? length - 1 : index;

      for (var op in contentList) {
        if (op is Map && op.containsKey('insert')) {
          _quillController.document.insert(safeIndex, op['insert']);
        }
      }
    }
  }

  Future<void> _pickCoverImage() async {
    final image = await ImageService.pickImage();
    if (image != null) {
      final savedPath = await ImageService.saveImage(image, _chapter.id);
      if (savedPath != null) {
        // Extract dominant color
        final dominantColor = await ImageService.extractDominantColor(
          savedPath,
        );

        setState(() {
          _chapter = _chapter.copyWith(coverUrl: savedPath);
          _hasUnsavedChanges = true;
        });

        if (dominantColor != null) {
          // Update book theme color
          final updatedBook = _book.copyWith(
            themeColor: dominantColor.toARGB32(),
          );
          await DatabaseService.updateBook(updatedBook);

          if (mounted) {
            Provider.of<ThemeService>(
              context,
              listen: false,
            ).setSeedColor(dominantColor);
            setState(() => _book = updatedBook);
          }
        }

        _saveChapter();
      }
    }
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_hasUnsavedChanges) {
          await _saveChapter();
        }

        if (mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _isDistractionFree ? null : _buildAppBar(),
        body: Stack(
          children: [
            Container(color: Theme.of(context).scaffoldBackgroundColor),
            // Background elements hidden in distraction free mode
            if (!_isDistractionFree) ...[
              Positioned(
                top: -100,
                right: 100,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 100,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SafeArea(
              child: Row(
                children: [
                  // Chapters Sidebar
                  if (_showChapters && !_isDistractionFree)
                    ChaptersSidebar(
                      book: widget.book,
                      currentChapterId: widget.chapter.id,
                      onClose: () => setState(() => _showChapters = false),
                    ),

                  Expanded(
                    child: Column(
                      children: [
                        if (!_isDistractionFree) const SizedBox(height: 60),

                        // Toolbar (Validation placeholder/Edit mode)
                        if (!_isDistractionFree) _buildToolbar(),

                        // Progress Bar
                        if (!_isDistractionFree &&
                            _chapter.wordCountGoal != null)
                          _buildProgressBar(),

                        // Editor
                        Expanded(
                          child: Stack(
                            children: [
                              _buildEditor(),
                              if (_isDistractionFree)
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: IconButton(
                                    icon: const Icon(Icons.fullscreen_exit),
                                    onPressed: () => setState(
                                      () => _isDistractionFree = false,
                                    ),
                                    tooltip: 'Exit Distraction Free',
                                    style: IconButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .surface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notes Sidebar
                  if (_showNotes && !_isDistractionFree)
                    NotesSidebar(
                      bookId: widget.book.id,
                      chapterId: widget.chapter.id,
                      onClose: () => setState(() => _showNotes = false),
                    ),

                  // Grammar Panel
                  if (_showGrammar && !_isDistractionFree)
                    SizedBox(
                      width: 300,
                      child: GrammarPanel(
                        text: _quillController.document.toPlainText(),
                        onIssueSelected: (offset, length) {
                          // Select the text with the issue
                          _quillController.updateSelection(
                            TextSelection(
                              baseOffset: offset,
                              extentOffset: offset + length,
                            ),
                            quill.ChangeSource.local,
                          );
                        },
                      ),
                    ),

                  // Bookmark Sidebar
                  if (_showBookmarks && !_isDistractionFree)
                    _buildBookmarksSidebar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarksSidebar() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          _buildSidebarHeader('Bookmarks', Icons.bookmark, () {
            setState(() => _showBookmarks = false);
          }),
          Expanded(
            child: FutureBuilder<List<Bookmark>>(
              future: DatabaseService.getBookmarks(_book.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final bookmarks =
                    snapshot.data
                        ?.where((b) => b.chapterId == _chapter.id)
                        .toList() ??
                    [];

                if (bookmarks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No bookmarks in this chapter',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = bookmarks[index];
                    return ListTile(
                      leading: const Icon(Icons.bookmark_outline, size: 20),
                      title: Text(bookmark.title),
                      subtitle: Text('Pos: ${bookmark.position}'),
                      onTap: () {
                        _quillController.updateSelection(
                          TextSelection.collapsed(offset: bookmark.position),
                          quill.ChangeSource.local,
                        );
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () async {
                          await DatabaseService.deleteBookmark(bookmark.id);
                          setState(() {});
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(
    String title,
    IconData icon,
    VoidCallback onClose,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _addBookmark() async {
    final titleController = TextEditingController();
    final pos = _quillController.selection.start;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Bookmark'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Bookmark Title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && titleController.text.isNotEmpty) {
      final bookmark = Bookmark(
        id: const Uuid().v4(),
        bookId: _book.id,
        chapterId: _chapter.id,
        title: titleController.text,
        position: pos,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await DatabaseService.saveBookmark(bookmark);
      setState(() {
        _showBookmarks = true;
      });
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.book.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'Chapter ${_chapter.order}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(_isSaving ? Icons.cloud_upload : Icons.cloud_done),
          onPressed: _hasUnsavedChanges ? _saveChapter : null,
          tooltip: _hasUnsavedChanges ? 'Save changes' : 'All changes saved',
        ),
        IconButton(
          icon: Icon(
            _isDistractionFree ? Icons.fullscreen_exit : Icons.fullscreen,
          ),
          onPressed: () {
            setState(() {
              _isDistractionFree = !_isDistractionFree;
              if (_isDistractionFree) {
                _showNotes = false;
                _showChapters = false;
              }
            });
          },
          tooltip: 'Distraction Free Mode',
        ),
        IconButton(
          icon: Icon(_showChapters ? Icons.list_alt : Icons.list),
          onPressed: () => setState(() => _showChapters = !_showChapters),
          tooltip: 'Toggle Chapters',
        ),
        IconButton(
          icon: Icon(_showNotes ? Icons.notes_outlined : Icons.notes),
          onPressed: () => setState(() => _showNotes = !_showNotes),
          tooltip: 'Toggle Notes',
        ),
        IconButton(
          icon: Icon(_showBookmarks ? Icons.bookmark : Icons.bookmark_outline),
          onPressed: () => setState(() {
            _showBookmarks = !_showBookmarks;
            if (_showBookmarks) {
              _showNotes = false;
              _showChapters = false;
              _showGrammar = false;
            }
          }),
          tooltip: 'Toggle Bookmarks',
        ),
        PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'cover':
                _pickCoverImage();
                break;
              case 'goal':
                _setWordCountGoal();
                break;
              case 'preview':
                await _saveChapter(); // Save before preview
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ReaderScreen(book: widget.book, chapter: _chapter),
                    ),
                  );
                }
                break;
              case 'validate':
                _runValidation();
                break;
              case 'template':
                _insertTemplate();
                break;
              case 'save_version':
                _saveSnapshot();
                break;
              case 'history':
                _viewHistory();
                break;
              case 'bookmark':
                _addBookmark();
                break;
              case 'grammar':
                setState(() {
                  _showGrammar = !_showGrammar;
                  if (_showGrammar) {
                    _showNotes = false;
                    _showChapters = false;
                  }
                });
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'cover',
              child: Row(
                children: [
                  Icon(Icons.image),
                  SizedBox(width: 8),
                  Text('Chapter Cover'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'goal',
              child: Row(
                children: [
                  Icon(Icons.flag),
                  SizedBox(width: 8),
                  Text('Word Count Goal'),
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
              value: 'bookmark',
              child: Row(
                children: [
                  Icon(Icons.bookmark_add_outlined),
                  SizedBox(width: 8),
                  Text('Add Bookmark'),
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
                  Icon(Icons.history),
                  SizedBox(width: 8),
                  Text('History'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'grammar',
              child: Row(
                children: [
                  Icon(Icons.spellcheck),
                  SizedBox(width: 8),
                  Text('Grammar Check'),
                ],
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: GlassContainer(
        borderRadius: BorderRadius.zero,
        blur: 10,
        opacity: 0.1,
        child: Container(),
      ),
    );
  }

  Widget _buildToolbar() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).colorScheme.surface,
      opacity: 0.15,
      child: quill.QuillSimpleToolbar(controller: _quillController),
    );
  }

  Widget _buildProgressBar() {
    final wordCount = _quillController.document
        .toPlainText()
        .trim()
        .split(RegExp(r'\s+'))
        .length;
    final goal = _chapter.wordCountGoal!;
    final progress = (wordCount / goal).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$wordCount / $goal words',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            color: progress >= 1.0
                ? Colors.green
                : Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return GlassContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).colorScheme.surface,
      opacity: 0.1,
      child: Column(
        children: [
          if (_chapter.coverUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? Image.network(_chapter.coverUrl!, fit: BoxFit.cover)
                      : Image.file(File(_chapter.coverUrl!), fit: BoxFit.cover),
                ),
              ),
            ),

          TextField(
            controller: _titleController,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Chapter Title',
              border: InputBorder.none,
              hintStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),

          Expanded(
            child: quill.QuillEditor.basic(controller: _quillController),
          ),
        ],
      ),
    );
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
        _titleController.text = _chapter.title;
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
