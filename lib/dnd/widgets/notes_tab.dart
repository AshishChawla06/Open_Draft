import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../models/adventure_note.dart';
import '../../services/database_service.dart';
import '../../widgets/glass_container.dart';
import 'redaction_overlay.dart';
import '../../models/redaction.dart';

class NotesTab extends StatefulWidget {
  final Book book;

  const NotesTab({super.key, required this.book});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  List<AdventureNote> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notes = await DatabaseService.getDndNotes(widget.book.id);
    if (mounted) {
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text('No notes yet'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _editNote(AdventureNote.empty(widget.book.id)),
              icon: const Icon(Icons.add),
              label: const Text('Add First Note'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'ADVENTURE NOTES',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _editNote(AdventureNote.empty(widget.book.id)),
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add Note',
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              final note = _notes[index];
              return _buildNoteCard(note);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(AdventureNote note) {
    final isRedacted = note.redactions != null && note.redactions!.isNotEmpty;

    return RedactionOverlay(
      isRedacted: isRedacted,
      label: 'SECRET NOTE',
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        child: ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(
            note.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            note.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteNote(note),
          ),
          onTap: () => _editNote(note),
        ),
      ),
    );
  }

  Future<void> _editNote(AdventureNote note) async {
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.content);
    bool isSecret = note.redactions != null && note.redactions!.isNotEmpty;

    final result = await showDialog<AdventureNote>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Quick Link:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.person_pin, size: 20),
                      tooltip: 'Link NPC',
                      onPressed: () => _showLinkPicker(context, 'NPC', (name) {
                        final selection = contentController.selection;
                        final text = contentController.text;
                        final link = '[[NPC: $name]]';
                        // Handle case when no cursor position in text field
                        final start = selection.start >= 0
                            ? selection.start
                            : text.length;
                        final end = selection.end >= 0
                            ? selection.end
                            : text.length;
                        contentController.text = text.replaceRange(
                          start,
                          end,
                          link,
                        );
                        contentController.selection = TextSelection.collapsed(
                          offset: start + link.length,
                        );
                      }),
                    ),
                    IconButton(
                      icon: const Icon(Icons.landscape, size: 20),
                      tooltip: 'Link Location',
                      onPressed: () => _showLinkPicker(context, 'Location', (
                        name,
                      ) {
                        final selection = contentController.selection;
                        final text = contentController.text;
                        final link = '[[Location: $name]]';
                        // Handle case when no cursor position in text field
                        final start = selection.start >= 0
                            ? selection.start
                            : text.length;
                        final end = selection.end >= 0
                            ? selection.end
                            : text.length;
                        contentController.text = text.replaceRange(
                          start,
                          end,
                          link,
                        );
                        contentController.selection = TextSelection.collapsed(
                          offset: start + link.length,
                        );
                      }),
                    ),
                    IconButton(
                      icon: const Icon(Icons.flash_on, size: 20),
                      tooltip: 'Link Encounter',
                      onPressed: () => _showLinkPicker(context, 'Encounter', (
                        name,
                      ) {
                        final selection = contentController.selection;
                        final text = contentController.text;
                        final link = '[[Encounter: $name]]';
                        // Handle case when no cursor position in text field
                        final start = selection.start >= 0
                            ? selection.start
                            : text.length;
                        final end = selection.end >= 0
                            ? selection.end
                            : text.length;
                        contentController.text = text.replaceRange(
                          start,
                          end,
                          link,
                        );
                        contentController.selection = TextSelection.collapsed(
                          offset: start + link.length,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 12,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('GM Secret'),
                  subtitle: const Text('Hide this note from players'),
                  value: isSecret,
                  onChanged: (val) {
                    setDialogState(() => isSecret = val);
                  },
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  note.copyWith(
                    title: titleController.text,
                    content: contentController.text,
                    redactions: isSecret
                        ? [
                            Redaction(
                              start: 0,
                              end: 1,
                              style: 'blur',
                              displayMode: 'overlay',
                            ),
                          ]
                        : [],
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await DatabaseService.saveDndNote(result);
      await _loadNotes();
    }
  }

  Future<void> _deleteNote(AdventureNote note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.deleteDndNote(note.id);
      await _loadNotes();
    }
  }

  Future<void> _showLinkPicker(
    BuildContext parentContext,
    String type,
    Function(String) onPicked,
  ) async {
    List<String> items = [];
    if (type == 'NPC') {
      final npcs = await DatabaseService.getDndNpcs(widget.book.id);
      items = npcs.map((e) => e.name).toList();
    } else if (type == 'Location') {
      final locs = await DatabaseService.getDndLocations(widget.book.id);
      items = locs.map((e) => e.name).toList();
    } else {
      final encounters = await DatabaseService.getDndEncounters(widget.book.id);
      items = encounters.map((e) => e.title).toList();
    }

    if (!parentContext.mounted) return;

    if (items.isEmpty) {
      ScaffoldMessenger.of(
        parentContext,
      ).showSnackBar(SnackBar(content: Text('No ${type}s found to link.')));
      return;
    }

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text('Link $type'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(items[index]),
                onTap: () {
                  Navigator.pop(dialogContext); // Close this dialog first
                  onPicked(items[index]); // Then invoke callback
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
