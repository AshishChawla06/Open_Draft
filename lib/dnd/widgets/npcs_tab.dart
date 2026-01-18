import 'package:flutter/material.dart';
import '../models/npc.dart';
import '../../models/book.dart';
import '../../services/database_service.dart';
import '../../widgets/glass_container.dart';
import 'redaction_overlay.dart';
import '../../models/redaction.dart';
import 'statblock_composer.dart';

class NpcsTab extends StatefulWidget {
  final Book book;

  const NpcsTab({super.key, required this.book});

  @override
  State<NpcsTab> createState() => _NpcsTabState();
}

class _NpcsTabState extends State<NpcsTab> {
  List<Npc> _npcs = [];
  bool _isLoading = true;

  final List<String> _races = [
    'Human',
    'Elf',
    'Dwarf',
    'Halfling',
    'Gnome',
    'Half-Orc',
    'Half-Elf',
    'Tiefling',
    'Dragonborn',
  ];
  final List<String> _classes = [
    'Barbarian',
    'Bard',
    'Cleric',
    'Druid',
    'Fighter',
    'Monk',
    'Paladin',
    'Ranger',
    'Rogue',
    'Sorcerer',
    'Warlock',
    'Wizard',
  ];
  final List<String> _roles = [
    'Quest Giver',
    'Merchant',
    'Villain',
    'Ally',
    'Neutral',
    'Messenger',
  ];
  final List<String> _sizes = [
    'Tiny',
    'Small',
    'Medium',
    'Large',
    'Huge',
    'Gargantuan',
  ];
  final List<String> _types = [
    'Humanoid',
    'Beast',
    'Undead',
    'Construct',
    'Dragon',
    'Elemental',
    'Fiend',
    'Fey',
  ];
  final List<String> _alignments = [
    'Lawful Good',
    'Neutral Good',
    'Chaotic Good',
    'Lawful Neutral',
    'True Neutral',
    'Chaotic Neutral',
    'Lawful Evil',
    'Neutral Evil',
    'Chaotic Evil',
    'Unaligned',
  ];

  @override
  void initState() {
    super.initState();
    _loadNpcs();
  }

  Future<void> _loadNpcs() async {
    setState(() => _isLoading = true);
    try {
      final npcs = await DatabaseService.getDndNpcs(widget.book.id);
      setState(() {
        _npcs = npcs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addNpc() async {
    final npc = Npc.empty(widget.book.id);
    await DatabaseService.saveDndNpc(npc);
    await _loadNpcs();
    // Find the newly created npc in our list (it will have the generated ID)
    final savedNpc = _npcs.firstWhere((n) => n.id == npc.id, orElse: () => npc);
    if (mounted) {
      _editNpc(savedNpc);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Non-Player Characters',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              FilledButton.icon(
                onPressed: _addNpc,
                icon: const Icon(Icons.person_add),
                label: const Text('Add NPC'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _npcs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _npcs.length,
                  itemBuilder: (context, index) {
                    final npc = _npcs[index];
                    return _buildNpcCard(npc);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No NPCs found in this adventure.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          TextButton(
            onPressed: _addNpc,
            child: const Text('Create a cast member'),
          ),
        ],
      ),
    );
  }

  Widget _buildNpcCard(Npc npc) {
    final isRedacted = npc.redactions != null && npc.redactions!.isNotEmpty;

    return RedactionOverlay(
      isRedacted: isRedacted,
      label: 'NPC SECRET',
      onToggle: () => _editNpc(npc), // Allow GM to edit by clicking
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.1),
            child: Text(npc.name.isNotEmpty ? npc.name[0].toUpperCase() : '?'),
          ),
          title: Text(
            npc.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${npc.race} ${npc.characterClass} • ${npc.role}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteNpc(npc),
          ),
          onTap: () => _editNpc(npc),
        ),
      ),
    );
  }

  Future<void> _deleteNpc(Npc npc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete NPC'),
        content: Text('Are you sure you want to remove ${npc.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.deleteDndNpc(npc.id);
      await _loadNpcs();
    }
  }

  Future<void> _editNpc(Npc npc) async {
    final nameController = TextEditingController(text: npc.name);
    final raceController = TextEditingController(text: npc.race);
    final classController = TextEditingController(text: npc.characterClass);
    final roleController = TextEditingController(text: npc.role);
    final backstoryController = TextEditingController(text: npc.backstory);
    bool isSecret = npc.redactions != null && npc.redactions!.isNotEmpty;
    bool includeStatblock = npc.includeStatblock;
    int? armorClass = npc.armorClass;
    int? hitPoints = npc.hitPoints;
    Map<String, int>? abilityScores = npc.abilityScores;

    final result = await showDialog<Npc>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit NPC'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _races.contains(raceController.text)
                      ? raceController.text
                      : _races[0],
                  decoration: const InputDecoration(labelText: 'Race'),
                  items: _races
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => raceController.text = val!),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _classes.contains(classController.text)
                      ? classController.text
                      : _classes[0],
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: _classes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => classController.text = val!),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _roles.contains(roleController.text)
                      ? roleController.text
                      : _roles[0],
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: _roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => roleController.text = val!),
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _sizes.contains(npc.size)
                            ? npc.size
                            : _sizes[2],
                        decoration: const InputDecoration(labelText: 'Size'),
                        items: _sizes
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => npc = npc.copyWith(size: val)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _types.contains(npc.type)
                            ? npc.type
                            : _types[0],
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: _types
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => npc = npc.copyWith(type: val)),
                      ),
                    ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  initialValue: _alignments.contains(npc.alignment)
                      ? npc.alignment
                      : _alignments[4],
                  decoration: const InputDecoration(labelText: 'Alignment'),
                  items: _alignments
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => npc = npc.copyWith(alignment: val)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            raceController.text = (_races..shuffle()).first;
                            classController.text = (_classes..shuffle()).first;
                            roleController.text = (_roles..shuffle()).first;
                            npc = npc.copyWith(
                              size: (_sizes..shuffle()).first,
                              type: (_types..shuffle()).first,
                              alignment: (_alignments..shuffle()).first,
                            );
                            abilityScores = {
                              'STR': 8 + (DateTime.now().millisecond % 10),
                              'DEX': 8 + (DateTime.now().millisecond % 10),
                              'CON': 8 + (DateTime.now().microsecond % 10),
                              'INT': 8 + (DateTime.now().millisecond % 10),
                              'WIS': 8 + (DateTime.now().microsecond % 10),
                              'CHA': 8 + (DateTime.now().millisecond % 10),
                            };
                            armorClass =
                                10 + (abilityScores!['DEX']! - 10) ~/ 2;
                            hitPoints = 10 + (abilityScores!['CON']! - 10) ~/ 2;
                          });
                        },
                        icon: const Icon(Icons.casino),
                        label: const Text("Randomize"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          bool hasName = nameController.text.isNotEmpty;
                          bool hasRace = raceController.text.isNotEmpty;

                          final List<String> errors = [];
                          if (!hasName) errors.add("Missing Name");
                          if (!hasRace) errors.add("Missing Race");

                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                errors.isEmpty
                                    ? 'Validation Success'
                                    : 'Validation Errors',
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: errors.isEmpty
                                    ? [const Text('This NPC is 5e compatible!')]
                                    : errors.map((e) => Text('• $e')).toList(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("Validate 5e"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: backstoryController,
                  decoration: const InputDecoration(labelText: 'Backstory'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final data = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => Dialog.fullscreen(
                        child: StatblockComposer(
                          initialData: {
                            'name': nameController.text,
                            'ac': int.tryParse(
                              npc.armorClass?.toString() ?? '10',
                            ),
                            'hp': int.tryParse(
                              npc.hitPoints?.toString() ?? '10',
                            ),
                            'abilityScores': npc.abilityScores,
                            'size': npc.size,
                            'type': npc.type,
                            'alignment': npc.alignment,
                            'speed': npc.speed,
                          },
                          onSave: (val) => Navigator.pop(context, val),
                        ),
                      ),
                    );
                    if (data != null) {
                      setDialogState(() {
                        nameController.text =
                            data['name'] ?? nameController.text;
                        armorClass = data['ac'];
                        hitPoints = data['hp'];
                        abilityScores = Map<String, int>.from(
                          data['abilityScores'] ?? {},
                        );
                        npc = npc.copyWith(
                          size: data['size'],
                          type: data['type'],
                          alignment: data['alignment'],
                          speed: data['speed'],
                        );
                        includeStatblock = true;
                      });
                    }
                  },
                  icon: const Icon(Icons.analytics),
                  label: const Text('Customize Statblock'),
                ),
                SwitchListTile(
                  title: const Text('Include Statblock'),
                  subtitle: const Text('Show stats in exports and views'),
                  value: includeStatblock,
                  onChanged: (val) {
                    setDialogState(() => includeStatblock = val);
                  },
                ),
                SwitchListTile(
                  title: const Text('GM Secret'),
                  subtitle: const Text('Hide this NPC from players in export'),
                  value: isSecret,
                  onChanged: (val) {
                    setDialogState(() => isSecret = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  npc.copyWith(
                    name: nameController.text,
                    race: raceController.text,
                    characterClass: classController.text,
                    role: roleController.text,
                    backstory: backstoryController.text,
                    includeStatblock: includeStatblock,
                    armorClass: armorClass,
                    hitPoints: hitPoints,
                    abilityScores: abilityScores,
                    speed: npc.speed,
                    redactions: isSecret
                        ? [
                            Redaction(
                              start: 0,
                              end: 1,
                              style: 'blur',
                              displayMode: 'overlay',
                            ),
                          ]
                        : [],
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await DatabaseService.saveDndNpc(result);
      await _loadNpcs();
    }
  }
}
