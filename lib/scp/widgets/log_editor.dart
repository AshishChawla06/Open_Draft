import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/scp_log.dart';
import '../../services/image_service.dart';

class LogEditor extends StatefulWidget {
  final SCPLog log;
  final ValueChanged<SCPLog> onUpdate;
  final VoidCallback onDelete;

  const LogEditor({
    super.key,
    required this.log,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<LogEditor> createState() => _LogEditorState();
}

class _LogEditorState extends State<LogEditor> {
  final TextEditingController _spkController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _pendingImageUrl;

  void _addEntry() {
    if (_contentController.text.isEmpty && _noteController.text.isEmpty) return;

    final newEntry = LogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      speaker: _spkController.text.isEmpty ? 'Unknown' : _spkController.text,
      content: _contentController.text,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      timestamp: DateTime.now(),
      imageUrl: _pendingImageUrl,
    );

    final updatedLog = widget.log.copyWith(
      entries: [...widget.log.entries, newEntry],
    );

    widget.onUpdate(updatedLog);
    _contentController.clear();
    _noteController.clear();
    setState(() => _pendingImageUrl = null);
    // Keep speaker for convenience in interviews
  }

  Future<void> _pickEntryImage() async {
    final image = await ImageService.pickImage();
    if (image != null) {
      final savedPath = await ImageService.saveImage(
        image,
        DateTime.now().millisecondsSinceEpoch.toString(),
        category: 'logs',
      );
      if (savedPath != null) {
        setState(() => _pendingImageUrl = savedPath);
      }
    }
  }

  void _removeEntry(int index) {
    final updatedEntries = List<LogEntry>.from(widget.log.entries);
    updatedEntries.removeAt(index);
    widget.onUpdate(widget.log.copyWith(entries: updatedEntries));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100];
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.white54 : Colors.black54;

    return Card(
      color: cardColor,
      elevation: isDark ? 0 : 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.log.type.toUpperCase(),
                  style: TextStyle(
                    color: mutedColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: mutedColor.withValues(alpha: 0.3),
                  ),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete Log',
                ),
              ],
            ),
            Divider(color: mutedColor.withValues(alpha: 0.2)),

            // Entries List
            if (widget.log.entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No entries recorded.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mutedColor.withValues(alpha: 0.5)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.log.entries.length,
                itemBuilder: (context, index) {
                  final entry = widget.log.entries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Speaker
                        SizedBox(
                          width: 80,
                          child: Text(
                            entry.speaker,
                            style: const TextStyle(
                              color: Color(0xFFFFB74D), // Amber/Gold
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.content,
                                style: TextStyle(color: textColor),
                              ),
                              if (entry.imageUrl != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: kIsWeb
                                        ? Image.network(
                                            entry.imageUrl!,
                                            fit: BoxFit.contain,
                                            height: 200,
                                          )
                                        : Image.file(
                                            File(entry.imageUrl!),
                                            fit: BoxFit.contain,
                                            height: 200,
                                          ),
                                  ),
                                ),
                              if (entry.note != null && entry.note!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '[${entry.note}]',
                                    style: TextStyle(
                                      color: mutedColor,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Delete
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 14,
                            color: mutedColor.withValues(alpha: 0.2),
                          ),
                          onPressed: () => _removeEntry(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 16),
            Divider(color: mutedColor.withValues(alpha: 0.2)),

            // Add Entry Form
            Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _spkController,
                        style: TextStyle(color: textColor, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Speaker',
                          hintStyle: TextStyle(
                            color: mutedColor.withValues(alpha: 0.5),
                          ),
                          isDense: true,
                          border: InputBorder.none,
                          fillColor: isDark
                              ? const Color(0xFF2C2C2C)
                              : Colors.white70,
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        style: TextStyle(color: textColor, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Dialogue or observation...',
                          hintStyle: TextStyle(
                            color: mutedColor.withValues(alpha: 0.5),
                          ),
                          isDense: true,
                          border: InputBorder.none,
                          fillColor: isDark
                              ? const Color(0xFF2C2C2C)
                              : Colors.white70,
                          filled: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _noteController,
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Optional note (e.g. pauses, actions)...',
                          hintStyle: TextStyle(
                            color: mutedColor.withValues(alpha: 0.4),
                          ),
                          isDense: true,
                          border: InputBorder.none,
                          fillColor: isDark
                              ? const Color(0xFF2C2C2C)
                              : Colors.white70,
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_a_photo, size: 20),
                      color: _pendingImageUrl != null
                          ? Colors.green
                          : mutedColor,
                      onPressed: _pickEntryImage,
                      tooltip: 'Add Image',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Color(0xFFFFB74D),
                      ),
                      onPressed: _addEntry,
                      tooltip: 'Add Entry',
                    ),
                  ],
                ),
                if (_pendingImageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.image, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Image attached',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => setState(() => _pendingImageUrl = null),
                          child: const Text(
                            'Remove',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _spkController.dispose();
    _contentController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
