import 'package:http/http.dart' as http;
import 'dart:convert';

class GrammarService {
  static const String _apiUrl = 'https://api.languagetool.org/v2/check';

  /// Check grammar and spelling using LanguageTool API
  static Future<List<GrammarIssue>> checkGrammar(String text) async {
    if (text.trim().isEmpty) return [];

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        body: {'text': text, 'language': 'en-US'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final matches = data['matches'] as List;

        return matches.map((match) {
          return GrammarIssue(
            message: match['message'] as String,
            shortMessage: match['shortMessage'] as String? ?? '',
            offset: match['offset'] as int,
            length: match['length'] as int,
            replacements:
                (match['replacements'] as List?)
                    ?.map((r) => r['value'] as String)
                    .take(3)
                    .toList() ??
                [],
            issueType: match['rule']['issueType'] as String? ?? 'grammar',
            context: match['context']['text'] as String,
          );
        }).toList();
      }
    } catch (e) {
      // Return empty list on error (offline mode)
      return [];
    }

    return [];
  }

  /// Get basic statistics about the text
  static TextStatistics getStatistics(String text) {
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final sentences = text
        .split(RegExp(r'[.!?]+\s+'))
        .where((s) => s.trim().isNotEmpty)
        .length;
    final paragraphs = text
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .length;

    return TextStatistics(
      wordCount: words.length,
      characterCount: text.length,
      characterCountNoSpaces: text.replaceAll(RegExp(r'\s+'), '').length,
      sentenceCount: sentences,
      paragraphCount: paragraphs,
      averageWordsPerSentence: sentences > 0
          ? (words.length / sentences).round()
          : 0,
    );
  }
}

class GrammarIssue {
  final String message;
  final String shortMessage;
  final int offset;
  final int length;
  final List<String> replacements;
  final String issueType;
  final String context;

  GrammarIssue({
    required this.message,
    required this.shortMessage,
    required this.offset,
    required this.length,
    required this.replacements,
    required this.issueType,
    required this.context,
  });

  String get severityColor {
    switch (issueType.toLowerCase()) {
      case 'misspelling':
        return 'red';
      case 'grammar':
        return 'orange';
      case 'style':
        return 'blue';
      default:
        return 'yellow';
    }
  }
}

class TextStatistics {
  final int wordCount;
  final int characterCount;
  final int characterCountNoSpaces;
  final int sentenceCount;
  final int paragraphCount;
  final int averageWordsPerSentence;

  TextStatistics({
    required this.wordCount,
    required this.characterCount,
    required this.characterCountNoSpaces,
    required this.sentenceCount,
    required this.paragraphCount,
    required this.averageWordsPerSentence,
  });
}
