import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/theme_service.dart';
import '../services/image_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_background.dart';
import '../services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _dailyGoal;
  late int _autoSaveInterval;
  late String _fontFamily;
  late double _fontSize;
  late double _lineSpacing;
  late bool _grammarCheckEnabled;
  late String _exportFormat;
  late String _authorName;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final dailyGoal = await SettingsService.getDailyGoal();
    final autoSaveInterval = await SettingsService.getAutoSaveInterval();
    final fontFamily = await SettingsService.getEditorFontFamily();
    final fontSize = await SettingsService.getEditorFontSize();
    final lineSpacing = await SettingsService.getEditorLineSpacing();
    final grammarEnabled = await SettingsService.getGrammarCheckEnabled();
    final exportFormat = await SettingsService.getDefaultExportFormat();
    final authorName = await SettingsService.getDefaultAuthorName();

    setState(() {
      _dailyGoal = dailyGoal;
      _autoSaveInterval = autoSaveInterval;
      _fontFamily = fontFamily;
      _fontSize = fontSize;
      _lineSpacing = lineSpacing;
      _grammarCheckEnabled = grammarEnabled;
      _exportFormat = exportFormat;
      _authorName = authorName;
      _isLoading = false;
    });
  }

  Future<void> _resetSettings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to defaults?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SettingsService.resetToDefaults();
      // Also reset ThemeService things
      if (mounted) {
        final themeService = context.read<ThemeService>();
        await themeService.setThemeMode(ThemeMode.system);
        await themeService.setBackgroundTheme('default');
        await themeService.setCustomSvg(null);
        await themeService.setCustomImagePath(null);
      }
      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings reset to defaults')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Settings'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetSettings,
              tooltip: 'Reset to Defaults',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection('Writing', [
              _buildDailyGoalTile(),
              _buildAutoSaveIntervalTile(),
              _buildGrammarCheckTile(),
            ]),
            const SizedBox(height: 24),
            _buildSection('Appearance', [
              _buildThemeModeTile(),
              _buildBackgroundThemeTile(),
              _buildCustomSvgTile(),
              _buildCustomImageTile(),
            ]),
            const SizedBox(height: 24),
            _buildSection('Editor', [
              _buildFontFamilyTile(),
              _buildFontSizeTile(),
              _buildLineSpacingTile(),
            ]),
            const SizedBox(height: 24),
            _buildSection('Export', [
              _buildDefaultExportFormatTile(),
              _buildDefaultAuthorNameTile(),
            ]),
            const SizedBox(height: 24),
            _buildSection('Data Management', [
              _buildBackupTile(),
              _buildRestoreTile(),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        GlassContainer(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(32),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDailyGoalTile() {
    return ListTile(
      leading: const Icon(Icons.flag),
      title: const Text('Daily Word Goal'),
      subtitle: Text('$_dailyGoal words per day'),
      trailing: const Icon(Icons.edit),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      onTap: () async {
        final controller = TextEditingController(text: _dailyGoal.toString());
        final newGoal = await showDialog<int>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Daily Word Goal'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Words per day',
                suffixText: 'words',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final goal = int.tryParse(controller.text);
                  Navigator.pop(context, goal);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );

        if (newGoal != null && newGoal > 0) {
          await SettingsService.setDailyGoal(newGoal);
          setState(() => _dailyGoal = newGoal);
        }
      },
    );
  }

  Widget _buildAutoSaveIntervalTile() {
    return ListTile(
      leading: const Icon(Icons.save),
      title: const Text('Auto-Save Interval'),
      subtitle: Text('Save every $_autoSaveInterval seconds'),
      trailing: const Icon(Icons.edit),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      onTap: () async {
        final controller = TextEditingController(
          text: _autoSaveInterval.toString(),
        );
        final newInterval = await showDialog<int>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Auto-Save Interval'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Seconds',
                suffixText: 'seconds',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final interval = int.tryParse(controller.text);
                  Navigator.pop(context, interval);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );

        if (newInterval != null && newInterval > 0) {
          await SettingsService.setAutoSaveInterval(newInterval);
          setState(() => _autoSaveInterval = newInterval);
        }
      },
    );
  }

  Widget _buildGrammarCheckTile() {
    return SwitchListTile(
      secondary: const Icon(Icons.spellcheck),
      title: const Text('Grammar Check'),
      subtitle: const Text('Enable real-time grammar checking'),
      value: _grammarCheckEnabled,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      onChanged: (value) async {
        await SettingsService.setGrammarCheckEnabled(value);
        setState(() => _grammarCheckEnabled = value);
      },
    );
  }

  Widget _buildThemeModeTile() {
    final themeService = context.watch<ThemeService>();
    final modes = ThemeMode.values;

    return ListTile(
      leading: const Icon(Icons.brightness_medium),
      title: const Text('Theme Mode'),
      subtitle: Text(themeService.themeMode.name.toUpperCase()),
      trailing: const Icon(Icons.arrow_drop_down),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      onTap: () async {
        final newMode = await showDialog<ThemeMode>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Select Theme Mode'),
            children: modes.map((mode) {
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(context, mode),
                child: Text(mode.name.toUpperCase()),
              );
            }).toList(),
          ),
        );

        if (newMode != null) {
          await themeService.setThemeMode(newMode);
        }
      },
    );
  }

  Widget _buildBackgroundThemeTile() {
    final themeService = context.watch<ThemeService>();
    final themes = ['default', 'vibrant', 'ocean', 'forest', 'custom'];

    return ListTile(
      leading: const Icon(Icons.wallpaper),
      title: const Text('Background Preset'),
      subtitle: Text(themeService.backgroundTheme.toUpperCase()),
      trailing: const Icon(Icons.arrow_drop_down),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      onTap: () async {
        final newTheme = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Select Background'),
            children: themes.map((theme) {
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(context, theme),
                child: Text(theme.toUpperCase()),
              );
            }).toList(),
          ),
        );

        if (newTheme != null) {
          await themeService.setBackgroundTheme(newTheme);
          if (newTheme != 'custom') {
            await themeService.setCustomSvg(null);
            await themeService.setCustomImagePath(null);
          }
        }
      },
    );
  }

  Widget _buildCustomSvgTile() {
    final themeService = context.watch<ThemeService>();
    return ListTile(
      leading: const Icon(Icons.code),
      title: const Text('Custom SVG Code'),
      subtitle: Text(
        themeService.customSvg != null ? 'Custom SVG applied' : 'Not set',
      ),
      trailing: const Icon(Icons.edit),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      onTap: () async {
        final controller = TextEditingController(text: themeService.customSvg);
        final newSvg = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Custom SVG Code'),
            content: TextField(
              controller: controller,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: '<svg>...</svg>',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Apply'),
              ),
            ],
          ),
        );

        if (newSvg != null) {
          await themeService.setBackgroundTheme('custom');
          await themeService.setCustomSvg(newSvg.isEmpty ? null : newSvg);
          await themeService.setCustomImagePath(null);
        }
      },
    );
  }

  Widget _buildCustomImageTile() {
    final themeService = context.watch<ThemeService>();
    return ListTile(
      leading: const Icon(Icons.image),
      title: const Text('Custom Background Image'),
      subtitle: Text(
        themeService.customImagePath != null
            ? 'Custom image applied'
            : 'Not set',
      ),
      trailing: const Icon(Icons.add_photo_alternate),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      onTap: () async {
        final picked = await ImageService.pickImage();
        if (picked != null) {
          final saved = await ImageService.saveImage(
            picked,
            'custom_bg',
            category: 'backgrounds',
          );
          if (saved != null) {
            await themeService.setBackgroundTheme('custom');
            await themeService.setCustomImagePath(saved);
            await themeService.setCustomSvg(null);
          }
        }
      },
    );
  }

  Widget _buildFontFamilyTile() {
    final fonts = ['Roboto', 'Open Sans', 'Lato', 'Merriweather', 'Courier'];
    return ListTile(
      leading: const Icon(Icons.font_download),
      title: const Text('Font Family'),
      subtitle: Text(_fontFamily),
      trailing: const Icon(Icons.arrow_drop_down),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      onTap: () async {
        final newFont = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Select Font'),
            children: fonts.map((font) {
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(context, font),
                child: Text(font, style: TextStyle(fontFamily: font)),
              );
            }).toList(),
          ),
        );

        if (newFont != null) {
          await SettingsService.setEditorFontFamily(newFont);
          setState(() => _fontFamily = newFont);
        }
      },
    );
  }

  Widget _buildFontSizeTile() {
    return ListTile(
      leading: const Icon(Icons.format_size),
      title: const Text('Font Size'),
      subtitle: Text('${_fontSize.toInt()}pt'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      trailing: SizedBox(
        width: 200,
        child: Slider(
          value: _fontSize,
          min: 12,
          max: 24,
          divisions: 12,
          label: '${_fontSize.toInt()}pt',
          onChanged: (value) {
            setState(() => _fontSize = value);
          },
          onChangeEnd: (value) async {
            await SettingsService.setEditorFontSize(value);
          },
        ),
      ),
    );
  }

  Widget _buildLineSpacingTile() {
    return ListTile(
      leading: const Icon(Icons.format_line_spacing),
      title: const Text('Line Spacing'),
      subtitle: Text('${_lineSpacing.toStringAsFixed(1)}x'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      trailing: SizedBox(
        width: 200,
        child: Slider(
          value: _lineSpacing,
          min: 1.0,
          max: 2.5,
          divisions: 15,
          label: '${_lineSpacing.toStringAsFixed(1)}x',
          onChanged: (value) {
            setState(() => _lineSpacing = value);
          },
          onChangeEnd: (value) async {
            await SettingsService.setEditorLineSpacing(value);
          },
        ),
      ),
    );
  }

  Widget _buildDefaultExportFormatTile() {
    final formats = ['pdf', 'epub', 'txt'];
    return ListTile(
      leading: const Icon(Icons.file_download),
      title: const Text('Default Export Format'),
      subtitle: Text(_exportFormat.toUpperCase()),
      trailing: const Icon(Icons.arrow_drop_down),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      onTap: () async {
        final newFormat = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Select Export Format'),
            children: formats.map((format) {
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(context, format),
                child: Text(format.toUpperCase()),
              );
            }).toList(),
          ),
        );

        if (newFormat != null) {
          await SettingsService.setDefaultExportFormat(newFormat);
          setState(() => _exportFormat = newFormat);
        }
      },
    );
  }

  Widget _buildDefaultAuthorNameTile() {
    return ListTile(
      leading: const Icon(Icons.person),
      title: const Text('Default Author Name'),
      subtitle: Text(_authorName.isEmpty ? 'Not set' : _authorName),
      trailing: const Icon(Icons.edit),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      onTap: () async {
        final controller = TextEditingController(text: _authorName);
        final newName = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Default Author Name'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Author name',
                hintText: 'Your name',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Save'),
              ),
            ],
          ),
        );

        if (newName != null) {
          await SettingsService.setDefaultAuthorName(newName);
          setState(() => _authorName = newName);
        }
      },
    );
  }

  Widget _buildBackupTile() {
    return ListTile(
      leading: const Icon(Icons.cloud_download),
      title: const Text('Backup Library'),
      subtitle: const Text('Save a copy of all your books and settings'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      onTap: () async {
        setState(() => _isLoading = true);
        try {
          await BackupService.createBackup();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup created successfully')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Widget _buildRestoreTile() {
    return ListTile(
      leading: const Icon(Icons.restore),
      title: const Text('Restore from Backup'),
      subtitle: const Text('Import library from a backup file'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restore Backup'),
            content: const Text(
              'This will replace your current library with the backup data. Are you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restore'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          setState(() => _isLoading = true);
          try {
            await BackupService.restoreBackup();
            await _loadSettings(); // Reload settings
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Library restored successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
            }
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        }
      },
    );
  }
}
