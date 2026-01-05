import 'package:flutter/material.dart';
import '../../widgets/glass_container.dart';
import '../services/dnd_template_library.dart';

class TemplatePickerDialog extends StatefulWidget {
  const TemplatePickerDialog({super.key});

  @override
  State<TemplatePickerDialog> createState() => _TemplatePickerDialogState();
}

class _TemplatePickerDialogState extends State<TemplatePickerDialog> {
  String _selectedCategory = 'One-Shot';

  @override
  Widget build(BuildContext context) {
    final categories = DnDTemplateLibrary.getCategories();
    final templates = DnDTemplateLibrary.getTemplatesByCategory(
      _selectedCategory,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(24),
        opacity: 0.95,
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Adventure Templates',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((category) {
                    final isSelected = category == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = category);
                        },
                        backgroundColor: Colors.transparent,
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Templates List
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          template.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(template.description),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => Navigator.pop(context, template),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TemplateVariableDialog extends StatefulWidget {
  final AdventureTemplate template;

  const TemplateVariableDialog({super.key, required this.template});

  @override
  State<TemplateVariableDialog> createState() => _TemplateVariableDialogState();
}

class _TemplateVariableDialogState extends State<TemplateVariableDialog> {
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (var variable in widget.template.variables)
        variable: TextEditingController(text: _getDefaultValue(variable)),
    };
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getDefaultValue(String variable) {
    // Provide smart defaults
    final defaults = {
      'adventure_name': 'Untitled Adventure',
      'village_name': 'Greenhill',
      'reward_gold': '100',
      'distance': '5 miles',
      'room_count': '5',
    };
    return defaults[variable] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(24),
        opacity: 0.95,
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customize Template',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Fill in the following variables:',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),

              // Variable Fields
              SizedBox(
                height: 400,
                child: ListView.builder(
                  itemCount: widget.template.variables.length,
                  itemBuilder: (context, index) {
                    final variable = widget.template.variables[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: _controllers[variable],
                        decoration: InputDecoration(
                          labelText: _formatVariableName(variable),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final variables = {
                        for (var entry in _controllers.entries)
                          entry.key: entry.value.text,
                      };
                      Navigator.pop(context, variables);
                    },
                    child: const Text('Apply Template'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatVariableName(String variable) {
    return variable
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
