import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatefulWidget {
  final Widget? child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;
  final Color? borderColor;
  final bool enableGlow;

  const GlassContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.blur = 25.0,
    this.opacity = 0.1,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.boxShadow,
    this.borderColor,
    this.enableGlow = true,
  });

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer> {
  bool _isHovered = false;
  Offset _mousePos = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = widget.color ?? colorScheme.surface;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(32.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      onHover: (event) {
        if (widget.enableGlow) {
          setState(() => _mousePos = event.localPosition);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow:
              widget.boxShadow ??
              [
                // Base shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                ),
                // Outer Glow shadow
                if (widget.enableGlow && _isHovered)
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 25,
                    spreadRadius: 1,
                    offset: const Offset(0, 0),
                  ),
              ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
            child: Container(
              // Background Decoration (Base Layer)
              decoration: BoxDecoration(
                color: baseColor.withValues(alpha: widget.opacity),
                borderRadius: borderRadius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surface.withValues(
                      alpha: widget.opacity + 0.05,
                    ),
                    colorScheme.surface.withValues(alpha: widget.opacity),
                    colorScheme.surface.withValues(
                      alpha: widget.opacity + 0.02,
                    ),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
              // Foreground Decoration (Border Layer - Top)
              foregroundDecoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(
                  color: widget.enableGlow && _isHovered
                      ? colorScheme.primary.withValues(alpha: 0.5)
                      : (widget.borderColor ??
                            colorScheme.onSurface.withValues(alpha: 0.08)),
                  width: 1.0,
                ),
              ),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  // Radial Cursor Glow Layer (Middle - Behind Content)
                  if (widget.enableGlow && _isHovered)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RadialGlowPainter(
                          center: _mousePos,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),

                  // Content Layer
                  Padding(
                    padding: widget.padding ?? EdgeInsets.zero,
                    child: widget.child ?? const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadialGlowPainter extends CustomPainter {
  final Offset center;
  final Color color;

  _RadialGlowPainter({required this.center, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.2), // Slightly more pronounced center
          color.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 200));

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _RadialGlowPainter oldDelegate) {
    return oldDelegate.center != center || oldDelegate.color != color;
  }
}
