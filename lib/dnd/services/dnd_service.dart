import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/monster.dart';

class DnDService {
  static final Logger _logger = Logger();
  static const String _baseUrl = 'https://api.open5e.com/monsters/';

  // Simple in-memory cache to avoid rate limiting and speed up searches
  static final List<Monster> _monsterCache = [];
  static bool _cacheInitialized = false;

  /// Searches for monsters by name.
  /// If [query] is empty, returns cache or fetches popular/low CR monsters.
  static Future<List<Monster>> searchMonsters(String query) async {
    try {
      if (query.isEmpty && _monsterCache.isNotEmpty) {
        return _monsterCache.take(50).toList();
      }

      final url = Uri.parse(
        '$_baseUrl?search=${Uri.encodeComponent(query)}&limit=50',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>;

        final monsters = results.map((json) => Monster.fromJson(json)).toList();

        // Update cache with new finds
        for (var monster in monsters) {
          if (!_monsterCache.any((m) => m.slug == monster.slug)) {
            _monsterCache.add(monster);
          }
        }

        return monsters;
      } else {
        _logger.e('Failed to load monsters: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.e('Error searching monsters: $e');
      return [];
    }
  }

  /// Calculates XP threshold difficulty for a party.
  /// Returns 'Easy', 'Medium', 'Hard', or 'Deadly'.
  static String calculateDifficulty(int totalXp, int partySize, int level) {
    // Simplified XP Logic for 5e
    // Thresholds per character level (Level: [Easy, Medium, Hard, Deadly])
    const thresholds = {
      1: [25, 50, 75, 100],
      2: [50, 100, 150, 200],
      3: [75, 150, 225, 400],
      4: [125, 250, 375, 500],
      5: [250, 500, 750, 1100],
      6: [300, 600, 900, 1400],
      7: [350, 750, 1100, 1700],
      8: [450, 900, 1400, 2100],
      9: [550, 1100, 1600, 2400],
      10: [600, 1200, 1900, 2800],
      // ... extrapolating or capping for now
    };

    final levelKey = level.clamp(1, 10);
    final levels = thresholds[levelKey]!;

    // Adjusted XP for encounter (Total XP * Multiplier based on count)
    // We'll trust the caller to pass "Adjusted XP" or just use Raw XP for now.
    // Let's use raw totals against Party Thresholds for simplicity.

    final partyEasy = levels[0] * partySize;
    final partyMedium = levels[1] * partySize;
    final partyHard = levels[2] * partySize;
    final partyDeadly = levels[3] * partySize;

    if (totalXp < partyEasy) return 'Trivial';
    if (totalXp < partyMedium) return 'Easy';
    if (totalXp < partyHard) return 'Medium';
    if (totalXp < partyDeadly) return 'Hard';
    return 'Deadly';
  }
}
