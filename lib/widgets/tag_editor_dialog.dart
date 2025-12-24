import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/database_service.dart';

/// Dialog for managing book tags
class TagEditorDialog extends StatefulWidget {
  final Book book;

  const TagEditorDialog({super.key, required this.book});

  @override
  State<TagEditorDialog> createState() => _TagEditorDialogState();
}

class _TagEditorDialogState extends State<TagEditorDialog> {
  late List<String> _tags;
  final TextEditingController _newTagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.book.tags);
  }

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _newTagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _newTagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveTags() async {
    final updatedBook = widget.book.copyWith(tags: _tags);
    await DatabaseService.updateBook(updatedBook);
    if (mounted) {
      Navigator.pop(context, updatedBook);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Tags'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add new tag
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newTagController,
                    decoration: const InputDecoration(
                      labelText: 'New Tag',
                      hintText: 'e.g., Fantasy, Romance',
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTag,
                  tooltip: 'Add Tag',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Current tags
            if (_tags.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No tags yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeTag(tag),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _saveTags, child: const Text('Save')),
      ],
    );
  }
}
