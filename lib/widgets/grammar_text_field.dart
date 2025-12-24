import 'package:flutter/material.dart';
import '../services/grammar_service.dart';

class GrammarTextField extends StatefulWidget {
  final TextEditingController controller;
  final List<GrammarIssue> grammarIssues;
  final TextStyle? style;
  final InputDecoration? decoration;
  final int? maxLines;
  final bool expands;
  final TextAlignVertical? textAlignVertical;
  final Function(GrammarIssue)? onIssueTapped;

  const GrammarTextField({
    super.key,
    required this.controller,
    required this.grammarIssues,
    this.style,
    this.decoration,
    this.maxLines,
    this.expands = false,
    this.textAlignVertical,
    this.onIssueTapped,
  });

  @override
  State<GrammarTextField> createState() => _GrammarTextFieldState();
}

class _GrammarTextFieldState extends State<GrammarTextField> {
  final GlobalKey _textFieldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TextField(
          key: _textFieldKey,
          controller: widget.controller,
          style: widget.style,
          decoration: widget.decoration,
          maxLines: widget.maxLines,
          expands: widget.expands,
          textAlignVertical: widget.textAlignVertical,
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: GrammarUnderlinePainter(
                text: widget.controller.text,
                issues: widget.grammarIssues,
                textStyle: widget.style ?? const TextStyle(),
              ),
            ),
          ),
        ),
        // Invisible gesture detector for tapping on issues
        Positioned.fill(
          child: GestureDetector(
            onTapDown: (details) {
              _handleTap(details.localPosition);
            },
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }

  void _handleTap(Offset position) {
    // Find if tap is on an issue
    for (final issue in widget.grammarIssues) {
      // This is a simplified check - in production, you'd need to calculate
      // the exact position of each character
      if (widget.onIssueTapped != null) {
        widget.onIssueTapped!(issue);
        break;
      }
    }
  }
}

class GrammarUnderlinePainter extends CustomPainter {
  final String text;
  final List<GrammarIssue> issues;
  final TextStyle textStyle;

  GrammarUnderlinePainter({
    required this.text,
    required this.issues,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (issues.isEmpty) return;

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );
    textPainter.layout(maxWidth: size.width);

    for (final issue in issues) {
      if (issue.offset >= text.length) continue;

      final startOffset = issue.offset;
      final endOffset = (issue.offset + issue.length).clamp(0, text.length);

      // Get the position of the underlined text
      textPainter.getPositionForOffset(
        textPainter.getOffsetForCaret(
          TextPosition(offset: startOffset),
          Rect.zero,
        ),
      );
      textPainter.getPositionForOffset(
        textPainter.getOffsetForCaret(
          TextPosition(offset: endOffset),
          Rect.zero,
        ),
      );

      // Get the boxes for the text range
      final boxes = textPainter.getBoxesForSelection(
        TextSelection(baseOffset: startOffset, extentOffset: endOffset),
      );

      // Determine color based on issue type
      final color = _getColorForIssueType(issue.issueType);

      // Draw squiggly underline for each box
      for (final box in boxes) {
        _drawSquigglyLine(
          canvas,
          Offset(box.left, box.bottom),
          Offset(box.right, box.bottom),
          color,
        );
      }
    }
  }

  Color _getColorForIssueType(String issueType) {
    switch (issueType.toLowerCase()) {
      case 'misspelling':
        return Colors.red;
      case 'grammar':
        return Colors.blue;
      case 'style':
        return Colors.blue.shade300;
      default:
        return Colors.orange;
    }
  }

  void _drawSquigglyLine(Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final amplitude = 2.0;
    final wavelength = 4.0;

    path.moveTo(start.dx, start.dy);

    double x = start.dx;
    bool up = true;

    while (x < end.dx) {
      final nextX = (x + wavelength / 2).clamp(start.dx, end.dx);
      final y = start.dy + (up ? -amplitude : amplitude);
      path.lineTo(nextX, y);
      x = nextX;
      up = !up;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(GrammarUnderlinePainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.issues != issues ||
        oldDelegate.textStyle != textStyle;
  }
}
