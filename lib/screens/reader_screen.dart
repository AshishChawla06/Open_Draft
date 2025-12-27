import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import '../models/chapter.dart';
import '../models/reader_theme.dart';
import '../models/book.dart';
import '../models/document_type.dart';
import '../models/scp_log.dart';
import '../services/database_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ReaderScreen extends StatefulWidget {
  final Book book;
  final Chapter chapter;

  const ReaderScreen({super.key, required this.book, required this.chapter});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late quill.QuillController _quillController;
  late ReaderTheme _currentTheme;
  List<SCPLog> _logs = [];
  bool _isLoadingLogs = true;

  @override
  void initState() {
    super.initState();
    // Default theme based on book type
    if (widget.book.documentType == DocumentType.scp) {
      _currentTheme = ReaderTheme.scpWiki;
    } else {
      _currentTheme = ReaderTheme.standardDark;
    }
    _initQuillController();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    if (widget.book.documentType == DocumentType.scp) {
      try {
        final logs = await DatabaseService.getLogsForChapter(widget.chapter.id);
        if (mounted) {
          setState(() {
            _logs = logs;
            _isLoadingLogs = false;
          });
        }
      } catch (e) {
        print('Error fetching logs: $e');
        if (mounted) {
          setState(() => _isLoadingLogs = false);
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingLogs = false);
      }
    }
  }

  void _initQuillController() {
    try {
      if (widget.chapter.content.isEmpty) {
        _quillController = quill.QuillController.basic();
      } else {
        if (widget.chapter.content.startsWith('{') ||
            widget.chapter.content.startsWith('[')) {
          final json = jsonDecode(widget.chapter.content);
          final ops = json is Map ? json['ops'] as List : json as List;
          final processedOps = _applyThemeToDelta(ops);
          _quillController = quill.QuillController(
            document: quill.Document.fromJson(processedOps),
            selection: const TextSelection.collapsed(offset: 0),
          );
        } else {
          _quillController = quill.QuillController(
            document: quill.Document()..insert(0, widget.chapter.content),
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
      }
      // Read only mode
      _quillController.readOnly = true;
    } catch (e) {
      print('Error init preview: $e');
      _quillController = quill.QuillController.basic();
    }
  }

  List<dynamic> _applyThemeToDelta(List<dynamic> ops) {
    final List<dynamic> processed = [];
    final isDark =
        ThemeData.estimateBrightnessForColor(_currentTheme.backgroundColor) ==
        Brightness.dark;

    for (var op in ops) {
      if (op is Map && op.containsKey('attributes')) {
        final attr = Map<String, dynamic>.from(op['attributes']);
        bool changed = false;

        if (attr.containsKey('background')) {
          final bg = (attr['background'] as String).toLowerCase();

          // Check for white blocks
          final isWhite =
              bg == '#ffffffff' ||
              bg == '#ffffff' ||
              bg == 'white' ||
              bg == 'rgb(255, 255, 255)';

          // Check for black blocks
          final isBlack =
              bg == '#ff000000' ||
              bg == '#000000' ||
              bg == 'black' ||
              bg == 'rgb(0, 0, 0)';

          if (isWhite && !isDark) {
            // In light mode, turn white redaction to black for visibility
            attr['background'] = '#FF000000';
            attr['color'] = '#FF000000';
            changed = true;
          } else if (isBlack && isDark) {
            // In dark mode, ensure black redaction is visible or matches theme redaction style
            // Actually, keep it black, but maybe the user wants it white?
            // "make its so a white block also changes the same way"
            // If they mean "inverse of what it was", then:
          }
        }

        if (changed) {
          final newOp = Map<String, dynamic>.from(op);
          newOp['attributes'] = attr;
          processed.add(newOp);
        } else {
          processed.add(op);
        }
      } else {
        processed.add(op);
      }
    }
    return processed;
  }

  @override
  void dispose() {
    _quillController.dispose();
    super.dispose();
  }

  void _changeTheme(ReaderTheme theme) {
    setState(() {
      _currentTheme = theme;
      // Re-process content for new theme
      try {
        if (widget.chapter.content.startsWith('{') ||
            widget.chapter.content.startsWith('[')) {
          final json = jsonDecode(widget.chapter.content);
          final ops = json is Map ? json['ops'] as List : json as List;
          final processedOps = _applyThemeToDelta(ops);
          _quillController.document = quill.Document.fromJson(processedOps);
        }
      } catch (e) {
        print('Error updating theme content: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkReader =
        ThemeData.estimateBrightnessForColor(_currentTheme.backgroundColor) ==
        Brightness.dark;

    // Use a fresh theme base to prevent global theme leakage
    final baseTheme = isDarkReader ? ThemeData.dark() : ThemeData.light();

    return Theme(
      data: baseTheme.copyWith(
        scaffoldBackgroundColor: _currentTheme.backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _currentTheme.textColor,
          brightness: isDarkReader ? Brightness.dark : Brightness.light,
          surface: _currentTheme.backgroundColor,
          onSurface: _currentTheme.textColor,
        ),
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: _currentTheme.textColor.withValues(alpha: 0.3),
          cursorColor: _currentTheme.textColor,
          selectionHandleColor: _currentTheme.textColor,
        ),
        textTheme: baseTheme.textTheme.apply(
          bodyColor: _currentTheme.textColor,
          displayColor: _currentTheme.textColor,
          fontFamily: _currentTheme.fontFamily,
        ),
      ),
      child: Scaffold(
        backgroundColor: _currentTheme.backgroundColor,
        appBar: AppBar(
          title: Text(widget.chapter.title),
          backgroundColor: _currentTheme.backgroundColor,
          foregroundColor: _currentTheme.textColor,
          elevation: 0,
          leading: BackButton(color: _currentTheme.textColor),
          actions: [
            PopupMenuButton<ReaderTheme>(
              icon: Icon(Icons.style, color: _currentTheme.textColor),
              tooltip: 'Change Theme',
              onSelected: _changeTheme,
              itemBuilder: (context) => ReaderTheme.allThemes.map((theme) {
                return PopupMenuItem(value: theme, child: Text(theme.name));
              }).toList(),
            ),
          ],
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 800,
            ), // Max width for readability
            padding: EdgeInsets.all(_currentTheme.contentPadding),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Display
                      Text(
                        widget.chapter.title,
                        style: TextStyle(
                          color: _currentTheme.textColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: _currentTheme.fontFamily,
                        ),
                      ),
                      if (widget.book.documentType == DocumentType.scp) ...[
                        Divider(color: _currentTheme.textColor),
                        Text(
                          'Item #: ${widget.book.scpMetadata?.itemNumber ?? "SCP-XXXX"}',
                          style: TextStyle(
                            color: _currentTheme.textColor,
                            fontWeight: FontWeight.bold,
                            fontFamily: _currentTheme.fontFamily,
                          ),
                        ),
                        if (widget.book.scpMetadata?.objectClass != null)
                          Text(
                            'Object Class: ${widget.book.scpMetadata!.objectClass}',
                            style: TextStyle(
                              color: _currentTheme.textColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: _currentTheme.fontFamily,
                            ),
                          ),
                        Divider(color: _currentTheme.textColor),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: quill.QuillEditor.basic(controller: _quillController),
                ),
                if (_isLoadingLogs)
                  const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_logs.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                  SliverToBoxAdapter(
                    child: Text(
                      'ADDENDA / LOGS',
                      style: TextStyle(
                        color: _currentTheme.textColor.withValues(alpha: 0.6),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        fontFamily: _currentTheme.fontFamily,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final log = _logs[index];
                      return _buildLogSection(log);
                    }, childCount: _logs.length),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogSection(SCPLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: _currentTheme.textColor.withValues(alpha: 0.3),
        ),
        color: _currentTheme.textColor.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getLogIcon(log.type),
                color: _currentTheme.textColor.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  log.title?.toUpperCase() ??
                      '${log.type.toUpperCase()} LOG'.toUpperCase(),
                  style: TextStyle(
                    color: _currentTheme.textColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: _currentTheme.fontFamily,
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          ...log.entries.map((entry) => _buildLogEntry(entry)),
        ],
      ),
    );
  }

  Widget _buildLogEntry(LogEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.imageUrl != null) _buildLogImage(entry.imageUrl!),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.speaker}: ',
                style: TextStyle(
                  color: _currentTheme.textColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: _currentTheme.fontFamily,
                ),
              ),
              Flexible(
                child: Text(
                  entry.content,
                  style: TextStyle(
                    color: _currentTheme.textColor,
                    fontFamily: _currentTheme.fontFamily,
                  ),
                ),
              ),
            ],
          ),
          if (entry.note != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 16),
              child: Text(
                'Note: ${entry.note}',
                style: TextStyle(
                  color: _currentTheme.textColor.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                  fontFamily: _currentTheme.fontFamily,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogImage(String path) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      constraints: const BoxConstraints(maxHeight: 300),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: _currentTheme.textColor.withValues(alpha: 0.2),
        ),
      ),
      child: kIsWeb
          ? Image.network(
              path,
              fit: BoxFit.contain,
              errorBuilder: (context, e, s) => const Icon(Icons.broken_image),
            )
          : Image.file(
              File(path),
              fit: BoxFit.contain,
              errorBuilder: (context, e, s) => const Icon(Icons.broken_image),
            ),
    );
  }

  IconData _getLogIcon(String type) {
    switch (type.toLowerCase()) {
      case 'interview':
        return Icons.record_voice_over;
      case 'incident':
        return Icons.warning_amber_rounded;
      case 'test':
        return Icons.science_rounded;
      case 'observation':
        return Icons.visibility_rounded;
      default:
        return Icons.description_rounded;
    }
  }
}
