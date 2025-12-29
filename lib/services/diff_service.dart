import 'package:diff_match_patch/diff_match_patch.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class DiffService {
  final dmp = DiffMatchPatch();

  /// Computes the diff between two content strings.
  /// If the content is valid JSON (Quill Delta), it extracts the plain text first.
  List<Diff> computeDiff(String oldContent, String newContent) {
    String oldText = _getPlainText(oldContent);
    String newText = _getPlainText(newContent);

    return dmp.diff(oldText, newText);
  }

  /// Helper to extract plain text from a Quill Delta JSON string.
  /// Falls back to the original string if it's not JSON or doesn't look like a Delta.
  String _getPlainText(String content) {
    try {
      final List<dynamic> delta = jsonDecode(content);
      StringBuffer buffer = StringBuffer();

      for (var op in delta) {
        if (op is Map && op.containsKey('insert')) {
          final insert = op['insert'];
          if (insert is String) {
            buffer.write(insert);
          } else {
            // Placeholder for non-text inserts like images
            buffer.write('[Object]');
          }
        }
      }
      return buffer.toString();
    } catch (_) {
      return content;
    }
  }

  /// Converts a list of Diffs into a list of TextSpans for rich display.
  List<TextSpan> getDiffSpans(List<Diff> diffs, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return diffs.map((diff) {
      Color? backgroundColor;
      Color? textColor;
      TextDecoration? decoration;

      switch (diff.operation) {
        case DIFF_INSERT:
          backgroundColor = Colors.green.withOpacity(0.2);
          textColor = Colors.green[800];
          break;
        case DIFF_DELETE:
          backgroundColor = Colors.red.withOpacity(0.2);
          textColor = Colors.red[800];
          decoration = TextDecoration.lineThrough;
          break;
        case DIFF_EQUAL:
        default:
          backgroundColor = Colors.transparent;
          textColor = colorScheme.onSurface;
          break;
      }

      return TextSpan(
        text: diff.text,
        style: TextStyle(
          backgroundColor: backgroundColor,
          color: textColor,
          decoration: decoration,
          fontSize: 16,
        ),
      );
    }).toList();
  }
}
