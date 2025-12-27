import 'dart:io';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';

void main() {
  // Initialize sqflite_common_ffi for desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeService())],
      child: const OpenDraftApp(),
    ),
  );
}

class OpenDraftApp extends StatelessWidget {
  const OpenDraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          lightColorScheme = ColorScheme.fromSeed(
            seedColor: themeService.seedColor,
          );
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: themeService.seedColor,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'OpenDraft',
          debugShowCheckedModeBanner: false,
          themeMode: themeService.themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            quill.FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', 'US')],
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
            textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
            scaffoldBackgroundColor: lightColorScheme.surface,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            scaffoldBackgroundColor: darkColorScheme.surface,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
