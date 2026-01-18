import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/location.dart';
import '../../models/book.dart';
import '../../services/database_service.dart';
import '../../widgets/glass_container.dart';
import 'redaction_overlay.dart';
import '../../models/redaction.dart';
import '../../services/image_service.dart';
import '../../widgets/image_provider_io.dart'
    if (dart.library.html) '../../widgets/image_provider_web.dart';

class LocationsTab extends StatefulWidget {
  final Book book;

  const LocationsTab({super.key, required this.book});

  @override
  State<LocationsTab> createState() => _LocationsTabState();
}

class _LocationsTabState extends State<LocationsTab> {
  List<Location> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);
    try {
      final locs = await DatabaseService.getDndLocations(widget.book.id);
      setState(() {
        _locations = locs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addLocation() async {
    final loc = Location.empty(widget.book.id);
    await DatabaseService.saveDndLocation(loc);
    await _loadLocations();
    final savedLoc = _locations.firstWhere(
      (l) => l.id == loc.id,
      orElse: () => loc,
    );
    if (mounted) {
      _editLocation(savedLoc);
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
                'Locations',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              FilledButton.icon(
                onPressed: _addLocation,
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Add Location'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _locations.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _locations.length,
                  itemBuilder: (context, index) {
                    final loc = _locations[index];
                    return _buildLocationCard(loc);
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
            Icons.map_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'The world is empty. Mark a spot on the map!',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          TextButton(
            onPressed: _addLocation,
            child: const Text('Discover something new'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Location loc) {
    final isRedacted = loc.redactions != null && loc.redactions!.isNotEmpty;

    return RedactionOverlay(
      isRedacted: isRedacted,
      label: 'LOCATION SECRET',
      onToggle: () => _editLocation(loc), // Allow GM to edit by clicking
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        child: ListTile(
          leading: Icon(
            Icons.place,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          title: Text(
            loc.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${loc.environment} • ${loc.rooms.length} Rooms'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteLocation(loc),
          ),
          onTap: () => _editLocation(loc),
        ),
      ),
    );
  }

  Future<void> _deleteLocation(Location loc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Are you sure you want to remove ${loc.name}?'),
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
      await DatabaseService.deleteDndLocation(loc.id);
      await _loadLocations();
    }
  }

  Future<void> _editLocation(Location loc) async {
    final nameController = TextEditingController(text: loc.name);
    final envController = TextEditingController(text: loc.environment);
    final regionController = TextEditingController(text: loc.region);
    final descController = TextEditingController(text: loc.description);
    final mapNotesController = TextEditingController(text: loc.mapNotes);
    List<LocationRoom> currentRooms = List.from(loc.rooms);
    bool isSecret = loc.redactions != null && loc.redactions!.isNotEmpty;
    String? currentMapUrl = loc.mapImageUrl;

    final result = await showDialog<Location>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Location'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map Preview
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () async {
                        final image = await ImageService.pickImage();
                        if (image != null) {
                          final savedPath = await ImageService.saveImage(
                            image,
                            loc.id,
                            category: 'dnd_maps',
                          );
                          if (savedPath != null) {
                            setDialogState(() => currentMapUrl = savedPath);
                          }
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(16),
                          image: currentMapUrl != null
                              ? DecorationImage(
                                  image: kIsWeb
                                      ? NetworkImage(currentMapUrl!)
                                      : getImageProvider(currentMapUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: currentMapUrl == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add Map Image',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                alignment: Alignment.bottomRight,
                                padding: const EdgeInsets.all(8),
                                child: const GlassContainer(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.edit, size: 16),
                                ),
                              ),
                      ),
                    ),
                  ),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),

                  TextField(
                    controller: envController,
                    decoration: const InputDecoration(labelText: 'Environment'),
                  ),
                  TextField(
                    controller: regionController,
                    decoration: const InputDecoration(labelText: 'Region'),
                  ),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Rooms',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...currentRooms.asMap().entries.map((entry) {
                    int idx = entry.key;
                    LocationRoom room = entry.value;
                    return ListTile(
                      title: Text(room.name),
                      subtitle: Text(
                        room.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () {
                          setDialogState(() => currentRooms.removeAt(idx));
                        },
                      ),
                      onTap: () async {
                        final editedRoom = await _editRoom(context, room);
                        if (editedRoom != null) {
                          setDialogState(() => currentRooms[idx] = editedRoom);
                        }
                      },
                    );
                  }),
                  TextButton.icon(
                    onPressed: () async {
                      final newRoom = await _editRoom(
                        context,
                        LocationRoom.empty(),
                      );
                      if (newRoom != null) {
                        setDialogState(() => currentRooms.add(newRoom));
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Room'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: mapNotesController,
                    decoration: const InputDecoration(labelText: 'Map Notes'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('GM Secret'),
                    subtitle: const Text('Hide this location from players'),
                    value: isSecret,
                    onChanged: (val) {
                      setDialogState(() => isSecret = val);
                    },
                  ),
                ],
              ),
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
                  loc.copyWith(
                    name: nameController.text,
                    environment: envController.text,
                    region: regionController.text,
                    description: descController.text,
                    rooms: currentRooms,
                    mapImageUrl: currentMapUrl,
                    mapNotes: mapNotesController.text,
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
      await DatabaseService.saveDndLocation(result);
      await _loadLocations();
    }
  }

  Future<LocationRoom?> _editRoom(
    BuildContext context,
    LocationRoom room,
  ) async {
    final nameController = TextEditingController(text: room.name);
    final descController = TextEditingController(text: room.description);
    final secretsController = TextEditingController(text: room.secrets);

    return showDialog<LocationRoom>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Room Name'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            TextField(
              controller: secretsController,
              decoration: const InputDecoration(
                labelText: 'Secrets / Hidden Details',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              LocationRoom(
                id: room.id,
                name: nameController.text,
                description: descController.text,
                secrets: secretsController.text,
                features: room.features,
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
