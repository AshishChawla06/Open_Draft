import 'package:flutter/material.dart';
import '../../models/scp_metadata.dart';
import '../../models/book.dart';
import '../domain/object_classes.dart';
import '../../services/database_service.dart';

class SCPMetadataPanel extends StatefulWidget {
  final Book book;
  final VoidCallback onUpdate;

  const SCPMetadataPanel({
    super.key,
    required this.book,
    required this.onUpdate,
  });

  @override
  State<SCPMetadataPanel> createState() => _SCPMetadataPanelState();
}

class _SCPMetadataPanelState extends State<SCPMetadataPanel> {
  late TextEditingController _itemNumberController;
  late SCPObjectClass _selectedClass;
  late int _clearanceLevel;
  late Set<SCPHazardType> _selectedHazards;

  @override
  void initState() {
    super.initState();
    final metadata =
        widget.book.scpMetadata ??
        SCPMetadata(itemNumber: 'SCP-XXXX', objectClass: 'Safe');
    _itemNumberController = TextEditingController(text: metadata.itemNumber);
    _selectedClass = SCPObjectClass.fromString(metadata.objectClass);
    _clearanceLevel = metadata.clearanceLevel;
    _selectedHazards = metadata.hazards
        .map(
          (h) => SCPHazardType.values.firstWhere(
            (e) => e.name == h,
            orElse: () => SCPHazardType.biological,
          ),
        )
        .toSet();
  }

  @override
  void dispose() {
    _itemNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveMetadata() async {
    final currentMetadata =
        widget.book.scpMetadata ??
        SCPMetadata(itemNumber: 'SCP-XXXX', objectClass: 'Safe');

    final updatedMetadata = currentMetadata.copyWith(
      itemNumber: _itemNumberController.text,
      objectClass: _selectedClass.displayName,
      clearanceLevel: _clearanceLevel,
      hazards: _selectedHazards.map((h) => h.name).toList(),
    );

    final updatedBook = widget.book.copyWith(scpMetadata: updatedMetadata);
    await DatabaseService.updateBook(updatedBook);
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.security, color: colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                'METADATA',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),

        // Divider
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          color: colorScheme.onSurface.withValues(alpha: 0.1),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Number
                _buildSectionLabel('ITEM NUMBER'),
                const SizedBox(height: 12),
                TextField(
                  controller: _itemNumberController,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'Courier Prime',
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: colorScheme.surface.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) => _saveMetadata(),
                ),

                const SizedBox(height: 28),

                // Object Class
                _buildSectionLabel('OBJECT CLASS'),
                const SizedBox(height: 12),
                ...SCPObjectClass.values.map((objClass) {
                  final isSelected = _selectedClass == objClass;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() => _selectedClass = objClass);
                        _saveMetadata();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? objClass.color.withValues(alpha: 0.15)
                              : colorScheme.surface.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? objClass.color
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: objClass.color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: objClass.color.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    objClass.displayName,
                                    style: TextStyle(
                                      color: isSelected
                                          ? objClass.color
                                          : colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    objClass.description,
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 28),

                // Clearance Level
                _buildSectionLabel('CLEARANCE LEVEL'),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(6, (index) {
                    final level = index;
                    final isSelected = _clearanceLevel == level;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index < 5 ? 6 : 0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() => _clearanceLevel = level);
                            _saveMetadata();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.surface.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '$level',
                                style: TextStyle(
                                  color: isSelected
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 28),

                // Hazard Types
                _buildSectionLabel('HAZARD TYPES'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SCPHazardType.values.map((hazard) {
                    final isSelected = _selectedHazards.contains(hazard);
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedHazards.remove(hazard);
                          } else {
                            _selectedHazards.add(hazard);
                          }
                        });
                        _saveMetadata();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.2)
                              : colorScheme.surface.withValues(alpha: 0.3),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.transparent,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hazard.icon,
                              size: 14,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withValues(
                                      alpha: 0.5,
                                    ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hazard.displayName,
                              style: TextStyle(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }
}
