import 'package:flutter/material.dart';
import '../services/diff_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_background.dart';

class VisualDiffViewer extends StatefulWidget {
  final String title;
  final String oldContent;
  final String newContent;
  final String? oldLabel;
  final String? newLabel;

  const VisualDiffViewer({
    super.key,
    required this.title,
    required this.oldContent,
    required this.newContent,
    this.oldLabel,
    this.newLabel,
  });

  @override
  State<VisualDiffViewer> createState() => _VisualDiffViewerState();
}

class _VisualDiffViewerState extends State<VisualDiffViewer> {
  final DiffService _diffService = DiffService();
  late List<TextSpan> _diffSpans;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _computeDiff();
  }

  void _computeDiff() {
    final diffs = _diffService.computeDiff(
      widget.oldContent,
      widget.newContent,
    );
    setState(() {
      _diffSpans = _diffService.getDiffSpans(diffs, context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.oldLabel != null || widget.newLabel != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      if (widget.oldLabel != null)
                        _buildLegendItem(
                          widget.oldLabel!,
                          Colors.red.withOpacity(0.2),
                          Colors.red[800]!,
                        ),
                      const SizedBox(width: 16),
                      if (widget.newLabel != null)
                        _buildLegendItem(
                          widget.newLabel!,
                          Colors.green.withOpacity(0.2),
                          Colors.green[800]!,
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: RichText(
                      text: TextSpan(
                        children: _diffSpans,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: text.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
