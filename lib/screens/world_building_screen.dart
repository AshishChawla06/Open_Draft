import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/character.dart';
import '../widgets/glass_container.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

/// Screen to manage characters and locations for a book
class WorldBuildingScreen extends StatefulWidget {
  final Book book;

  const WorldBuildingScreen({super.key, required this.book});

  @override
  State<WorldBuildingScreen> createState() => _WorldBuildingScreenState();
}

class _WorldBuildingScreenState extends State<WorldBuildingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Character> _characters = [];
  List<Location> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final chars = await DatabaseService.getCharacters(widget.book.id);
    final locs = await DatabaseService.getLocations(widget.book.id);
    setState(() {
      _characters = chars;
      _locations = locs;
      _isLoading = false;
    });
  }

  Future<void> _addCharacter() async {
    final character = Character(
      id: const Uuid().v4(),
      bookId: widget.book.id,
      name: 'New Character',
      role: 'Protagonist',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await DatabaseService.saveCharacter(character);
    await _loadData();
  }

  Future<void> _addLocation() async {
    final location = Location(
      id: const Uuid().v4(),
      bookId: widget.book.id,
      name: 'New Location',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await DatabaseService.saveLocation(location);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('World Building - ${widget.book.title}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Characters'),
            Tab(icon: Icon(Icons.place), text: 'Locations'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildCharactersTab(), _buildLocationsTab()],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _addCharacter();
          } else {
            _addLocation();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCharactersTab() {
    if (_characters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No characters yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first character',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _characters.length,
      itemBuilder: (context, index) {
        final character = _characters[index];
        return GlassContainer(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(0),
          child: ListTile(
            onTap: () => _editCharacter(character),
            leading: CircleAvatar(
              child: Text(
                character.name.isEmpty ? '?' : character.name[0].toUpperCase(),
              ),
            ),
            title: Text(character.name),
            subtitle: Text(character.role ?? 'No role assigned'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Character'),
                    content: Text(
                      'Are you sure you want to delete ${character.name}?',
                    ),
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
                  await DatabaseService.deleteCharacter(character.id);
                  await _loadData();
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _editCharacter(Character character) async {
    final nameController = TextEditingController(text: character.name);
    final roleController = TextEditingController(text: character.role);
    final descController = TextEditingController(text: character.description);

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Character'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(
                  labelText: 'Role (e.g. Protagonist)',
                ),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newChar = character.copyWith(
                name: nameController.text,
                role: roleController.text,
                description: descController.text,
                updatedAt: DateTime.now(),
              );
              await DatabaseService.saveCharacter(newChar);
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated == true) {
      await _loadData();
    }
  }

  Widget _buildLocationsTab() {
    if (_locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.place_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No locations yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first location',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _locations.length,
      itemBuilder: (context, index) {
        final location = _locations[index];
        return GlassContainer(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(0),
          child: ListTile(
            onTap: () => _editLocation(location),
            leading: const Icon(Icons.place),
            title: Text(location.name),
            subtitle: Text(location.description ?? 'No description'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Location'),
                    content: Text(
                      'Are you sure you want to delete ${location.name}?',
                    ),
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
                  await DatabaseService.deleteLocation(location.id);
                  await _loadData();
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _editLocation(Location location) async {
    final nameController = TextEditingController(text: location.name);
    final descController = TextEditingController(text: location.description);

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Location'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newLoc = location.copyWith(
                name: nameController.text,
                description: descController.text,
                updatedAt: DateTime.now(),
              );
              await DatabaseService.saveLocation(newLoc);
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated == true) {
      await _loadData();
    }
  }
}
