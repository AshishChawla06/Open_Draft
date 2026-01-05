import 'package:uuid/uuid.dart';
import '../../models/redaction.dart';

class Npc {
  final String id;
  final String adventureId; // Links to Book
  final String name;
  final String race;
  final String characterClass; // To avoid conflict with Dart keyword 'class'
  final String alignment;
  final String role; // e.g., 'Quest Giver', 'Villain', 'Ally'

  // Personality
  final List<String> traits;
  final List<String> ideals;
  final List<String> bonds;
  final List<String> flaws;
  final String backstory;

  // Visual & Voice
  final String appearance;
  final String voiceMannerisms;

  // Stats (optional)
  final bool includeStatblock;
  final int? armorClass;
  final int? hitPoints;
  final Map<String, int>? abilityScores; // STR, DEX, CON, INT, WIS, CHA

  // GM Secrets
  final List<Redaction>? redactions;

  final DateTime createdAt;
  final DateTime updatedAt;

  Npc({
    required this.id,
    required this.adventureId,
    required this.name,
    this.race = '',
    this.characterClass = '',
    this.alignment = '',
    this.role = '',
    this.traits = const [],
    this.ideals = const [],
    this.bonds = const [],
    this.flaws = const [],
    this.backstory = '',
    this.appearance = '',
    this.voiceMannerisms = '',
    this.includeStatblock = false,
    this.armorClass,
    this.hitPoints,
    this.abilityScores,
    this.redactions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Npc copyWith({
    String? name,
    String? race,
    String? characterClass,
    String? alignment,
    String? role,
    List<String>? traits,
    List<String>? ideals,
    List<String>? bonds,
    List<String>? flaws,
    String? backstory,
    String? appearance,
    String? voiceMannerisms,
    bool? includeStatblock,
    int? armorClass,
    int? hitPoints,
    Map<String, int>? abilityScores,
    List<Redaction>? redactions,
  }) {
    return Npc(
      id: id,
      adventureId: adventureId,
      name: name ?? this.name,
      race: race ?? this.race,
      characterClass: characterClass ?? this.characterClass,
      alignment: alignment ?? this.alignment,
      role: role ?? this.role,
      traits: traits ?? this.traits,
      ideals: ideals ?? this.ideals,
      bonds: bonds ?? this.bonds,
      flaws: flaws ?? this.flaws,
      backstory: backstory ?? this.backstory,
      appearance: appearance ?? this.appearance,
      voiceMannerisms: voiceMannerisms ?? this.voiceMannerisms,
      includeStatblock: includeStatblock ?? this.includeStatblock,
      armorClass: armorClass ?? this.armorClass,
      hitPoints: hitPoints ?? this.hitPoints,
      abilityScores: abilityScores ?? this.abilityScores,
      redactions: redactions ?? this.redactions,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adventureId': adventureId,
      'name': name,
      'race': race,
      'characterClass': characterClass,
      'alignment': alignment,
      'role': role,
      'traits': traits,
      'ideals': ideals,
      'bonds': bonds,
      'flaws': flaws,
      'backstory': backstory,
      'appearance': appearance,
      'voiceMannerisms': voiceMannerisms,
      'includeStatblock': includeStatblock,
      'armorClass': armorClass,
      'hitPoints': hitPoints,
      'abilityScores': abilityScores,
      'redactions': redactions?.map((r) => r.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Npc.fromJson(Map<String, dynamic> json) {
    return Npc(
      id: json['id'] ?? '',
      adventureId: json['adventureId'] ?? '',
      name: json['name'] ?? 'Unnamed NPC',
      race: json['race'] ?? '',
      characterClass: json['characterClass'] ?? '',
      alignment: json['alignment'] ?? '',
      role: json['role'] ?? '',
      traits: List<String>.from(json['traits'] ?? []),
      ideals: List<String>.from(json['ideals'] ?? []),
      bonds: List<String>.from(json['bonds'] ?? []),
      flaws: List<String>.from(json['flaws'] ?? []),
      backstory: json['backstory'] ?? '',
      appearance: json['appearance'] ?? '',
      voiceMannerisms: json['voiceMannerisms'] ?? '',
      includeStatblock: json['includeStatblock'] ?? false,
      armorClass: json['armorClass'],
      hitPoints: json['hitPoints'],
      abilityScores: json['abilityScores'] != null
          ? Map<String, int>.from(json['abilityScores'])
          : null,
      redactions: json['redactions'] != null
          ? (json['redactions'] as List)
                .map((r) => Redaction.fromJson(r))
                .toList()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  factory Npc.empty(String adventureId) {
    return Npc(
      id: const Uuid().v4(),
      adventureId: adventureId,
      name: 'New NPC',
    );
  }
}
