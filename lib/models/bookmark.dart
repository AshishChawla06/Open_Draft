class Bookmark {
  final String id;
  final String bookId;
  final String chapterId;
  final String title;
  final int position; // Character position in the chapter content
  final DateTime createdAt;
  final DateTime updatedAt;

  Bookmark({
    required this.id,
    required this.bookId,
    required this.chapterId,
    required this.title,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  Bookmark copyWith({
    String? id,
    String? bookId,
    String? chapterId,
    String? title,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      title: title ?? this.title,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'chapterId': chapterId,
      'title': title,
      'position': position,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'],
      bookId: json['bookId'],
      chapterId: json['chapterId'],
      title: json['title'],
      position: json['position'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
