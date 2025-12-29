import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _seedColorKey = 'seed_color';
  static const String _backgroundThemeKey = 'background_theme';
  static const String _customSvgKey = 'custom_svg';
  static const String _customImagePathKey = 'custom_image_path';

  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = Colors.blue;
  String _backgroundTheme = 'default';
  String? _customSvg;
  String? _customImagePath;

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  String get backgroundTheme => _backgroundTheme;
  String? get customSvg => _customSvg;
  String? get customImagePath => _customImagePath;

  late Future<void> _initFuture;
  Future<void> get initialization => _initFuture;

  ThemeService() {
    _initFuture = initialize();
  }

  Future<void> initialize() async {
    await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt(_themeModeKey);
    if (themeModeIndex != null) {
      _themeMode = ThemeMode.values[themeModeIndex];
    }

    final seedColorValue = prefs.getInt(_seedColorKey);
    if (seedColorValue != null) {
      _seedColor = Color(seedColorValue);
    }

    _backgroundTheme = prefs.getString(_backgroundThemeKey) ?? 'default';
    _customSvg = prefs.getString(_customSvgKey);
    _customImagePath = prefs.getString(_customImagePathKey);

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedColorKey, color.toARGB32());
  }

  Future<void> setBackgroundTheme(String theme) async {
    _backgroundTheme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundThemeKey, theme);
  }

  Future<void> setCustomSvg(String? svg) async {
    _customSvg = svg;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (svg != null) {
      await prefs.setString(_customSvgKey, svg);
    } else {
      await prefs.remove(_customSvgKey);
    }
  }

  Future<void> setCustomImagePath(String? path) async {
    _customImagePath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_customImagePathKey, path);
    } else {
      await prefs.remove(_customImagePathKey);
    }
  }

  static const String _parallaxKey = 'parallax_enabled';
  bool _isParallaxEnabled = false;
  bool get isParallaxEnabled => _isParallaxEnabled;

  Future<void> setParallaxEnabled(bool enabled) async {
    _isParallaxEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_parallaxKey, enabled);
  }
}
