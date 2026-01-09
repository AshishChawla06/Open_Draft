import 'package:flutter/material.dart';
import '../widgets/glass_background.dart';
import '../widgets/logo_header.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _navigateToHome();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToHome() async {
    final startTime = DateTime.now();

    try {
      // 1. Initialize Database & Sample Data
      await DatabaseService.initializeSampleData().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Database initialization timed out');
        },
      );

      // 2. Initialize Theme Service Preferences
      if (mounted) {
        await Provider.of<ThemeService>(
          context,
          listen: false,
        ).initialization.timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            debugPrint('Theme initialization timed out');
          },
        );
      }

      // Ensure at least 3 seconds of splash for branding/animation
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < const Duration(seconds: 3)) {
        await Future.delayed(const Duration(seconds: 3) - elapsed);
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      // Continue anyway or show error
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [LogoHeader(size: 160, rotation: _controller)],
          ),
        ),
      ),
    );
  }
}
