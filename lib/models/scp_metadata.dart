import 'dart:convert';

class SCPMetadata {
  final String itemNumber; // e.g., "SCP-173"
  final String objectClass; // Safe, Euclid, Keter, etc.
  final List<String> hazards; // cognitohazard, memetic, etc.
  final int clearanceLevel; // 0-5
  final String department; // e.g., "Containment"
  final List<String> tags; // General tags
  final String status; // Draft, Review, Published
  final int? rating;
  final String? author;
  final DateTime? lastRevision;

  SCPMetadata({
    required this.itemNumber,
    required this.objectClass,
    this.hazards = const [],
    this.clearanceLevel = 2,
    this.department = '',
    this.tags = const [],
    this.status = 'Draft',
    this.rating,
    this.author,
    this.lastRevision,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemNumber': itemNumber,
      'objectClass': objectClass,
      'hazards': hazards,
      'clearanceLevel': clearanceLevel,
      'department': department,
      'tags': tags,
      'status': status,
      'rating': rating,
      'author': author,
      'lastRevision': lastRevision?.toIso8601String(),
    };
  }

  factory SCPMetadata.fromJson(Map<String, dynamic> json) {
    return SCPMetadata(
      itemNumber: json['itemNumber'] as String,
      objectClass: json['objectClass'] as String,
      hazards: (json['hazards'] as List<dynamic>?)?.cast<String>() ?? [],
      clearanceLevel: json['clearanceLevel'] as int? ?? 2,
      department: json['department'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      status: json['status'] as String? ?? 'Draft',
      rating: json['rating'] as int?,
      author: json['author'] as String?,
      lastRevision: json['lastRevision'] != null
          ? DateTime.parse(json['lastRevision'] as String)
          : null,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory SCPMetadata.fromJsonString(String jsonString) {
    return SCPMetadata.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  SCPMetadata copyWith({
    String? itemNumber,
    String? objectClass,
    List<String>? hazards,
    int? clearanceLevel,
    String? department,
    List<String>? tags,
    String? status,
    int? rating,
    String? author,
    DateTime? lastRevision,
  }) {
    return SCPMetadata(
      itemNumber: itemNumber ?? this.itemNumber,
      objectClass: objectClass ?? this.objectClass,
      hazards: hazards ?? this.hazards,
      clearanceLevel: clearanceLevel ?? this.clearanceLevel,
      department: department ?? this.department,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      author: author ?? this.author,
      lastRevision: lastRevision ?? this.lastRevision,
    );
  }
}
