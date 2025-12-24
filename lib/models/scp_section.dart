enum SCPSectionType {
  itemNumber,
  objectClass,
  specialContainmentProcedures,
  description,
  addendum,
  testLog,
  incidentReport,
  interviewTranscript,
  footnotes,
  custom;

  String get displayName {
    switch (this) {
      case SCPSectionType.itemNumber:
        return 'Item #';
      case SCPSectionType.objectClass:
        return 'Object Class';
      case SCPSectionType.specialContainmentProcedures:
        return 'Special Containment Procedures';
      case SCPSectionType.description:
        return 'Description';
      case SCPSectionType.addendum:
        return 'Addendum';
      case SCPSectionType.testLog:
        return 'Test Log';
      case SCPSectionType.incidentReport:
        return 'Incident Report';
      case SCPSectionType.interviewTranscript:
        return 'Interview Transcript';
      case SCPSectionType.footnotes:
        return 'Footnotes';
      case SCPSectionType.custom:
        return 'Custom Section';
    }
  }

  static SCPSectionType fromString(String value) {
    return SCPSectionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SCPSectionType.custom,
    );
  }
}

class SCPSection {
  final String id;
  final SCPSectionType type;
  final String title;
  final String content;
  final int order;
  final bool required;

  SCPSection({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.order,
    this.required = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'content': content,
      'order': order,
      'required': required,
    };
  }

  factory SCPSection.fromJson(Map<String, dynamic> json) {
    return SCPSection(
      id: json['id'] as String,
      type: SCPSectionType.fromString(json['type'] as String),
      title: json['title'] as String,
      content: json['content'] as String,
      order: json['order'] as int,
      required: json['required'] as bool? ?? false,
    );
  }

  SCPSection copyWith({
    String? id,
    SCPSectionType? type,
    String? title,
    String? content,
    int? order,
    bool? required,
  }) {
    return SCPSection(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      order: order ?? this.order,
      required: required ?? this.required,
    );
  }
}
