import 'package:flutter/material.dart';

enum ReaderThemeType { standard, scpWiki, manuscript }

class ReaderTheme {
  final String id;
  final String name;
  final Color backgroundColor;
  final Color textColor;
  final String? fontFamily;
  final double contentPadding;

  const ReaderTheme({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    this.fontFamily,
    this.contentPadding = 24.0,
  });

  static ReaderTheme get standardDark => const ReaderTheme(
    id: 'standard_dark',
    name: 'Standard Dark',
    backgroundColor: Color(0xFF1E1E1E),
    textColor: Color(0xFFE0E0E0),
    fontFamily: null, // Default
  );

  static ReaderTheme get standardLight => const ReaderTheme(
    id: 'standard_light',
    name: 'Standard Light',
    backgroundColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF333333),
    fontFamily: null, // Default
  );

  static ReaderTheme get scpWiki => const ReaderTheme(
    id: 'scp_wiki',
    name: 'SCP Wiki',
    backgroundColor: Color(0xFFF4F4F4),
    textColor: Color(0xFF333333),
    fontFamily: 'Courier Prime', // Assumes this font is available
  );

  static ReaderTheme get manuscript => const ReaderTheme(
    id: 'manuscript',
    name: 'Manuscript',
    backgroundColor: Color(0xFFF5E6D3), // Parchment color
    textColor: Color(0xFF3E2723), // Dark brown
    fontFamily: 'Playfair Display', // Or 'Times New Roman'
  );

  static List<ReaderTheme> get allThemes => [
    standardDark,
    standardLight,
    scpWiki,
    manuscript,
  ];
}
