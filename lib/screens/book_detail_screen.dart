import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/document_type.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_background.dart';
import '../widgets/logo_header.dart';
import '../widgets/tag_editor_dialog.dart';
import 'editor_screen.dart';
import 'world_building_screen.dart';
import 'export_screen.dart';
import '../services/image_service.dart';
import '../scp/screens/scp_editor_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Book _currentBook;
  Color? _tintColor;

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _extractColor();

    // Apply book theme if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentBook.themeColor != null) {
        Provider.of<ThemeService>(
          context,
          listen: false,
        ).setSeedColor(Color(_currentBook.themeColor!));
      }
    });
  }

  Future<void> _extractColor() async {
    if (_currentBook.coverUrl != null) {
      final color = await ImageService.extractDominantColor(
        _currentBook.coverUrl!,
      );
      if (mounted) {
        setState(() {
          _tintColor = color;
        });
      }
    }
  }

  Future<void> _reloadBook() async {
    try {
      final books = await DatabaseService.getAllBooks();
      final updatedBook = books.firstWhere((b) => b.id == widget.book.id);
      setState(() {
        _currentBook = updatedBook;
      });
      _extractColor();
    } catch (e) {
      // Error handling
    }
  }

  Future<void> _showExportDialog() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExportScreen(book: _currentBook)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassBackground(
      tintColor: _tintColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
            color: colorScheme.onSurface,
          ),
          title: const LogoHeader(size: 40, showText: true),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.public, size: 22), // World Building
              tooltip: 'World Building',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorldBuildingScreen(book: _currentBook),
                ),
              ),
              color: colorScheme.onSurface,
            ),
            IconButton(
              icon: const Icon(Icons.label_outline, size: 22),
              tooltip: 'Edit Tags',
              onPressed: _editTags,
              color: colorScheme.onSurface,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 22),
              tooltip: 'Export',
              onPressed: _showExportDialog,
              color: colorScheme.onSurface,
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 22),
              tooltip: 'Book Settings',
              onPressed: _editDetails,
              color: colorScheme.onSurface,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unified Detail Card
              GlassContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: BorderRadius.circular(32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book Cover
                    GestureDetector(
                      onTap: _showCoverOptions,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Stack(
                          children: [
                            Hero(
                              tag: 'book-cover-${_currentBook.id}',
                              child: _currentBook.coverUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: kIsWeb
                                          ? Image.network(
                                              _currentBook.coverUrl!,
                                              width: 140,
                                              height: 200,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.file(
                                              File(_currentBook.coverUrl!),
                                              width: 140,
                                              height: 200,
                                              fit: BoxFit.cover,
                                            ),
                                    )
                                  : Container(
                                      width: 140,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.book,
                                        size: 48,
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),

                    // Info Column
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentBook.title,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'By ${_currentBook.author}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildBadge(
                                _currentBook.documentType == DocumentType.scp
                                    ? 'SCP'
                                    : 'Novel',
                                _currentBook.documentType == DocumentType.scp
                                    ? Colors.blue
                                    : Colors.orange,
                              ),
                              ..._currentBook.tags.map(
                                (tag) => _buildBadge(tag, null),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Actions Column (Right Side)
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _editDetails,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GlassContainer(
                                    padding: const EdgeInsets.all(12),
                                    borderRadius: BorderRadius.circular(12),
                                    opacity: 0.1,
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  // Delete logic
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Draft?'),
                                      content: Text(
                                        'Are you sure you want to delete "${_currentBook.title}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await DatabaseService.deleteBook(
                                      _currentBook.id,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context); // Go back
                                    }
                                  }
                                },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GlassContainer(
                                    padding: const EdgeInsets.all(12),
                                    borderRadius: BorderRadius.circular(12),
                                    opacity: 0.1,
                                    color: colorScheme.error.withValues(
                                      alpha: 0.1,
                                    ),
                                    child: Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Stats (Vertical)
                          _buildStatRow(
                            context,
                            Icons.article_outlined,
                            'Chapters',
                            '${_currentBook.chapters.length}',
                          ),
                          const SizedBox(height: 12),
                          _buildStatRow(
                            context,
                            Icons.text_fields,
                            'Characters',
                            _calculateTotalCharacters(),
                          ),
                          const SizedBox(height: 12),
                          _buildStatRow(
                            context,
                            Icons.calendar_today,
                            'Updated',
                            _formatDate(_currentBook.updatedAt),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                _currentBook.description ?? 'No description provided.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 40),

              // Chapters Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chapters',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addChapter,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('New Chapter'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currentBook.chapters.length,
                itemBuilder: (context, index) {
                  final chapter = _currentBook.chapters[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => _openChapter(chapter),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(20),
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          children: [
                            Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chapter.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${chapter.content.length} characters',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Bottom spacing
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _calculateTotalCharacters() {
    int total = 0;
    for (var chapter in _currentBook.chapters) {
      total += chapter.content.length;
    }
    return total.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildBadge(String label, Color? accentColor) {
    final colorScheme = Theme.of(context).colorScheme;
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      borderRadius: BorderRadius.circular(8),
      color: accentColor ?? colorScheme.surface,
      opacity: accentColor != null ? 0.3 : 0.05,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  void _editDetails() async {
    final titleController = TextEditingController(text: _currentBook.title);
    final authorController = TextEditingController(text: _currentBook.author);
    final descriptionController = TextEditingController(
      text: _currentBook.description,
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Project Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: authorController,
              decoration: const InputDecoration(labelText: 'Author'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final updatedBook = _currentBook.copyWith(
                title: titleController.text,
                author: authorController.text,
                description: descriptionController.text,
              );
              await DatabaseService.updateBook(updatedBook);
              await _reloadBook();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editTags() async {
    final updated = await showDialog<Book>(
      context: context,
      builder: (context) => TagEditorDialog(book: _currentBook),
    );
    if (updated != null) {
      await _reloadBook();
    }
  }

  Future<void> _addChapter() async {
    final newChapter = Chapter(
      id: const Uuid().v4(),
      title: 'Chapter ${_currentBook.chapters.length + 1}',
      content: '',
      order: _currentBook.chapters.length + 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final updatedBook = _currentBook.copyWith(
      chapters: [..._currentBook.chapters, newChapter],
    );

    await DatabaseService.updateBook(updatedBook);
    await _reloadBook();
    _openChapter(newChapter);
  }

  void _openChapter(Chapter chapter) async {
    final reloadedChapter = _currentBook.chapters.firstWhere(
      (c) => c.id == chapter.id,
      orElse: () => chapter,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _currentBook.documentType == DocumentType.scp
            ? SCPEditorScreen(book: _currentBook, chapter: reloadedChapter)
            : EditorScreen(book: _currentBook, chapter: reloadedChapter),
      ),
    );
    await _reloadBook();
  }

  void _showCoverOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 24),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Change Cover'),
              onTap: () {
                Navigator.pop(context);
                _changeCover();
              },
            ),
            if (_currentBook.coverUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Remove Cover',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeCover();
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeCover() async {
    final pickedFile = await ImageService.pickImage();
    if (pickedFile != null) {
      // If we have an old cover, we could delete it, but saveImage uses ID as name, so it overwrites anyway.
      final savedPath = await ImageService.saveImage(
        pickedFile,
        _currentBook.id,
      );

      if (savedPath != null) {
        final updatedBook = _currentBook.copyWith(coverUrl: savedPath);
        await DatabaseService.updateBook(updatedBook);
        await _reloadBook();
      }
    }
  }

  Future<void> _removeCover() async {
    if (_currentBook.coverUrl != null) {
      await ImageService.deleteImage(_currentBook.coverUrl!);
      final updatedBook = _currentBook.copyWith(clearCover: true);
      await DatabaseService.updateBook(updatedBook);
      await _reloadBook();
      setState(() {
        _tintColor = null; // Reset tint when cover is removed
      });
    }
  }
}
