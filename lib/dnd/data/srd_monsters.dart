import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/monster.dart';

/// SRD Monster Database (loads from JSON)
class SRDMonsters {
  static List<Monster> _monsters = [];
  static bool _loaded = false;

  /// Load monsters from JSON asset
  static Future<void> loadFromAssets() async {
    if (_loaded) return;

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/monsters_srd.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> monstersJson = jsonData['monsters'];

      _monsters = monstersJson.map((json) => Monster.fromJson(json)).toList();
      _loaded = true;

      print('✅ Loaded ${_monsters.length} SRD monsters from JSON');
    } catch (e) {
      print('❌ Error loading SRD monsters: $e');
      _monsters = _getFallbackMonsters(); // Use hardcoded fallback
      _loaded = true;
    }
  }

  /// Search local monsters by name (case-insensitive)
  static List<Monster> search(String query) {
    if (query.isEmpty) return _monsters;

    final lowerQuery = query.toLowerCase();
    return _monsters
        .where(
          (m) =>
              m.name.toLowerCase().contains(lowerQuery) ||
              m.type.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  /// Filter by type
  static List<Monster> filterByType(String type) {
    if (type.isEmpty) return _monsters;
    return _monsters
        .where((m) => m.type.toLowerCase() == type.toLowerCase())
        .toList();
  }

  /// Filter by CR range
  static List<Monster> filterByCR(double minCr, double maxCr) {
    return _monsters
        .where((m) => m.challengeRating >= minCr && m.challengeRating <= maxCr)
        .toList();
  }

  /// Fallback hardcoded monsters if JSON fails to load
  static List<Monster> _getFallbackMonsters() {
    return [
      Monster(
        slug: 'goblin',
        name: 'Goblin',
        size: 'Small',
        type: 'humanoid',
        subtype: 'goblinoid',
        alignment: 'neutral evil',
        armorClass: 15,
        hitPoints: 7,
        hitDice: '2d6',
        speed: {'walk': 30},
        strength: 8,
        dexterity: 14,
        constitution: 10,
        intelligence: 10,
        wisdom: 8,
        charisma: 8,
        challengeRating: 0.25,
        actions: [],
        source: 'SRD',
      ),
      Monster(
        slug: 'dragon',
        name: 'Adult Red Dragon',
        size: 'Huge',
        type: 'dragon',
        subtype: '',
        alignment: 'chaotic evil',
        armorClass: 19,
        hitPoints: 256,
        hitDice: '19d12+133',
        speed: {'walk': 40, 'fly': 80},
        strength: 27,
        dexterity: 10,
        constitution: 25,
        intelligence: 16,
        wisdom: 13,
        charisma: 21,
        challengeRating: 17.0,
        actions: [],
        source: 'SRD',
      ),
    ];
  }
}
