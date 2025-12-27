import 'package:flutter/material.dart';
import 'glass_container.dart';

class LogoHeader extends StatelessWidget {
  final double size;
  final bool showText;

  const LogoHeader({super.key, this.size = 80, this.showText = true});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GlassContainer(
          width: size,
          height: size,
          borderRadius: BorderRadius.circular(size * 0.25),
          blur: 15,
          opacity: 0.05,
          color: colorScheme.primary,
          child: Center(
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.8),
                  width: size * 0.06,
                ),
                borderRadius: BorderRadius.circular(size * 0.15),
              ),
              child: Center(
                child: Container(
                  width: size * 0.18,
                  height: size * 0.18,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 16),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'OpenDraft',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
