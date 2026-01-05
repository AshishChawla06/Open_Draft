import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../screens/editor_screen.dart';
import '../scp/screens/scp_editor_screen.dart';
import '../models/document_type.dart';
import '../dnd/screens/adventure_editor_screen.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../services/database_service.dart';

class ChaptersSidebar extends StatelessWidget {
  final Book book;
  final String currentChapterId;
  final VoidCallback onClose;

  const ChaptersSidebar({
    super.key,
    required this.book,
    required this.currentChapterId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // Sort chapters by order
    final sortedChapters = List<Chapter>.from(book.chapters)
      ..sort((a, b) => a.order.compareTo(b.order));

    return Container(
      width: 250,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  book.documentType == DocumentType.dndAdventure
                      ? 'Acts & Scenes'
                      : 'Chapters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  tooltip: 'Close Navigation',
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) async {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final Chapter item = sortedChapters.removeAt(oldIndex);
                sortedChapters.insert(newIndex, item);

                // Update order in DB
                for (int i = 0; i < sortedChapters.length; i++) {
                  final chapter = sortedChapters[i].copyWith(order: i + 1);
                  await DatabaseService.updateChapter(chapter);
                }
              },
              itemCount: sortedChapters.length + 1,
              itemBuilder: (context, index) {
                if (index == sortedChapters.length) {
                  // "New Chapter" button - not reorderable
                  return Padding(
                    key: const ValueKey('add_button'),
                    padding: const EdgeInsets.all(16.0),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final newChapter = Chapter(
                          id: const Uuid().v4(),
                          title: book.documentType == DocumentType.scp
                              ? 'New SCP Section'
                              : book.documentType == DocumentType.dndAdventure
                              ? 'New Scene'
                              : 'New Chapter',
                          content: jsonEncode([
                            {'insert': '\n'},
                          ]),
                          order: sortedChapters.length + 1,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        await DatabaseService.saveChapter(book.id, newChapter);
                        if (context.mounted) {
                          _navigateToEditor(context, newChapter);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: Text(
                        book.documentType == DocumentType.dndAdventure
                            ? 'New Scene'
                            : 'New Chapter',
                      ),
                    ),
                  );
                }

                final chapter = sortedChapters[index];
                final isSelected = chapter.id == currentChapterId;

                return ReorderableDragStartListener(
                  key: ValueKey(chapter.id),
                  index: index,
                  child: ListTile(
                    title: Text(
                      chapter.title.isEmpty ? 'Untitled' : chapter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.drag_indicator,
                          size: 16,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    selectedTileColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    onTap: () {
                      if (!isSelected) {
                        _navigateToEditor(context, chapter);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditor(BuildContext context, Chapter chapter) {
    if (book.documentType == DocumentType.scp) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SCPEditorScreen(book: book, chapter: chapter),
        ),
      );
    } else if (book.documentType == DocumentType.dndAdventure) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AdventureEditorScreen(book: book, chapter: chapter),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EditorScreen(book: book, chapter: chapter),
        ),
      );
    }
  }
}
