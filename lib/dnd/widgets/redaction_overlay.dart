import 'package:flutter/material.dart';
import '../../widgets/glass_container.dart';

class RedactionOverlay extends StatelessWidget {
  final Widget child;
  final bool isRedacted;
  final VoidCallback? onToggle;
  final String label;

  const RedactionOverlay({
    super.key,
    required this.child,
    this.isRedacted = true,
    this.onToggle,
    this.label = 'SECRET',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isRedacted)
          Positioned.fill(
            child: GestureDetector(
              onTap: onToggle,
              child: GlassContainer(
                opacity: 0.8,
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.visibility_off,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (!isRedacted && onToggle != null)
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.visibility, size: 16),
              onPressed: onToggle,
              tooltip: 'Hide',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
      ],
    );
  }
}
