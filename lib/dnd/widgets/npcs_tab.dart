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
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No NPCs found in this adventure.',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
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
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.1),
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
                TextField(
                  controller: raceController,
                  decoration: const InputDecoration(labelText: 'Race'),
                ),
                TextField(
                  controller: classController,
                  decoration: const InputDecoration(labelText: 'Class'),
                ),
                TextField(
                  controller: roleController,
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
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
