import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage all application settings
class SettingsService {
  static const String _dailyGoalKey = 'dailyGoal';
  static const String _autoSaveIntervalKey = 'autoSaveInterval';
  static const String _editorFontFamilyKey = 'editorFontFamily';
  static const String _editorFontSizeKey = 'editorFontSize';
  static const String _editorLineSpacingKey = 'editorLineSpacing';
  static const String _grammarCheckEnabledKey = 'grammarCheckEnabled';
  static const String _defaultExportFormatKey = 'defaultExportFormat';
  static const String _defaultAuthorNameKey = 'defaultAuthorName';
  static const String _backgroundThemeKey = 'backgroundTheme';

  // Default values
  static const int defaultDailyGoal = 2000;
  static const int defaultAutoSaveInterval = 2; // seconds
  static const String defaultFontFamily = 'Roboto';
  static const double defaultFontSize = 16.0;
  static const double defaultLineSpacing = 1.5;
  static const bool defaultGrammarCheckEnabled = true;
  static const String defaultExportFormat = 'pdf';
  static const String defaultAuthorName = '';
  static const String defaultBackgroundTheme = 'default';

  /// Get daily word count goal
  static Future<int> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyGoalKey) ?? defaultDailyGoal;
  }

  /// Set daily word count goal
  static Future<void> setDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyGoalKey, goal);
  }

  /// Get auto-save interval in seconds
  static Future<int> getAutoSaveInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_autoSaveIntervalKey) ?? defaultAutoSaveInterval;
  }

  /// Set auto-save interval in seconds
  static Future<void> setAutoSaveInterval(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoSaveIntervalKey, seconds);
  }

  /// Get editor font family
  static Future<String> getEditorFontFamily() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_editorFontFamilyKey) ?? defaultFontFamily;
  }

  /// Set editor font family
  static Future<void> setEditorFontFamily(String fontFamily) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_editorFontFamilyKey, fontFamily);
  }

  /// Get editor font size
  static Future<double> getEditorFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_editorFontSizeKey) ?? defaultFontSize;
  }

  /// Set editor font size
  static Future<void> setEditorFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_editorFontSizeKey, size);
  }

  /// Get editor line spacing
  static Future<double> getEditorLineSpacing() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_editorLineSpacingKey) ?? defaultLineSpacing;
  }

  /// Set editor line spacing
  static Future<void> setEditorLineSpacing(double spacing) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_editorLineSpacingKey, spacing);
  }

  /// Get grammar check enabled status
  static Future<bool> getGrammarCheckEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_grammarCheckEnabledKey) ?? defaultGrammarCheckEnabled;
  }

  /// Set grammar check enabled status
  static Future<void> setGrammarCheckEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_grammarCheckEnabledKey, enabled);
  }

  /// Get default export format
  static Future<String> getDefaultExportFormat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultExportFormatKey) ?? defaultExportFormat;
  }

  /// Set default export format
  static Future<void> setDefaultExportFormat(String format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultExportFormatKey, format);
  }

  /// Get default author name
  static Future<String> getDefaultAuthorName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultAuthorNameKey) ?? defaultAuthorName;
  }

  /// Set default author name
  static Future<void> setDefaultAuthorName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultAuthorNameKey, name);
  }

  /// Get background theme
  static Future<String> getBackgroundTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backgroundThemeKey) ?? defaultBackgroundTheme;
  }

  /// Set background theme
  static Future<void> setBackgroundTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundThemeKey, theme);
  }

  /// Reset all settings to defaults
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dailyGoalKey);
    await prefs.remove(_autoSaveIntervalKey);
    await prefs.remove(_editorFontFamilyKey);
    await prefs.remove(_editorFontSizeKey);
    await prefs.remove(_editorLineSpacingKey);
    await prefs.remove(_grammarCheckEnabledKey);
    await prefs.remove(_defaultExportFormatKey);
    await prefs.remove(_defaultAuthorNameKey);
    await prefs.remove(_backgroundThemeKey);
  }
}
