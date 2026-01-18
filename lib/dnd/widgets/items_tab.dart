import 'package:flutter/material.dart';
import '../models/magic_item.dart';
import '../../models/book.dart';
import '../../services/database_service.dart';
import '../../widgets/glass_container.dart';
import 'redaction_overlay.dart';
import '../../models/redaction.dart';

class ItemsTab extends StatefulWidget {
  final Book book;

  const ItemsTab({super.key, required this.book});

  @override
  State<ItemsTab> createState() => _ItemsTabState();
}

class _ItemsTabState extends State<ItemsTab> {
  List<MagicItem> _items = [];
  bool _isLoading = true;

  final List<String> _rarities = [
    'Common',
    'Uncommon',
    'Rare',
    'Very Rare',
    'Legendary',
    'Artifact',
  ];
  final List<String> _types = [
    'Weapon',
    'Armor',
    'Potion',
    'Ring',
    'Wondrous Item',
    'Scroll',
    'Staff',
    'Wand',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await DatabaseService.getDndMagicItems(widget.book.id);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addItem() async {
    final item = MagicItem.empty(widget.book.id);
    await DatabaseService.saveDndMagicItem(item);
    await _loadItems();
    final savedItem = _items.firstWhere(
      (i) => i.id == item.id,
      orElse: () => item,
    );
    if (mounted) {
      _editItem(savedItem);
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
                'Magic Items',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              FilledButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Add Item'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return _buildItemCard(item);
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
            Icons.shopping_bag_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No loot found. Time to stock the dungeon!',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          TextButton(
            onPressed: _addItem,
            child: const Text('Forge an artifact'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(MagicItem item) {
    final rarityColor = item.getRarityColor();
    final isRedacted = item.redactions != null && item.redactions!.isNotEmpty;

    return RedactionOverlay(
      isRedacted: isRedacted,
      label: 'ITEM SECRET',
      onToggle: () => _editItem(item), // Allow GM to edit by clicking
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        child: ListTile(
          leading: Icon(Icons.auto_awesome, color: rarityColor),
          title: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${item.rarity} • ${item.type}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteItem(item),
          ),
          onTap: () => _editItem(item),
        ),
      ),
    );
  }

  Future<void> _deleteItem(MagicItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to remove ${item.name}?'),
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
      await DatabaseService.deleteDndMagicItem(item.id);
      await _loadItems();
    }
  }

  Future<void> _editItem(MagicItem item) async {
    final nameController = TextEditingController(text: item.name);
    final rarityController = TextEditingController(text: item.rarity);
    final typeController = TextEditingController(text: item.type);
    final effectsController = TextEditingController(text: item.effects);
    bool isSecret = item.redactions != null && item.redactions!.isNotEmpty;

    final result = await showDialog<MagicItem>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Magic Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _rarities.contains(rarityController.text)
                      ? rarityController.text
                      : _rarities[0],
                  decoration: const InputDecoration(labelText: 'Rarity'),
                  items: _rarities
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => rarityController.text = val!),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _types.contains(typeController.text)
                      ? typeController.text
                      : _types[0],
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: _types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => typeController.text = val!),
                ),
                TextField(
                  controller: effectsController,
                  decoration: const InputDecoration(labelText: 'Effects'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Custom Properties",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...item.customProperties.entries.map(
                  (e) => Row(
                    children: [
                      Expanded(child: Text("${e.key}: ${e.value}")),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 16),
                        onPressed: () {
                          setDialogState(() {
                            final newProps = Map<String, String>.from(
                              item.customProperties,
                            );
                            newProps.remove(e.key);
                            item = item.copyWith(customProperties: newProps);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final keyController = TextEditingController();
                    final valController = TextEditingController();
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Add Property"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: keyController,
                              decoration: const InputDecoration(
                                labelText: "Key (e.g. Weight)",
                              ),
                            ),
                            TextField(
                              controller: valController,
                              decoration: const InputDecoration(
                                labelText: "Value (e.g. 5 lbs)",
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Add"),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && keyController.text.isNotEmpty) {
                      setDialogState(() {
                        final newProps = Map<String, String>.from(
                          item.customProperties,
                        );
                        newProps[keyController.text] = valController.text;
                        item = item.copyWith(customProperties: newProps);
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add Property"),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('GM Secret'),
                  subtitle: const Text('Hide this item from players'),
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
                  item.copyWith(
                    name: nameController.text,
                    rarity: rarityController.text,
                    type: typeController.text,
                    effects: effectsController.text,
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
      await DatabaseService.saveDndMagicItem(result);
      await _loadItems();
    }
  }
}
