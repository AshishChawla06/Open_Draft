import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/monster.dart';
import '../models/encounter.dart';
import '../services/dnd_service.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_background.dart';
import '../../widgets/cascade_image.dart';
import '../widgets/add_monster_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'monster_data_sources_screen.dart';
import '../../widgets/monster_image_saver_io.dart'
    if (dart.library.html) '../../widgets/monster_image_saver_web.dart';

class EncounterEditorScreen extends StatefulWidget {
  final Encounter encounter;
  final Function(Encounter) onSave;
  final VoidCallback? onDelete;

  const EncounterEditorScreen({
    super.key,
    required this.encounter,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<EncounterEditorScreen> createState() => _EncounterEditorScreenState();
}

class _EncounterEditorScreenState extends State<EncounterEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late List<EncounterMonster> _monsters;
  String _environment = 'Dungeon';
  String _difficulty = 'Unknown';

  final List<String> _environments = [
    'Dungeon',
    'Forest',
    'City',
    'Cavern',
    'Coastal',
    'Desert',
    'Mountain',
    'Swamp',
    'Underdark',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.encounter.title);
    _notesController = TextEditingController(text: widget.encounter.notes);
    _monsters = List.from(widget.encounter.monsters);
    _environment = widget.encounter.environment.isNotEmpty
        ? widget.encounter.environment
        : 'Dungeon';
    _difficulty = widget.encounter.difficultyRating;
  }

  void _addMonster() async {
    final Monster? selected = await showDialog<Monster>(
      context: context,
      builder: (context) => const AddMonsterDialog(),
    );

    if (selected != null) {
      setState(() {
        _monsters.add(EncounterMonster.fromMonster(selected));
        _updateDifficulty();
      });
    }
  }

  void _removeMonster(int index) {
    setState(() {
      _monsters.removeAt(index);
      _updateDifficulty();
    });
  }

  void _incrementMonsterQuantity(int index) {
    // Add another instance of the same monster
    if (index < 0 || index >= _monsters.length) return;

    final original = _monsters[index];
    if (original.monsterSnapshot == null) return;

    final newMonster = EncounterMonster.fromMonster(original.monsterSnapshot!);

    setState(() {
      _monsters.insert(index + 1, newMonster);
      _updateDifficulty();
    });
  }

  void _decrementMonsterQuantity(int index) {
    // Remove this instance (same as delete if quantity would be 0)
    _removeMonster(index);
  }

  void _updateDifficulty() {
    if (_monsters.isEmpty) {
      setState(() => _difficulty = 'Trivial');
      return;
    }

    // Calculate total XP from all monsters
    int totalXp = 0;
    for (final monster in _monsters) {
      final cr = monster.monsterSnapshot?.challengeRating ?? 0.0;
      totalXp += _getXpForCr(cr);
    }

    // Apply encounter multiplier based on number of monsters
    final multiplier = _getEncounterMultiplier(_monsters.length);
    final adjustedXp = (totalXp * multiplier).round();

    // For now, assume party of 4 level 5 characters (can be made configurable later)
    const partySize = 4;
    const partyLevel = 5;

    // Calculate difficulty using DnDService
    final calculatedDifficulty = DnDService.calculateDifficulty(
      adjustedXp,
      partySize,
      partyLevel,
    );

    setState(() => _difficulty = calculatedDifficulty);
  }

  int _getXpForCr(double cr) {
    // Official D&D 5e CR to XP conversion
    final xpMap = {
      0.0: 10,
      0.125: 25,
      0.25: 50,
      0.5: 100,
      1.0: 200,
      2.0: 450,
      3.0: 700,
      4.0: 1100,
      5.0: 1800,
      6.0: 2300,
      7.0: 2900,
      8.0: 3900,
      9.0: 5000,
      10.0: 5900,
      11.0: 7200,
      12.0: 8400,
      13.0: 10000,
      14.0: 11500,
      15.0: 13000,
      16.0: 15000,
      17.0: 18000,
      18.0: 20000,
      19.0: 22000,
      20.0: 25000,
      21.0: 33000,
      22.0: 41000,
      23.0: 50000,
      24.0: 62000,
      25.0: 75000,
      26.0: 90000,
      27.0: 105000,
      28.0: 120000,
      29.0: 135000,
      30.0: 155000,
    };
    return xpMap[cr] ?? 0;
  }

  double _getEncounterMultiplier(int monsterCount) {
    // D&D 5e encounter multipliers
    if (monsterCount == 1) return 1.0;
    if (monsterCount == 2) return 1.5;
    if (monsterCount <= 6) return 2.0;
    if (monsterCount <= 10) return 2.5;
    if (monsterCount <= 14) return 3.0;
    return 4.0;
  }

  void _save() {
    final updated = widget.encounter.copyWith(
      title: _titleController.text,
      notes: _notesController.text,
      environment: _environment,
      difficultyRating: _difficulty, // Auto-calculated based on XP
      monsters: _monsters,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  Future<void> _generateMonsterImage(Monster monster) async {
    final promptText =
        'Create a fantasy art image of ${monster.name}, a ${monster.size} ${monster.type} creature from Dungeons and Dragons. ${monster.description ?? ""}'
            .trim();

    // Copy to clipboard
    await Clipboard.setData(ClipboardData(text: promptText));

    // Show snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prompt copied! Press Ctrl+V to paste in Gemini.'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    // Launch Gemini
    final prompt = Uri.encodeComponent(promptText);
    final url = Uri.parse('https://gemini.google.com/app?q=$prompt');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _uploadMonsterImage(int monsterIndex) async {
    // Image upload is not supported on web
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Image upload is not available on web. Use the AI generation feature instead.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final ImagePicker picker = ImagePicker();

    try {
      // Pick image from gallery
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      // Save image to app directory
      final savedPath = await saveMonsterImage(image.path, image.name);

      if (savedPath == null) {
        throw Exception('Failed to save image');
      }

      // Update monster with new image URL
      if (mounted) {
        setState(() {
          final monster = _monsters[monsterIndex];
          //Update the monster snapshot with new image path
          if (monster.monsterSnapshot != null) {
            final updatedMonster = monster.monsterSnapshot!.copyWith(
              imgUrl: savedPath,
              imageSource: 'Custom Upload',
            );
            // Create new EncounterMonster with updated snapshot
            _monsters[monsterIndex] = EncounterMonster(
              instanceId: monster.instanceId,
              monsterSlug: monster.monsterSlug,
              monsterSnapshot: updatedMonster,
              customName: monster.customName,
              currentHp: monster.currentHp,
              maxHp: monster.maxHp,
              initiative: monster.initiative,
              xp: monster.xp,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Encounter"),
        content: Text(
          "Are you sure you want to delete '${_titleController.text}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (widget.onDelete != null) {
        widget.onDelete!();
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("Edit Encounter"),
          actions: [
            // Monster Data Sources
            IconButton(
              icon: const Icon(Icons.cloud_sync),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MonsterDataSourcesScreen(),
                  ),
                );
              },
              tooltip: "Monster Data Sources",
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _delete,
              tooltip: "Delete Encounter",
            ),
            TextButton(
              onPressed: _save,
              child: const Text(
                "Save",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Card
              GlassContainer(
                borderRadius: BorderRadius.circular(16),
                opacity: 0.1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        style: Theme.of(context).textTheme.headlineSmall,
                        decoration: const InputDecoration(
                          labelText: 'Encounter Name',
                          border: InputBorder.none,
                        ),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _environments.contains(_environment)
                                  ? _environment
                                  : _environments.first,
                              dropdownColor: Theme.of(
                                context,
                              ).colorScheme.surface,
                              decoration: const InputDecoration(
                                labelText: 'Environment',
                              ),
                              items: _environments
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _environment = val!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Difficulty: $_difficulty',
                                  style: TextStyle(
                                    color: _getDifficultyColor(_difficulty),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Slider(
                                  value: _getDifficultyIndex(
                                    _difficulty,
                                  ).toDouble(),
                                  min: 0,
                                  max: 3,
                                  divisions: 3,
                                  activeColor: _getDifficultyColor(_difficulty),
                                  onChanged: (val) {
                                    setState(() {
                                      _difficulty = _getDifficultyFromIndex(
                                        val.toInt(),
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Monsters Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Monsters",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _addMonster,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Monster"),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Monster List
              if (_monsters.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text("No monsters added yet.")),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _monsters.length,
                  itemBuilder: (context, index) {
                    final m = _monsters[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassContainer(
                        borderRadius: BorderRadius.circular(12),
                        opacity: 0.1,
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CascadeImage(
                              imageUrls:
                                  m.monsterSnapshot?.imageCandidates ?? [],
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            m.customName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'HP: ${m.maxHp} | AC: ${m.monsterSnapshot?.armorClass ?? "?"} | CR: ${m.monsterSnapshot?.challengeRating ?? "?"}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Quantity controls
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 16),
                                      onPressed: () =>
                                          _decrementMonsterQuantity(index),
                                      tooltip: 'Remove one',
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    Text(
                                      '1', // Will be dynamic later
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 16),
                                      onPressed: () =>
                                          _incrementMonsterQuantity(index),
                                      tooltip: 'Add another',
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Actions menu
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'generate':
                                      if (m.monsterSnapshot != null) {
                                        _generateMonsterImage(
                                          m.monsterSnapshot!,
                                        );
                                      }
                                      break;
                                    case 'upload':
                                      _uploadMonsterImage(index);
                                      break;
                                    case 'delete':
                                      _removeMonster(index);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'generate',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text('Generate Image with AI'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'upload',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.upload_file,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text('Upload Image'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text('Remove'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              _buildMonsterSlideshow(),
              const SizedBox(height: 24),

              // GM Notes
              Text(
                "GM Notes",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GlassContainer(
                borderRadius: BorderRadius.circular(16),
                opacity: 0.1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _notesController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: "Enter trap details, tactics, or loot here...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String rating) {
    switch (rating) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      case 'Deadly':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  int _getDifficultyIndex(String rating) {
    switch (rating) {
      case 'Easy':
        return 0;
      case 'Medium':
        return 1;
      case 'Hard':
        return 2;
      case 'Deadly':
        return 3;
      default:
        return 0;
    }
  }

  String _getDifficultyFromIndex(int index) {
    const ratings = ['Easy', 'Medium', 'Hard', 'Deadly'];
    if (index >= 0 && index < ratings.length) {
      return ratings[index];
    }
    return 'Easy';
  }

  Widget _buildMonsterSlideshow() {
    final monstersWithImages = _monsters
        .where((m) => m.monsterSnapshot?.imgUrl != null)
        .toList();
    if (monstersWithImages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: monstersWithImages.length,
            itemBuilder: (context, index) {
              final m = monstersWithImages[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CascadeImage(
                          imageUrls: m.monsterSnapshot!.imageCandidates,
                          width: 140,
                          fit: BoxFit.cover,
                          onGenerateImage: () =>
                              _generateMonsterImage(m.monsterSnapshot!),
                          onUploadImage: () => _uploadMonsterImage(
                            monstersWithImages.indexOf(m),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.customName,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
