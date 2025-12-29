import 'package:flutter/material.dart';
import 'glass_background.dart';
import 'logo_header.dart';

class AppLoadingScreen extends StatefulWidget {
  final String? message;
  final Future<void>? future;
  final VoidCallback? onComplete;

  const AppLoadingScreen({
    super.key,
    this.message,
    this.future,
    this.onComplete,
  });

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    if (widget.future != null) {
      widget.future!.then((_) {
        if (mounted && widget.onComplete != null) {
          widget.onComplete!();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LogoHeader(size: 140, rotation: _controller),
              if (widget.message != null) ...[
                const SizedBox(height: 32),
                Text(
                  widget.message!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
