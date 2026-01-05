import 'package:uuid/uuid.dart';
import '../../models/redaction.dart';

class AdventureNote {
  final String id;
  final String adventureId;
  final String title;
  final String content;
  final List<Redaction>? redactions;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdventureNote({
    required this.id,
    required this.adventureId,
    required this.title,
    this.content = '',
    this.redactions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  AdventureNote copyWith({
    String? title,
    String? content,
    List<Redaction>? redactions,
  }) {
    return AdventureNote(
      id: id,
      adventureId: adventureId,
      title: title ?? this.title,
      content: content ?? this.content,
      redactions: redactions ?? this.redactions,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adventureId': adventureId,
      'title': title,
      'content': content,
      'redactions': redactions?.map((r) => r.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AdventureNote.fromJson(Map<String, dynamic> json) {
    return AdventureNote(
      id: json['id'] ?? '',
      adventureId: json['adventureId'] ?? '',
      title: json['title'] ?? 'Untitled Note',
      content: json['content'] ?? '',
      redactions: (json['redactions'] as List?)
          ?.map((r) => Redaction.fromJson(r))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  factory AdventureNote.empty(String adventureId) {
    return AdventureNote(
      id: const Uuid().v4(),
      adventureId: adventureId,
      title: 'New Note',
    );
  }
}
