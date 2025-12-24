import 'package:flutter/material.dart';
import '../services/database_service.dart';

class NotesSidebar extends StatefulWidget {
  final String bookId;
  final String? chapterId;
  final VoidCallback onClose;

  const NotesSidebar({
    super.key,
    required this.bookId,
    this.chapterId,
    required this.onClose,
  });

  @override
  State<NotesSidebar> createState() => _NotesSidebarState();
}

class _NotesSidebarState extends State<NotesSidebar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _projectNotesController = TextEditingController();
  final TextEditingController _chapterNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final projectNotes = await DatabaseService.getNote(
      widget.bookId,
      'project',
    );
    final chapterNotes = widget.chapterId != null
        ? await DatabaseService.getNote(widget.chapterId!, 'chapter')
        : null;

    if (mounted) {
      setState(() {
        if (projectNotes != null) _projectNotesController.text = projectNotes;
        if (chapterNotes != null) _chapterNotesController.text = chapterNotes;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _projectNotesController.dispose();
    _chapterNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
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
                  'Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                  tooltip: 'Close Notes',
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Chapter'),
              Tab(text: 'Project'),
            ],
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNoteEditor(_chapterNotesController, 'Chapter Notes...'),
                _buildNoteEditor(_projectNotesController, 'Project Notes...'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteEditor(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.3),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () async {
                  if (controller == _projectNotesController) {
                    await DatabaseService.saveNote(
                      widget.bookId,
                      'project',
                      controller.text,
                    );
                  } else if (widget.chapterId != null &&
                      controller == _chapterNotesController) {
                    await DatabaseService.saveNote(
                      widget.chapterId!,
                      'chapter',
                      controller.text,
                    );
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Note saved')));
                  }
                },
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
