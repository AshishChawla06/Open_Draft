import 'package:flutter/material.dart';
import '../models/document_type.dart';

class DocumentTypeBadge extends StatelessWidget {
  final DocumentType documentType;
  final double? fontSize;

  const DocumentTypeBadge({
    super.key,
    required this.documentType,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(colors.icon, size: fontSize ?? 12, color: colors.textColor),
          const SizedBox(width: 4),
          Text(
            colors.label,
            style: TextStyle(
              fontSize: fontSize ?? 11,
              fontWeight: FontWeight.bold,
              color: colors.textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeColors _getColors(BuildContext context) {
    switch (documentType) {
      case DocumentType.scp:
        return _BadgeColors(
          backgroundColor: const Color(0xFF1A1A1A),
          borderColor: const Color(0xFFFF4444),
          textColor: const Color(0xFFFF4444),
          icon: Icons.warning_amber_rounded,
          label: 'SCP',
        );
      case DocumentType.novel:
        return _BadgeColors(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          borderColor: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onPrimaryContainer,
          icon: Icons.book_rounded,
          label: 'NOVEL',
        );
    }
  }
}

class _BadgeColors {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData icon;
  final String label;

  _BadgeColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.icon,
    required this.label,
  });
}
