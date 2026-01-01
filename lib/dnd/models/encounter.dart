import 'package:uuid/uuid.dart';
import 'monster.dart';

class Encounter {
  final String id;
  final String chapterId; // Links to the scene/chapter
  final String title;
  final String environment; // e.g., 'Dungeon', 'Forest'
  final String notes;
  final String difficultyRating; // 'Easy', 'Medium', 'Hard', 'Deadly'
  final List<EncounterMonster> monsters;
  final DateTime updatedAt;

  Encounter({
    required this.id,
    required this.chapterId,
    required this.title,
    this.environment = '',
    this.notes = '',
    this.difficultyRating = 'Unknown',
    this.monsters = const [],
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Encounter copyWith({
    String? title,
    String? environment,
    String? notes,
    String? difficultyRating,
    List<EncounterMonster>? monsters,
  }) {
    return Encounter(
      id: id,
      chapterId: chapterId,
      title: title ?? this.title,
      environment: environment ?? this.environment,
      notes: notes ?? this.notes,
      difficultyRating: difficultyRating ?? this.difficultyRating,
      monsters: monsters ?? this.monsters,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chapterId': chapterId,
      'title': title,
      'environment': environment,
      'notes': notes,
      'difficultyRating': difficultyRating,
      'monsters': monsters.map((m) => m.toJson()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Encounter.fromJson(Map<String, dynamic> json) {
    return Encounter(
      id: json['id'],
      chapterId: json['chapterId'] ?? '',
      title: json['title'] ?? 'Untitled Encounter',
      environment: json['environment'] ?? '',
      notes: json['notes'] ?? '',
      difficultyRating: json['difficultyRating'] ?? 'Unknown',
      monsters:
          (json['monsters'] as List<dynamic>?)
              ?.map((e) => EncounterMonster.fromJson(e))
              .toList() ??
          [],
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  factory Encounter.empty(String chapterId) {
    return Encounter(
      id: const Uuid().v4(),
      chapterId: chapterId,
      title: 'New Encounter',
    );
  }

  // XP Calculation helpers can go here
  int get totalXp => monsters.fold(0, (sum, m) => sum + m.xp);
}

class EncounterMonster {
  final String instanceId;
  final String monsterSlug; // Reference to source data
  final Monster? monsterSnapshot; // Embedded data for offline cache
  final String customName;
  final int currentHp;
  final int maxHp;
  final int initiative;
  final int xp; // Cached XP value

  EncounterMonster({
    required this.instanceId,
    required this.monsterSlug,
    this.monsterSnapshot,
    required this.customName,
    required this.currentHp,
    required this.maxHp,
    this.initiative = 0,
    this.xp = 0,
  });

  factory EncounterMonster.fromMonster(Monster monster) {
    return EncounterMonster(
      instanceId: const Uuid().v4(),
      monsterSlug: monster.slug,
      monsterSnapshot: monster,
      customName: monster.name,
      currentHp: monster.hitPoints,
      maxHp: monster.hitPoints,
      // XP logic would technically normally need mapping from CR,
      // but Open5e usually provides it or we calculate it.
      // For now, placeholder 0 if not provided.
      xp: 0,
    );
  }

  EncounterMonster copyWith({
    String? customName,
    int? currentHp,
    int? maxHp,
    int? initiative,
  }) {
    return EncounterMonster(
      instanceId: instanceId,
      monsterSlug: monsterSlug,
      monsterSnapshot: monsterSnapshot,
      customName: customName ?? this.customName,
      currentHp: currentHp ?? this.currentHp,
      maxHp: maxHp ?? this.maxHp,
      initiative: initiative ?? this.initiative,
      xp: xp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instanceId': instanceId,
      'monsterSlug': monsterSlug,
      'monsterSnapshot': monsterSnapshot?.toJson(),
      'customName': customName,
      'currentHp': currentHp,
      'maxHp': maxHp,
      'initiative': initiative,
      'xp': xp,
    };
  }

  factory EncounterMonster.fromJson(Map<String, dynamic> json) {
    return EncounterMonster(
      instanceId: json['instanceId'] ?? '',
      monsterSlug: json['monsterSlug'] ?? '',
      monsterSnapshot: json['monsterSnapshot'] != null
          ? Monster.fromJson(json['monsterSnapshot'])
          : null,
      customName: json['customName'] ?? 'Unknown',
      currentHp: json['currentHp'] ?? 10,
      maxHp: json['maxHp'] ?? 10,
      initiative: json['initiative'] ?? 0,
      xp: json['xp'] ?? 0,
    );
  }
}
