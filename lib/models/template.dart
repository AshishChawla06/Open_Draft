import 'document_type.dart';

class Template {
  final String id;
  final String name;
  final String description;
  final String content; // JSON delta or plain text
  final DocumentType type; // Novel, SCP, or both (if we want shared)

  const Template({
    required this.id,
    required this.name,
    required this.description,
    required this.content,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'content': content,
      'type': type.name,
    };
  }

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      content: json['content'],
      type: DocumentType.values.firstWhere((e) => e.name == json['type']),
    );
  }
}
