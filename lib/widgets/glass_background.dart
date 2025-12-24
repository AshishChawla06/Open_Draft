import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/theme_service.dart';

class GlassBackground extends StatefulWidget {
  final Widget child;
  final Color? tintColor;

  const GlassBackground({super.key, required this.child, this.tintColor});

  @override
  State<GlassBackground> createState() => _GlassBackgroundState();
}

class _GlassBackgroundState extends State<GlassBackground> {
  final ValueNotifier<Offset> _offsetNotifier = ValueNotifier(Offset.zero);

  String _colorToHex(Color color) {
    return '#${(color.a * 255).toInt().toRadixString(16).padLeft(2, '0')}${(color.r * 255).toInt().toRadixString(16).padLeft(2, '0')}${(color.g * 255).toInt().toRadixString(16).padLeft(2, '0')}${(color.b * 255).toInt().toRadixString(16).padLeft(2, '0')}'
        .substring(2);
  }

  @override
  void dispose() {
    _offsetNotifier.dispose();
    super.dispose();
  }

  void _handleHover(PointerEvent event) {
    if (!mounted) return;
    // Calculate offset based on center of screen
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);
    final delta = event.position - center;

    // Small parallax factor (negative for background moving opposite to mouse usually looks like depth)
    // Or positive for "looking through a window". Let's go with subtle opposing motion (-0.02)
    _offsetNotifier.value = delta * -0.015;
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final bgTheme = themeService.backgroundTheme;
    final customSvgCode = themeService.customSvg;
    final customImagePath = themeService.customImagePath;
    final isParallax = themeService.isParallaxEnabled;

    // Use tintColor if provided, otherwise fall back to primary
    final activeTint = widget.tintColor ?? colorScheme.primary;

    Widget backgroundWidget;

    if (customImagePath != null && customImagePath.isNotEmpty) {
      if (kIsWeb) {
        backgroundWidget = Image.network(
          customImagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              Container(color: colorScheme.surface),
        );
      } else {
        backgroundWidget = Image.file(
          File(customImagePath),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              Container(color: colorScheme.surface),
        );
      }
    } else if (customSvgCode != null && customSvgCode.isNotEmpty) {
      backgroundWidget = SvgPicture.string(
        customSvgCode,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholderBuilder: (context) => Container(color: colorScheme.surface),
      );
    } else {
      // PRESET SVG LOGIC
      String bg1 = '050816';
      String bg2 = '04101F';
      String primary1 = '4F46E5';
      String primary2 = '22C1C3';
      String secondary1 = 'F97316';
      String secondary2 = 'FB7185';
      String tertiary1 = '0EA5E9';
      String tertiary2 = '22C55E';

      double highlightOpacity = 0.08;
      double grainOpacity = 0.4;

      if (bgTheme == 'vibrant') {
        bg1 = '1A0B2E';
        bg2 = '0F051D';
        primary1 = 'FF0080';
        primary2 = '7928CA';
        secondary1 = 'FF4D4D';
        secondary2 = 'F9CB28';
        tertiary1 = '00DFD8';
        tertiary2 = '007CF0';
        highlightOpacity = 0.1;
        grainOpacity = 0.3;
      } else if (bgTheme == 'ocean') {
        bg1 = '001219';
        bg2 = '001B2E';
        primary1 = '005F73';
        primary2 = '0A9396';
        secondary1 = '94D2BD';
        secondary2 = 'E9D8A6';
        tertiary1 = 'EE9B00';
        tertiary2 = 'CA6702';
        highlightOpacity = 0.06;
        grainOpacity = 0.5;
      } else if (bgTheme == 'forest') {
        bg1 = '081C15';
        bg2 = '0B1F1A';
        primary1 = '1B4332';
        primary2 = '2D6A4F';
        secondary1 = '40916C';
        secondary2 = '52B788';
        tertiary1 = '74C69D';
        tertiary2 = '95D5B2';
        highlightOpacity = 0.07;
        grainOpacity = 0.45;
      } else if (bgTheme != 'default') {
        bg1 = _colorToHex(activeTint.withOpacity(0.1));
        bg2 = _colorToHex(colorScheme.surface);
        primary1 = _colorToHex(activeTint);
        primary2 = _colorToHex(activeTint.withOpacity(0.5));
        secondary1 = _colorToHex(colorScheme.secondary);
        secondary2 = _colorToHex(colorScheme.tertiary);
        tertiary1 = _colorToHex(colorScheme.tertiary);
        tertiary2 = _colorToHex(activeTint.withOpacity(0.1));
        highlightOpacity = 0.08;
        grainOpacity = 0.4;
      }

      final svgString =
          '''
<svg width="1080" height="2400" viewBox="0 0 1080 2400" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bgGradient" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#$bg1" />
      <stop offset="100%" stop-color="#$bg2" />
    </linearGradient>

    <linearGradient id="primaryBlob" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#$primary1" />
      <stop offset="100%" stop-color="#$primary2" />
    </linearGradient>

    <linearGradient id="secondaryBlob" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#$secondary1" />
      <stop offset="100%" stop-color="#$secondary2" />
    </linearGradient>

    <linearGradient id="tertiaryBlob" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#$tertiary1" />
      <stop offset="100%" stop-color="#$tertiary2" />
    </linearGradient>

    <filter id="grain">
      <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="3" stitchTiles="noStitch" />
      <feColorMatrix type="saturate" values="0" />
      <feComponentTransfer>
        <feFuncA type="linear" slope="0.08" />
      </feComponentTransfer>
      <feBlend in="SourceGraphic" mode="soft-light" />
    </filter>
  </defs>

  <rect x="0" y="0" width="1080" height="2400" fill="url(#bgGradient)" />

  <path id="primaryShape" fill="url(#primaryBlob)" fill-opacity="0.95" d="M -200 200 C 200 -100, 700 -100, 900 250 C 1050 500, 900 700, 650 750 C 350 820, 50 650, -80 450 Z" />
  <path id="secondaryShape" fill="url(#secondaryBlob)" fill-opacity="0.75" d="M 500 -200 C 850 -50, 1200 150, 1200 500 C 1200 800, 950 950, 700 900 C 500 860, 380 700, 400 500 C 420 320, 350 20, 500 -200 Z" />
  <path id="tertiaryShape" fill="url(#tertiaryBlob)" fill-opacity="0.85" d="M -200 1400 C 100 1300, 450 1300, 700 1450 C 950 1600, 1150 1900, 1000 2150 C 850 2400, 450 2450, 200 2300 C -50 2150, -250 1900, -200 1700 Z" />

  <!-- Subtle glass highlight band -->
  <rect x="-50" y="780" width="1180" height="520" rx="260" fill="rgba(255, 255, 255, $highlightOpacity)" />

  <rect x="0" y="0" width="1080" height="2400" filter="url(#grain)" opacity="$grainOpacity" />
</svg>
''';
      backgroundWidget = SvgPicture.string(
        svgString,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholderBuilder: (context) => Container(color: colorScheme.surface),
      );
    }

    return MouseRegion(
      onHover: isParallax ? _handleHover : null,
      child: Stack(
        children: [
          Positioned.fill(
            // Scale up slightly so parallax edges don't show background color
            child: Transform.scale(
              scale: isParallax ? 1.05 : 1.0,
              child: ValueListenableBuilder<Offset>(
                valueListenable: _offsetNotifier,
                builder: (context, offset, child) {
                  return Transform.translate(
                    offset: isParallax ? offset : Offset.zero,
                    child: backgroundWidget,
                  );
                },
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
