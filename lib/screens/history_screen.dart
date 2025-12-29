import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chapter.dart';
import '../models/snapshot.dart';
import '../services/database_service.dart';
import '../widgets/visual_diff_viewer.dart';

class HistoryScreen extends StatefulWidget {
  final Chapter chapter;

  const HistoryScreen({super.key, required this.chapter});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ChapterSnapshot> _snapshots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSnapshots();
  }

  Future<void> _loadSnapshots() async {
    setState(() => _isLoading = true);
    final snapshots = await DatabaseService.getSnapshots(widget.chapter.id);
    if (mounted) {
      setState(() {
        _snapshots = snapshots;
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreSnapshot(ChapterSnapshot snapshot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Version'),
        content: const Text(
          'Are you sure you want to restore this version? Current unsaved changes might be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Update the chapter with snapshot content
      final updatedChapter = widget.chapter.copyWith(
        content: snapshot.content,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.updateChapter(updatedChapter);

      if (mounted) {
        Navigator.pop(context, updatedChapter); // Return updated chapter
      }
    }
  }

  Future<void> _deleteSnapshot(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Snapshot'),
        content: const Text('Are you sure you want to delete this snapshot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.deleteSnapshot(id);
      _loadSnapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Version History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _snapshots.isEmpty
          ? const Center(child: Text('No snapshots saved for this chapter.'))
          : ListView.builder(
              itemCount: _snapshots.length,
              itemBuilder: (context, index) {
                final snapshot = _snapshots[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(
                      DateFormat.yMMMd().add_jm().format(snapshot.timestamp),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      snapshot.description.isNotEmpty
                          ? snapshot.description
                          : 'Snapshot',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.difference_outlined),
                          tooltip: 'Compare with current',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VisualDiffViewer(
                                  title: 'Changes',
                                  oldContent: snapshot.content,
                                  newContent: widget.chapter.content,
                                  oldLabel: 'Snapshot',
                                  newLabel: 'Current',
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.restore),
                          tooltip: 'Restore',
                          onPressed: () => _restoreSnapshot(snapshot),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete',
                          onPressed: () => _deleteSnapshot(snapshot.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
