import 'package:flutter/material.dart';
import '../../models/chapter.dart';
import '../models/encounter.dart';
import '../screens/encounter_editor_screen.dart';
import 'encounter_card.dart';
import '../../services/database_service.dart';

class EncountersTab extends StatefulWidget {
  final Chapter chapter;
  final Function(Encounter) onEncounterUpdate;
  final Function(String) onEncounterDelete;

  const EncountersTab({
    super.key,
    required this.chapter,
    required this.onEncounterUpdate,
    required this.onEncounterDelete,
  });

  @override
  State<EncountersTab> createState() => _EncountersTabState();
}

class _EncountersTabState extends State<EncountersTab> {
  // In a real app, we'd parse this from the Chapter's metadata or a sub-collection.
  // For now, we'll assume the Chapter has a way to store encounters or we manage a local list.
  // Since we don't have a direct 'encounters' field on Chapter yet, we might need to
  // utilize a custom metadata field or a separate collection.
  // EXCEPT: We aren't changing the Chapter model schema right now.
  // STRATEGY: We will store encounters in the 'content' JSON under a specific key if possible,
  // OR for this phase, we'll just mock the list or use a separate temporary storage.
  //
  // WAIT: The task plan said "Encounter model (list of monsters, notes, difficulty)".
  // Realistically, to persist this, we should add 'encounters' to the Chapter model or
  // store it in the JSON content.
  // Let's modify the plan: We will store encounters as a JSON list inside the Chapter's `metadata` map (if it existed)
  // or just use a separate service call.
  //
  // Actually, for now, let's keep it simple: We'll assume the parent passes the list
  // (which it isn't yet).
  //
  // Let's implement independent storage logic here or minimal state for the UI demo.

  List<Encounter> _encounters = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEncounters();
  }

  Future<void> _loadEncounters() async {
    setState(() => _isLoading = true);
    try {
      final encounters = await DatabaseService.getDndEncounters(
        widget.chapter.id,
      );
      setState(() {
        _encounters = encounters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _createNewEncounter() async {
    final newEncounter = Encounter.empty(widget.chapter.id);
    await DatabaseService.saveDndEncounter(newEncounter);
    setState(() {
      _encounters.add(newEncounter);
    });
    widget.onEncounterUpdate(newEncounter);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EncounterEditorScreen(
            encounter: newEncounter,
            onSave: (updated) {
              setState(() {
                final idx = _encounters.indexWhere((e) => e.id == updated.id);
                if (idx != -1) {
                  _encounters[idx] = updated;
                }
              });
              widget.onEncounterUpdate(updated);
            },
            onDelete: () => _deleteEncounter(newEncounter),
          ),
        ),
      );
    }
  }

  Future<void> _deleteEncounter(Encounter encounter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Encounter"),
        content: Text("Are you sure you want to delete '${encounter.title}'?"),
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
      await DatabaseService.deleteDndEncounter(encounter.id);
      setState(() {
        _encounters.removeWhere((e) => e.id == encounter.id);
      });
      widget.onEncounterDelete(encounter.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header / Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Encounters',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              FilledButton.icon(
                onPressed: _createNewEncounter,
                icon: const Icon(Icons.add),
                label: const Text("New Encounter"),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _encounters.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.close, // Placeholder for crossed swords
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                      const Icon(
                        Icons.shield_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No encounters yet.",
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      TextButton(
                        onPressed: _createNewEncounter,
                        child: const Text("Create your first battle"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _encounters.length,
                  itemBuilder: (context, index) {
                    final encounter = _encounters[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EncounterCard(
                        encounter: encounter,
                        onDelete: () => _deleteEncounter(encounter),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EncounterEditorScreen(
                                encounter: encounter,
                                onSave: (updated) {
                                  setState(() {
                                    _encounters[index] = updated;
                                  });
                                  widget.onEncounterUpdate(updated);
                                },
                                onDelete: () => _deleteEncounter(encounter),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
