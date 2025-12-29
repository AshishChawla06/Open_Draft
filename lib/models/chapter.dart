import 'scp_section.dart';
import 'redaction.dart';

class Chapter {
  final String id;
  final String title;
  final String content;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  final int? wordCountGoal;
  final String? coverUrl;
  final SCPSectionType? sectionType;
  final List<Redaction>? redactions;

  Chapter({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    this.wordCountGoal,
    this.coverUrl,
    this.sectionType,
    this.redactions,
  });

  Chapter copyWith({
    String? id,
    String? title,
    String? content,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? wordCountGoal,
    String? coverUrl,
    SCPSectionType? sectionType,
    List<Redaction>? redactions,
    bool clearCover = false,
    bool clearWordCountGoal = false,
    bool clearSectionType = false,
    bool clearRedactions = false,
  }) {
    return Chapter(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      wordCountGoal: clearWordCountGoal
          ? null
          : (wordCountGoal ?? this.wordCountGoal),
      coverUrl: clearCover ? null : (coverUrl ?? this.coverUrl),
      sectionType: clearSectionType ? null : (sectionType ?? this.sectionType),
      redactions: clearRedactions ? null : (redactions ?? this.redactions),
    );
  }

  int get wordCount {
    if (content.trim().isEmpty) return 0;
    // Simple word count for display
    return content
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
  }
}
