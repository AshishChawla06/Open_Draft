class ChapterSnapshot {
  final String id;
  final String chapterId;
  final String content;
  final DateTime timestamp;
  final String description;

  const ChapterSnapshot({
    required this.id,
    required this.chapterId,
    required this.content,
    required this.timestamp,
    this.description = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapterId': chapterId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
    };
  }

  factory ChapterSnapshot.fromMap(Map<String, dynamic> map) {
    return ChapterSnapshot(
      id: map['id'] as String,
      chapterId: map['chapterId'] as String,
      content: map['content'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      description: map['description'] as String? ?? '',
    );
  }
}
