import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../screens/editor_screen.dart';
import '../scp/screens/scp_editor_screen.dart';
import '../models/document_type.dart';
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
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Chapters',
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
            child: ListView.builder(
              itemCount:
                  sortedChapters.length + 1, // +1 for "New Chapter" button
              itemBuilder: (context, index) {
                if (index == sortedChapters.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final newChapter = Chapter(
                          id: const Uuid().v4(),
                          title: book.documentType == DocumentType.scp
                              ? 'New SCP Section'
                              : 'New Chapter',
                          content: jsonEncode([
                            {'insert': '\n'},
                          ]),
                          order: sortedChapters.length,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        await DatabaseService.saveChapter(book.id, newChapter);

                        if (context.mounted) {
                          if (book.documentType == DocumentType.scp) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SCPEditorScreen(
                                  book: book,
                                  chapter: newChapter,
                                ),
                              ),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditorScreen(
                                  book: book,
                                  chapter: newChapter,
                                ),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('New Chapter'),
                    ),
                  );
                }

                final chapter = sortedChapters[index];
                final isSelected = chapter.id == currentChapterId;

                return ListTile(
                  title: Text(
                    chapter.title.isEmpty ? 'Untitled Chapter' : chapter.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                  leading: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.1),
                  onTap: () {
                    if (!isSelected) {
                      // Navigate to chapter
                      // Check for unsaved changes handled by EditorScreen's PopScope?
                      // Navigator.pushReplacement won't trigger PopScope of the current route?
                      // We should ideally confirm save before switching.
                      // For now, direct navigation.
                      if (book.documentType == DocumentType.scp) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SCPEditorScreen(book: book, chapter: chapter),
                          ),
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditorScreen(book: book, chapter: chapter),
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
