import 'package:flutter/material.dart';
import '../../models/monster.dart';
import '../models/encounter.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_background.dart';
import 'add_monster_dialog.dart';

class EncounterEditorScreen extends StatefulWidget {
  final Encounter encounter;
  final Function(Encounter) onSave;

  const EncounterEditorScreen({
    super.key,
    required this.encounter,
    required this.onSave,
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

  void _updateDifficulty() {
    // Basic placeholder logic. Real logic would use DnDService.calculateDifficulty
    // But we need total XP and party size.
    // For now, let's just sum XP.
    // We haven't implemented XP lookup yet (it's 0 in basic map).
    // Let's just set it to 'Calculating...' or manual for now.
    // Or better, let's update simple difficulty based on monster count/CR sum roughly.

    // Actually, let's just leave it manual or auto-update on save.
    // We'll update the state.
  }

  void _save() {
    final updated = widget.encounter.copyWith(
      title: _titleController.text,
      notes: _notesController.text,
      environment: _environment,
      difficultyRating: _difficulty, // TODO: Calculate real difficulty
      monsters: _monsters,
    );
    widget.onSave(updated);
    Navigator.pop(context);
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
                              value: _environments.contains(_environment)
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
                            child: TextFormField(
                              initialValue: _difficulty,
                              decoration: const InputDecoration(
                                labelText: 'Difficulty (Manual)',
                              ),
                              onChanged: (val) => _difficulty = val,
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
                          title: Text(
                            m.customName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'HP: ${m.maxHp} | AC: ${m.monsterSnapshot?.armorClass ?? "?"} | CR: ${m.monsterSnapshot?.challengeRating ?? "?"}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _removeMonster(index),
                          ),
                        ),
                      ),
                    );
                  },
                ),

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
}
