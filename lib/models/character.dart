class Character {
  final String id;
  final String bookId;
  final String name;
  final String? description;
  final String? role; // protagonist, antagonist, supporting
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Character({
    required this.id,
    required this.bookId,
    required this.name,
    this.description,
    this.role,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Character copyWith({
    String? id,
    String? bookId,
    String? name,
    String? description,
    String? role,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Character(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      name: name ?? this.name,
      description: description ?? this.description,
      role: role ?? this.role,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'name': name,
      'description': description,
      'role': role,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'],
      bookId: json['bookId'],
      name: json['name'],
      description: json['description'],
      role: json['role'],
      imageUrl: json['imageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class Location {
  final String id;
  final String bookId;
  final String name;
  final String? description;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Location({
    required this.id,
    required this.bookId,
    required this.name,
    this.description,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Location copyWith({
    String? id,
    String? bookId,
    String? name,
    String? description,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Location(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      bookId: json['bookId'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
