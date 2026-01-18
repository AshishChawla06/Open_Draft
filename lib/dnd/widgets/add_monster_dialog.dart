import 'dart:async';
import 'package:flutter/material.dart';
import '../models/monster.dart';
import '../services/dnd_service.dart';
import 'monster_detail_dialog.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/cascade_image.dart';
import '../../widgets/alphabetical_index.dart';

class AddMonsterDialog extends StatefulWidget {
  const AddMonsterDialog({super.key});

  @override
  State<AddMonsterDialog> createState() => _AddMonsterDialogState();
}

class _AddMonsterDialogState extends State<AddMonsterDialog> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Monster> _results = [];
  bool _isLoading = false;
  bool _isInitializing = false;
  MonsterImageProvider _selectedProvider = MonsterImageProvider.open5e;
  Timer? _debounce;

  String _selectedType = '';
  final String _sortBy = 'Name';
  final List<String> _types = [
    '',
    'aberration',
    'beast',
    'celestial',
    'construct',
    'dragon',
    'elemental',
    'fey',
    'fiend',
    'giant',
    'humanoid',
    'monstrosity',
    'ooze',
    'plant',
    'undead',
  ];

  // A-Z Index support
  Map<String, int> _letterIndexMap = {};
  List<String> _availableLetters = [];

  @override
  void initState() {
    super.initState();
    _isInitializing = true;
    _initialize();
  }

  Future<void> _initialize() async {
    await DnDService.initialize();
    if (mounted) {
      setState(() => _isInitializing = false);
      _searchMonsers('');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchMonsers(query);
    });
  }

  Future<void> _searchMonsers(String query) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Get instant offline results
    final monsters = await DnDService.searchMonsters(
      query,
      type: _selectedType,
      imageProvider: _selectedProvider,
      onApiResults: (apiMonsters) {
        // Merge API results when they arrive
        if (mounted) {
          setState(() {
            // Remove duplicates and add API monsters
            final existingSlugs = _results.map((m) => m.slug).toSet();
            final newMonsters = apiMonsters
                .where((m) => !existingSlugs.contains(m.slug))
                .toList();

            _results.addAll(newMonsters);
            _sortResults();
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _results = monsters;
        _sortResults();
        _isLoading = false;
      });
    }
  }

  void _sortResults() {
    switch (_sortBy) {
      case 'CR':
        _results.sort(
          (a, b) => (a.challengeRating).compareTo(b.challengeRating),
        );
        break;
      case 'HP':
        _results.sort((a, b) => b.hitPoints.compareTo(a.hitPoints));
        break;
      case 'Name':
      default:
        _results.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    _buildLetterIndexMap();
  }

  void _buildLetterIndexMap() {
    final map = <String, int>{};
    final letters = <String>{};

    for (int i = 0; i < _results.length; i++) {
      if (_results[i].name.isNotEmpty) {
        final firstLetter = _results[i].name[0].toUpperCase();
        if (!map.containsKey(firstLetter)) {
          map[firstLetter] = i;
        }
        letters.add(firstLetter);
      }
    }

    setState(() {
      _letterIndexMap = map;
      _availableLetters = letters.toList()..sort();
    });
  }

  void _scrollToLetter(String letter) {
    final index = _letterIndexMap[letter];
    if (index != null && _scrollController.hasClients) {
      // Calculate average item height dynamically
      final currentMax = _scrollController.position.maxScrollExtent;
      final estimatedItemHeight = _results.isNotEmpty
          ? currentMax / _results.length
          : 80.0;
      final double targetOffset = index * estimatedItemHeight;

      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        width: MediaQuery.of(context).size.width * 0.9,
        child: GlassContainer(
          borderRadius: BorderRadius.circular(24),
          opacity: 0.95, // High opacity for readability
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white70),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Search monsters (e.g. Goblin, Lich)...',
                          hintStyle: TextStyle(color: Colors.white30),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white24),

              // Filters & Sorting
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedType,
                          dropdownColor: Colors.grey[900],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          hint: const Text(
                            "All Types",
                            style: TextStyle(color: Colors.white54),
                          ),
                          items: _types
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t.isEmpty
                                        ? "All Types"
                                        : t[0].toUpperCase() + t.substring(1),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() => _selectedType = val!);
                            _searchMonsers(_searchController.text);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<MonsterImageProvider>(
                          isExpanded: true,
                          value: _selectedProvider,
                          dropdownColor: Colors.grey[900],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          items: MonsterImageProvider.values
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text("API: ${p.name}"),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() => _selectedProvider = val!);
                            _searchMonsers(_searchController.text);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white24),

              // Results area - SCROLLABLE
              Expanded(
                child: _isInitializing
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty && _searchController.text.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pets,
                              size: 64,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Search for monsters',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty
                    ? const Center(
                        child: Text(
                          "No monsters found.",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : Stack(
                        children: [
                          ListView.separated(
                            controller: _scrollController,
                            primary: false,
                            physics: const BouncingScrollPhysics(),
                            shrinkWrap: false,
                            padding: const EdgeInsets.only(
                              left: 8,
                              right: 40, // Space for A-Z index
                              top: 8,
                              bottom: 8,
                            ),
                            itemCount: _results.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1, color: Colors.white10),
                            itemBuilder: (context, index) {
                              final monster = _results[index];
                              return ListTile(
                                leading: monster.imgUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: CascadeImage(
                                          imageUrls: monster.imageCandidates,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.pets,
                                        color: Colors.white24,
                                      ),
                                title: Text(
                                  monster.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${monster.size} ${monster.type} • CR ${monster.challengeRating}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.info_outline,
                                        color: Colors.blueAccent,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              MonsterDetailDialog(
                                                monster: monster,
                                              ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'AC ${monster.armorClass}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'HP ${monster.hitPoints}',
                                          style: const TextStyle(
                                            color: Colors.greenAccent,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () => Navigator.pop(context, monster),
                              );
                            },
                          ),
                          // iOS-style A-Z alphabetical index
                          if (_availableLetters.isNotEmpty)
                            AlphabeticalIndex(
                              availableLetters: _availableLetters,
                              onLetterSelected: _scrollToLetter,
                            ),
                        ],
                      ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Powered by Open5e API",
                      style: TextStyle(color: Colors.white30, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
