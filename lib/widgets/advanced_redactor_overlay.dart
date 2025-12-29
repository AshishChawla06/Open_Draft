import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/redaction.dart';

class AdvancedRedactorOverlay extends StatefulWidget {
  final Redaction redaction;
  final Function(Redaction) onUpdate;
  final VoidCallback onDelete;
  final bool isReadOnly;

  const AdvancedRedactorOverlay({
    super.key,
    required this.redaction,
    required this.onUpdate,
    required this.onDelete,
    this.isReadOnly = false,
  });

  @override
  State<AdvancedRedactorOverlay> createState() =>
      _AdvancedRedactorOverlayState();
}

class _AdvancedRedactorOverlayState extends State<AdvancedRedactorOverlay> {
  late double _x;
  late double _y;
  late double _width;
  late double _height;

  @override
  void initState() {
    super.initState();
    _x = widget.redaction.x ?? 100;
    _y = widget.redaction.y ?? 100;
    _width = widget.redaction.width ?? 200;
    _height = widget.redaction.height ?? 50;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.redaction.revealed && widget.isReadOnly) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onPanUpdate: widget.isReadOnly
            ? null
            : (details) {
                setState(() {
                  _x += details.delta.dx;
                  _y += details.delta.dy;
                });
              },
        onPanEnd: widget.isReadOnly ? null : (_) => _notifyUpdate(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildRedactionBody(),
            if (!widget.isReadOnly) _buildResizeHandles(),
          ],
        ),
      ),
    );
  }

  Widget _buildRedactionBody() {
    Widget content;
    switch (widget.redaction.style) {
      case 'blur':
        content = ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.white.withValues(alpha: 0.1),
              width: _width,
              height: _height,
            ),
          ),
        );
        break;
      case 'pixel':
        content = CustomPaint(
          size: Size(_width, _height),
          painter: PixelatedPainter(),
        );
        break;
      case 'bar':
      default:
        content = Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(2),
          ),
        );
    }

    if (widget.redaction.revealed) {
      return Opacity(opacity: 0.3, child: content);
    }

    return content;
  }

  Widget _buildResizeHandles() {
    return Positioned(
      right: -10,
      bottom: -10,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _width = (_width + details.delta.dx).clamp(20, 1000);
            _height = (_height + details.delta.dy).clamp(10, 500);
          });
        },
        onPanEnd: (_) => _notifyUpdate(),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(Icons.open_in_full, size: 14, color: Colors.white),
        ),
      ),
    );
  }

  void _notifyUpdate() {
    widget.onUpdate(
      widget.redaction.copyWith(x: _x, y: _y, width: _width, height: _height),
    );
  }
}

class PixelatedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.8);
    final double pixelSize = 10.0;

    for (double x = 0; x < size.width; x += pixelSize) {
      for (double y = 0; y < size.height; y += pixelSize) {
        canvas.drawRect(Rect.fromLTWH(x, y, pixelSize, pixelSize), paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
