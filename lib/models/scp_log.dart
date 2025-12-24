class SCPLog {
  final String id;
  final String chapterId;
  final String type; // 'interview', 'incident', 'test', 'observation'
  final List<LogEntry> entries;
  final DateTime createdAt;
  final String? title;

  SCPLog({
    required this.id,
    required this.chapterId,
    required this.type,
    required this.entries,
    required this.createdAt,
    this.title,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chapterId': chapterId,
      'type': type,
      'entries': entries.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'title': title,
    };
  }

  factory SCPLog.fromJson(Map<String, dynamic> json) {
    return SCPLog(
      id: json['id'] as String,
      chapterId: json['chapterId'] as String,
      type: json['type'] as String,
      entries: (json['entries'] as List<dynamic>)
          .map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      title: json['title'] as String?,
    );
  }

  SCPLog copyWith({
    String? id,
    String? chapterId,
    String? type,
    List<LogEntry>? entries,
    DateTime? createdAt,
    String? title,
  }) {
    return SCPLog(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      type: type ?? this.type,
      entries: entries ?? this.entries,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
    );
  }
}

class LogEntry {
  final String id;
  final String speaker; // "Dr. Smith", "D-9341", "SCP-173"
  final String content;
  final DateTime? timestamp;
  final String? note; // Parentheticals or actions [Data Expunged]
  final String? imageUrl;

  LogEntry({
    required this.id,
    required this.speaker,
    required this.content,
    this.timestamp,
    this.note,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'speaker': speaker,
      'content': content,
      'timestamp': timestamp?.toIso8601String(),
      'note': note,
      'imageUrl': imageUrl,
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'] as String,
      speaker: json['speaker'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      note: json['note'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  LogEntry copyWith({
    String? id,
    String? speaker,
    String? content,
    DateTime? timestamp,
    String? note,
    String? imageUrl,
  }) {
    return LogEntry(
      id: id ?? this.id,
      speaker: speaker ?? this.speaker,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
