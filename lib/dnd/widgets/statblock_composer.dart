import 'dart:math';
import 'package:flutter/material.dart';
import '../../widgets/glass_container.dart';

class StatblockComposer extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSave;

  const StatblockComposer({super.key, this.initialData, required this.onSave});

  @override
  State<StatblockComposer> createState() => _StatblockComposerState();
}

class _StatblockComposerState extends State<StatblockComposer> {
  final _formKey = GlobalKey<FormState>();

  // Basic Info
  late TextEditingController _nameController;

  // Stats
  late TextEditingController _acController;
  late TextEditingController _hpController;
  late TextEditingController _speedController;

  final Map<String, int> _abilityScores = {
    'STR': 10,
    'DEX': 10,
    'CON': 10,
    'INT': 10,
    'WIS': 10,
    'CHA': 10,
  };

  // Track which ability scores are locked (won't change on randomize)
  final Set<String> _lockedStats = {};

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

  late String _selectedSize;
  late String _selectedType;
  late String _selectedAlignment;

  // Difficulty slider (0=Easy, 1=Medium, 2=Hard, 3=Deadly)
  double _difficulty = 1.0; // Start at Medium

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialData?['name'] ?? 'New Monster',
    );
    _acController = TextEditingController(
      text: widget.initialData?['ac']?.toString() ?? '10',
    );
    _hpController = TextEditingController(
      text: widget.initialData?['hp']?.toString() ?? '10',
    );
    _speedController = TextEditingController(
      text: widget.initialData?['speed'] ?? '30 ft.',
    );

    if (widget.initialData?['abilityScores'] != null) {
      _abilityScores.addAll(
        Map<String, int>.from(widget.initialData!['abilityScores']),
      );
    }

    _selectedSize = widget.initialData?['size'] ?? 'Medium';
    _selectedType = widget.initialData?['type'] ?? 'Humanoid';
    _selectedAlignment = widget.initialData?['alignment'] ?? 'True Neutral';
  }

  void _randomizeStats() {
    setState(() {
      // Only randomize stats that are not locked
      final random = Random();
      int baseRoll() => 8 + random.nextInt(10); // 8-17 range
      final difficultyBonus = (_difficulty * 2).round(); // 0, 2, 4, 6

      if (!_lockedStats.contains('STR')) {
        _abilityScores['STR'] = baseRoll() + difficultyBonus;
      }
      if (!_lockedStats.contains('DEX')) {
        _abilityScores['DEX'] = baseRoll() + difficultyBonus;
      }
      if (!_lockedStats.contains('CON')) {
        _abilityScores['CON'] = baseRoll() + difficultyBonus;
      }
      if (!_lockedStats.contains('INT')) {
        _abilityScores['INT'] = baseRoll() + difficultyBonus;
      }
      if (!_lockedStats.contains('WIS')) {
        _abilityScores['WIS'] = baseRoll() + difficultyBonus;
      }
      if (!_lockedStats.contains('CHA')) {
        _abilityScores['CHA'] = baseRoll() + difficultyBonus;
      }

      _selectedSize = (_sizes..shuffle()).first;
      _selectedType = (_types..shuffle()).first;
      _selectedAlignment = (_alignments..shuffle()).first;

      final dexMod = (_abilityScores['DEX']! - 10) ~/ 2;
      final conMod = (_abilityScores['CON']! - 10) ~/ 2;

      _acController.text = (10 + dexMod + difficultyBonus).toString();
      _hpController.text = (10 + conMod + (difficultyBonus * 2)).toString();
    });
  }

  void _validate5e() {
    bool hasName = _nameController.text.isNotEmpty;
    bool hasAC = _acController.text.isNotEmpty;
    bool hasHP = _hpController.text.isNotEmpty;
    bool hasStats = _abilityScores.values.every((v) => v > 0);

    final List<String> errors = [];
    if (!hasName) errors.add("Missing Name");
    if (!hasAC) errors.add("Missing Armor Class");
    if (!hasHP) errors.add("Missing Hit Points");
    if (!hasStats) errors.add("Ability scores must be greater than 0");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          errors.isEmpty ? 'Validation Success' : 'Validation Errors',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: errors.isEmpty
              ? [const Text('This statblock is 5e compatible!')]
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Customize Statblock'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Basic Information'),
                    _buildTextField(_nameController, 'Name'),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _sizes.contains(_selectedSize)
                                ? _selectedSize
                                : _sizes[2],
                            decoration: const InputDecoration(
                              labelText: 'Size',
                            ),
                            items: _sizes
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedSize = val!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _types.contains(_selectedType)
                                ? _selectedType
                                : _types[0],
                            decoration: const InputDecoration(
                              labelText: 'Type',
                            ),
                            items: _types
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedType = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _alignments.contains(_selectedAlignment)
                          ? _selectedAlignment
                          : _alignments[4],
                      decoration: const InputDecoration(labelText: 'Alignment'),
                      items: _alignments
                          .map(
                            (a) => DropdownMenuItem(value: a, child: Text(a)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedAlignment = val!),
                    ),
                    const SizedBox(height: 16),

                    _buildSectionHeader('Combat Stats'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _acController,
                            'AC',
                            isNumeric: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTextField(
                            _hpController,
                            'HP',
                            isNumeric: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTextField(_speedController, 'Speed'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildSectionHeader('Ability Scores'),
                    _buildAbilityScoreGrid(),
                    const SizedBox(height: 24),

                    _buildSectionHeader('Difficulty & Level'),
                    _buildDifficultySlider(),
                    const SizedBox(height: 24),

                    _buildSectionHeader('Preview (Draft)'),
                    _buildStatblockPreview(),
                  ],
                ),
              ),
            ),
          ),
          _buildToolButtons(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildToolButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _randomizeStats,
              icon: const Icon(Icons.casino),
              label: const Text('Randomize Stats'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _validate5e,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Validate 5e'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.surface.withValues(alpha: 0.3),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildAbilityScoreGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 6,
      childAspectRatio: 0.65,
      children: _abilityScores.keys.map((stat) {
        final isLocked = _lockedStats.contains(stat);
        return Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stat,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 2),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isLocked) {
                        _lockedStats.remove(stat);
                      } else {
                        _lockedStats.add(stat);
                      }
                    });
                  },
                  child: Icon(
                    isLocked ? Icons.lock : Icons.lock_open,
                    size: 12,
                    color: isLocked
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 40,
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: isLocked
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: isLocked
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                controller: TextEditingController(
                  text: _abilityScores[stat].toString(),
                ),
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null) _abilityScores[stat] = parsed;
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getModifierString(_abilityScores[stat]!),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 11,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _getModifierString(int score) {
    final mod = (score - 10) ~/ 2;
    return mod >= 0 ? '+$mod' : '$mod';
  }

  String _getDifficultyLabel() {
    if (_difficulty <= 0.5) return 'Easy';
    if (_difficulty <= 1.5) return 'Medium';
    if (_difficulty <= 2.5) return 'Hard';
    return 'Deadly';
  }

  int _getRecommendedLevel() {
    // Calculate average ability score
    final avgScore = _abilityScores.values.reduce((a, b) => a + b) / 6;
    final ac = int.tryParse(_acController.text) ?? 10;

    // Level calculation based on stats
    if (avgScore < 10 && ac < 12) return 1;
    if (avgScore < 12 && ac < 14) return 3;
    if (avgScore < 14 && ac < 16) return 5;
    if (avgScore < 16 && ac < 18) return 8;
    if (avgScore < 18 && ac < 20) return 11;
    return 15;
  }

  Widget _buildDifficultySlider() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Difficulty: ${_getDifficultyLabel()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                'Recommended Level: ${_getRecommendedLevel()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _difficulty,
            min: 0,
            max: 3,
            divisions: 3,
            label: _getDifficultyLabel(),
            onChanged: (value) {
              setState(() => _difficulty = value);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Easy',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              Text(
                'Medium',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              Text(
                'Hard',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              Text(
                'Deadly',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatblockPreview() {
    return GlassContainer(
      width: double.infinity,
      color: Colors.black.withOpacity(0.3),
      borderRadius: BorderRadius.circular(8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _nameController.text,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
            ),
          ),
          Text(
            '$_selectedSize $_selectedType, $_selectedAlignment',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 14,
              color: Color(0xFFFFFFFF),
            ),
          ),
          const Divider(color: Colors.white24, thickness: 2, height: 24),
          _buildPreviewRow('Armor Class', _acController.text),
          _buildPreviewRow('Hit Points', _hpController.text),
          _buildPreviewRow('Speed', _speedController.text),
          const Divider(color: Colors.white24, thickness: 1, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _abilityScores.keys.map((stat) {
              return Column(
                children: [
                  Text(
                    stat,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  Text(
                    '${_abilityScores[stat]} (${_getModifierString(_abilityScores[stat]!)})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFEEEEEE),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const Divider(color: Colors.white24, thickness: 1, height: 24),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 14),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Color(0xFFEEEEEE)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onSave({
                    'name': _nameController.text,
                    'size': _selectedSize,
                    'type': _selectedType,
                    'alignment': _selectedAlignment,
                    'ac': int.tryParse(_acController.text) ?? 10,
                    'hp': int.tryParse(_hpController.text) ?? 10,
                    'speed': _speedController.text,
                    'abilityScores': _abilityScores,
                  });
                }
              },
              child: const Text('Save Statblock'),
            ),
          ),
        ],
      ),
    );
  }
}
