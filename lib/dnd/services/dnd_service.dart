import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/monster.dart';
import '../data/srd_monsters.dart';

enum MonsterImageProvider {
  open5e, // api.open5e.com (default)
  fiveETools, // 5e.tools
  fiveEBits, // 5e-bits/5e-srd-api (GitHub-based, comprehensive SRD)
}

class DnDService {
  static const String _baseUrl = 'https://api.open5e.com/monsters';
  static final Logger _logger = Logger();

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    // Load offline SRD monsters from JSON
    await SRDMonsters.loadFromAssets();
    _isInitialized = true;
  }

  // Simple in-memory cache
  static final List<Monster> _monsterCache = [];

  /// Searches for monsters - offline-first pattern
  /// Returns local SRD immediately, then enriches with API data via callback
  static Future<List<Monster>> searchMonsters(
    String query, {
    String? type,
    String? document,
    MonsterImageProvider imageProvider = MonsterImageProvider.open5e,
    Function(List<Monster>)? onApiResults,
  }) async {
    await initialize();

    // INSTANT: Return local SRD monsters immediately
    final localResults = _searchLocalMonsters(query, type: type);

    // BACKGROUND: Fetch from API and call callback when done
    _fetchApiMonsters(
      query,
      type: type,
      document: document,
      imageProvider: imageProvider,
      onResults: onApiResults,
    );

    return localResults;
  }

  /// Fetch from API in background
  static Future<void> _fetchApiMonsters(
    String query, {
    String? type,
    String? document,
    MonsterImageProvider imageProvider = MonsterImageProvider.open5e,
    Function(List<Monster>)? onResults,
  }) async {
    try {
      String queryParams = 'search=${Uri.encodeComponent(query)}&limit=50';
      if (type != null && type.isNotEmpty) {
        queryParams += '&type=${Uri.encodeComponent(type)}';
      }
      if (document != null && document.isNotEmpty) {
        queryParams += '&document__slug=${Uri.encodeComponent(document)}';
      }

      final url = Uri.parse('$_baseUrl?$queryParams');
      _logger.i('Fetching from API: $url');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              _logger.w('API timeout - using offline results');
              return http.Response('{"results":[]}', 408);
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>?;

        if (results == null || results.isEmpty) {
          _logger.w('API returned no results');
          return;
        }

        final monsters = results.map((json) {
          var monster = Monster.fromJson(json);
          if (imageProvider == MonsterImageProvider.fiveETools) {
            final toolsUrl =
                'https://raw.githubusercontent.com/TheGiddyLimit/homebrew/master/_img/monsters/MM/${monster.name}.png';
            monster = monster.copyWith(
              imgUrl: toolsUrl,
              imageSource: '5e.tools',
            );
          }
          return monster;
        }).toList();

        // Update cache
        for (var monster in monsters) {
          if (!_monsterCache.any((m) => m.slug == monster.slug)) {
            _monsterCache.add(monster);
          }
        }

        // Call callback with API results
        onResults?.call(monsters);
      }
    } catch (e) {
      _logger.e('API error: $e');
      // Silent fail - local results already shown
    }
  }

  /// Search local SRD monsters (offline)
  static List<Monster> _searchLocalMonsters(String query, {String? type}) {
    final srdMonsters = SRDMonsters.search(query);

    if (type != null && type.isNotEmpty) {
      return srdMonsters
          .where((m) => m.type.toLowerCase() == type.toLowerCase())
          .toList();
    }

    return srdMonsters;
  }

  /// Calculates XP threshold difficulty for a party.
  static String calculateDifficulty(int totalXp, int partySize, int level) {
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
    };

    final levelKey = level.clamp(1, 10);
    final levels = thresholds[levelKey]!;

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
