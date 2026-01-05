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
  late TextEditingController _sizeTypeController;
  late TextEditingController _alignmentController;

  // Stats
  late TextEditingController _acController;
  late TextEditingController _hpController;
  late TextEditingController _speedController;

  // Ability Scores
  final Map<String, int> _abilityScores = {
    'STR': 10,
    'DEX': 10,
    'CON': 10,
    'INT': 10,
    'WIS': 10,
    'CHA': 10,
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialData?['name'] ?? 'New Monster',
    );
    _sizeTypeController = TextEditingController(
      text: widget.initialData?['sizeType'] ?? 'Medium humanoid',
    );
    _alignmentController = TextEditingController(
      text: widget.initialData?['alignment'] ?? 'Unspecified',
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
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                        child: _buildTextField(
                          _sizeTypeController,
                          'Size & Type (e.g. Medium undead)',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          _alignmentController,
                          'Alignment',
                        ),
                      ),
                    ],
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

                  _buildSectionHeader('Preview (Draft)'),
                  _buildStatblockPreview(),
                ],
              ),
            ),
          ),
        ),
        _buildActionButtons(),
      ],
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
      childAspectRatio: 0.8,
      children: _abilityScores.keys.map((stat) {
        return Column(
          children: [
            Text(
              stat,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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

  Widget _buildStatblockPreview() {
    return GlassContainer(
      width: double.infinity,
      color: const Color(0xFFFBEFD5), // Parchment color
      borderRadius: BorderRadius.circular(4),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _nameController.text,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7A200D),
            ),
          ),
          Text(
            '${_sizeTypeController.text}, ${_alignmentController.text}',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const Divider(color: Color(0xFF7A200D), thickness: 2),
          _buildPreviewRow('Armor Class', _acController.text),
          _buildPreviewRow('Hit Points', _hpController.text),
          _buildPreviewRow('Speed', _speedController.text),
          const Divider(color: Color(0xFF7A200D), thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _abilityScores.keys.map((stat) {
              return Column(
                children: [
                  Text(
                    stat,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Color(0xFF7A200D),
                    ),
                  ),
                  Text(
                    '${_abilityScores[stat]} (${_getModifierString(_abilityScores[stat]!)})',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7A200D),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const Divider(color: Color(0xFF7A200D), thickness: 1),
          // Actions would go here
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Color(0xFF7A200D), fontSize: 13),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
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
                    'sizeType': _sizeTypeController.text,
                    'alignment': _alignmentController.text,
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
