import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/document_type.dart';
import '../models/template.dart';
import '../services/template_service.dart';

class TemplateSelectionDialog extends StatelessWidget {
  final DocumentType documentType;
  final String? currentContent;

  const TemplateSelectionDialog({
    super.key,
    required this.documentType,
    this.currentContent,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Insert Template',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (currentContent != null)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Create template from current content',
                    onPressed: () => _createCustomTemplate(context),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Template>>(
              future: TemplateService.getTemplates(documentType),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final templates = snapshot.data ?? [];
                if (templates.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text("No templates available.")),
                  );
                }
                return Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: templates.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      return ListTile(
                        title: Text(
                          template.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          template.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.pop(context, template);
                        },
                        contentPadding: EdgeInsets.zero,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCustomTemplate(BuildContext context) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Create a template from current selection/content?'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Template Name'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true) {
      final newTemplate = Template(
        id: const Uuid().v4(),
        name: nameController.text,
        description: descController.text,
        content: currentContent!,
        type: documentType,
      );
      await TemplateService.saveCustomTemplate(newTemplate);
      if (context.mounted) {
        Navigator.pop(context); // Close selection dialog too
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom template created!')),
        );
      }
    }
  }
}
