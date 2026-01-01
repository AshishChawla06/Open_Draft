import 'package:flutter/material.dart';
import 'glass_container.dart';

enum EditorMode {
  write, // Distraction free
  view, // Reader preview
  edit, // Formatting / Standard
  notes, // Toggle notes
  share, // Export
}

class IntegratedActionBar extends StatelessWidget {
  final EditorMode currentMode;
  final Function(EditorMode) onModeChanged;
  final bool isNotesOpen;
  final bool isToolbarOpen;
  final bool isDistractionFree;

  final bool hasUnsavedChanges;
  final VoidCallback? onInfoPressed;
  final VoidCallback? onShowOutline;

  const IntegratedActionBar({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.isNotesOpen = false,
    this.isToolbarOpen = true,
    this.isDistractionFree = false,
    this.hasUnsavedChanges = false,
    this.onInfoPressed,
    this.onShowOutline,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      borderRadius: BorderRadius.circular(32),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            context,
            EditorMode.write,
            isDistractionFree ? Icons.fullscreen_exit : Icons.auto_awesome,
            'Focus Mode',
            isDistractionFree,
          ),
          _buildActionButton(
            context,
            EditorMode.edit,
            Icons.edit_note,
            'Edit Tools',
            isToolbarOpen && !isDistractionFree,
          ),
          _buildActionButton(
            context,
            EditorMode.notes,
            Icons.assignment_outlined,
            'Notes',
            isNotesOpen,
          ),
          const SizedBox(width: 8),
          Container(
            height: 24,
            width: 1,
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            context,
            EditorMode.view,
            Icons.visibility_outlined,
            'Preview',
            false,
          ),
          _buildActionButton(
            context,
            EditorMode.share,
            Icons.ios_share,
            'Export',
            false,
          ),
          const SizedBox(width: 12),
          Container(
            height: 24,
            width: 1,
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 12),
          _buildSavedPill(context),
          const SizedBox(width: 8),
          _buildIconButton(
            context,
            onShowOutline,
            Icons.format_list_bulleted,
            'Outline',
          ),
          _buildInfoButton(context),
        ],
      ),
    );
  }

  Widget _buildSavedPill(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: hasUnsavedChanges
            ? Colors.orange.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasUnsavedChanges
              ? Colors.orange.withValues(alpha: 0.2)
              : Colors.green.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: hasUnsavedChanges ? Colors.orange : Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            hasUnsavedChanges ? 'Unsaved' : 'Saved',
            style: TextStyle(
              color: hasUnsavedChanges ? Colors.orange : Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    VoidCallback? onPressed,
    IconData icon,
    String tooltip,
  ) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      tooltip: tooltip,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
    );
  }

  Widget _buildInfoButton(BuildContext context) {
    return InkWell(
      onTap: onInfoPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: const Icon(Icons.info_outline, size: 14, color: Colors.red),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    EditorMode mode,
    IconData icon,
    String tooltip,
    bool isActive,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      icon: Icon(
        icon,
        size: 20,
        color: isActive ? colorScheme.primary : colorScheme.onSurface,
      ),
      tooltip: tooltip,
      onPressed: () => onModeChanged(mode),
      style: IconButton.styleFrom(
        backgroundColor: isActive
            ? colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
      ),
    );
  }
}
