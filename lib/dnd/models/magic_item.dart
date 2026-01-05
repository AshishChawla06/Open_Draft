import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import '../../models/redaction.dart';

class MagicItem {
  final String id;
  final String adventureId;
  final String name;
  final String
  rarity; // 'Common', 'Uncommon', 'Rare', 'Very Rare', 'Legendary', 'Artifact'
  final String
  type; // 'Weapon', 'Armor', 'Potion', 'Ring', 'Wondrous Item', etc.
  final bool requiresAttunement;

  // Description
  final String lore;
  final String effects;
  final String hiddenPowers; // Cursed traits, secret abilities

  // Mechanics
  final String mechanics; // Game mechanics, bonuses, etc.

  // Secrets
  final List<Redaction>? redactions;

  final DateTime createdAt;
  final DateTime updatedAt;

  MagicItem({
    required this.id,
    required this.adventureId,
    required this.name,
    this.rarity = 'Common',
    this.type = 'Wondrous Item',
    this.requiresAttunement = false,
    this.lore = '',
    this.effects = '',
    this.hiddenPowers = '',
    this.mechanics = '',
    this.redactions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  MagicItem copyWith({
    String? name,
    String? rarity,
    String? type,
    bool? requiresAttunement,
    String? lore,
    String? effects,
    String? hiddenPowers,
    String? mechanics,
    List<Redaction>? redactions,
  }) {
    return MagicItem(
      id: id,
      adventureId: adventureId,
      name: name ?? this.name,
      rarity: rarity ?? this.rarity,
      type: type ?? this.type,
      requiresAttunement: requiresAttunement ?? this.requiresAttunement,
      lore: lore ?? this.lore,
      effects: effects ?? this.effects,
      hiddenPowers: hiddenPowers ?? this.hiddenPowers,
      mechanics: mechanics ?? this.mechanics,
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
      'rarity': rarity,
      'type': type,
      'requiresAttunement': requiresAttunement,
      'lore': lore,
      'effects': effects,
      'hiddenPowers': hiddenPowers,
      'mechanics': mechanics,
      'redactions': redactions?.map((r) => r.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MagicItem.fromJson(Map<String, dynamic> json) {
    return MagicItem(
      id: json['id'] ?? '',
      adventureId: json['adventureId'] ?? '',
      name: json['name'] ?? 'Unnamed Item',
      rarity: json['rarity'] ?? 'Common',
      type: json['type'] ?? 'Wondrous Item',
      requiresAttunement: json['requiresAttunement'] ?? false,
      lore: json['lore'] ?? '',
      effects: json['effects'] ?? '',
      hiddenPowers: json['hiddenPowers'] ?? '',
      mechanics: json['mechanics'] ?? '',
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

  factory MagicItem.empty(String adventureId) {
    return MagicItem(
      id: const Uuid().v4(),
      adventureId: adventureId,
      name: 'New Magic Item',
    );
  }

  // Helper to get rarity color
  Color getRarityColor() {
    switch (rarity.toLowerCase()) {
      case 'common':
        return const Color(0xFF9E9E9E); // Grey
      case 'uncommon':
        return const Color(0xFF4CAF50); // Green
      case 'rare':
        return const Color(0xFF2196F3); // Blue
      case 'very rare':
        return const Color(0xFF9C27B0); // Purple
      case 'legendary':
        return const Color(0xFFFF9800); // Orange
      case 'artifact':
        return const Color(0xFFFF5722); // Deep Orange/Red
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
