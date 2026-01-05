import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/document_type.dart';
import '../services/database_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/logo_header.dart';
import 'book_detail_screen.dart';
import 'new_book_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:flutter/services.dart';
import '../services/stats_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Book> _recentBooks = [];
  bool _isLoading = true;
  late PageController _pageController;
  Timer? _scrollTimer;
  int _currentFeaturePage = 0;
  bool _isStackHovered = false;
  int? _hoveredCardIndex;
  int _totalWordCount = 0;
  int _currentStreak = 0;
  Map<DateTime, int> _dailyStats = {};
  List<Book> _allBooks = [];

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.segment,
      'title': 'Modular writing',
      'subtitle': 'Organize, Create. One section regions and research bypass.',
      'color': Colors.blue,
    },
    {
      'icon': Icons.folder_shared,
      'title': 'SCP template',
      'subtitle':
          'Reviewed business, opportunities, diagnostics, logs, and vanilla.',
      'color': Colors.red,
    },
    {
      'icon': Icons.public,
      'title': 'World building',
      'subtitle':
          'Create rich characters and locations with deep lore integration.',
      'color': Colors.purple,
    },
    {
      'icon': Icons.file_upload,
      'title': 'Export tools',
      'subtitle':
          'Export to PDF, ePub, and Markdown with professional formatting.',
      'color': Colors.orange,
    },
    {
      'icon': Icons.cloud_sync,
      'title': 'Cloud sync',
      'subtitle':
          'Never lose a word. Seamless synchronization across all your devices.',
      'color': Colors.teal,
    },
    {
      'icon': Icons.code,
      'title': 'Open source & extensible',
      'subtitle': 'Built to be forced, cohering and fronted by the community.',
      'color': Colors.green,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8, initialPage: 0);
    _loadData();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _scrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_isLoading) return;
      _currentFeaturePage++;
      if (_currentFeaturePage >= _features.length) {
        _currentFeaturePage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentFeaturePage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future<void> _loadData() async {
    final books = await DatabaseService.getAllBooks();
    final dailyStats = await DatabaseService.getDailyStats();
    final streak = await StatsService.getCurrentStreak();

    // Sort by updated date descending and take top 3
    final recentBooks = List<Book>.from(books);
    recentBooks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (mounted) {
      setState(() {
        _allBooks = books;
        _recentBooks = recentBooks.take(3).toList();
        _dailyStats = dailyStats;
        _currentStreak = streak;
        _totalWordCount = StatsService.getTotalWordCount(books);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branded Header
            Row(
              children: [
                const LogoHeader(size: 40, showText: true),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Credits',
                  onPressed: () {
                    final colorScheme = Theme.of(context).colorScheme;
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        backgroundColor: colorScheme.surface.withValues(
                          alpha: 0.9,
                        ),
                        title: Row(
                          children: [
                            const Text('🪶 OpenDraft — Credits'),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        content: SizedBox(
                          width: 500,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'This file acknowledges the people, tools, and communities that made OpenDraft possible.',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.7,
                                    ),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildCreditsSection(
                                  context,
                                  '👤 Author',
                                  'Ashish Chawla\nCreator, designer, and lead developer of OpenDraft\nGitHub: https://github.com/AshishChawla06',
                                ),
                                _buildCreditsSection(
                                  context,
                                  '🎨 Design & UX',
                                  'Hybrid Design System\nOpenDraft’s interface is built on a custom blend of:\n\n'
                                      '• Liquid Glass (iOS‑style) translucency\n'
                                      '• Material You Expressive (Pixel‑style) motion, color, and shape\n'
                                      '• Dynamic color tinting\n'
                                      '• SVG‑driven expressive backgrounds\n'
                                      '• Accessibility‑first typography and layout',
                                ),
                                _buildCreditsSection(
                                  context,
                                  '🧠 Inspiration & Foundations',
                                  'OpenDraft draws inspiration from:\n\n'
                                      '• Material You (Google) — expressive color, motion, and shape\n'
                                      '• iOS Glassmorphism — frosted translucency and depth\n'
                                      '• SCP Foundation community — templates, structure, and creative energy\n'
                                      '• Modern writing tools — modular scene‑based drafting and distraction‑free editors\n\n'
                                      'SCP‑related concepts remain under CC BY‑SA 3.0.',
                                ),
                                _buildCreditsSection(
                                  context,
                                  '🛠️ Technologies & Tools',
                                  'OpenDraft is built using:\n\n'
                                      '• Flutter — cross‑platform UI toolkit\n'
                                      '• Dart — primary programming language\n'
                                      '• flutter_svg — SVG rendering\n'
                                      '• super_editor / quill (planned) — rich text editing\n'
                                      '• Material 3 components — icons, shapes, motion\n'
                                      '• GitHub — version control and collaboration',
                                ),
                                _buildCreditsSection(
                                  context,
                                  '💬 Community',
                                  'OpenDraft is shaped by feedback from:\n\n'
                                      '• Writers\n'
                                      '• SCP authors\n'
                                      '• Worldbuilders\n'
                                      '• Open‑source contributors\n\n'
                                      'Your ideas, issues, and pull requests help the project grow.',
                                ),
                                _buildCreditsSection(
                                  context,
                                  '🛡️ Legal Notes',
                                  'OpenDraft is not affiliated with the SCP Foundation or any official SCP wiki.\n'
                                      'All SCP‑related content is governed by CC BY‑SA 3.0.\n\n'
                                      'If you believe your work should be credited here, please open an issue or pull request.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 64),

            // Hero Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Draft, contain,\nand craft your\nworlds.',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                              letterSpacing: -1.5,
                              color: colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Open source, modular writing studio with SCP template, peer boards, and distraction-free drafting.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: _buildElevatedButton(
                              'New Project',
                              true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NewBookScreen(),
                                  ),
                                ).then((_) => _loadData());
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: _buildElevatedButton(
                              'Open Last Draft',
                              false,
                              onTap: () {
                                if (_recentBooks.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookDetailScreen(
                                        book: _recentBooks.first,
                                      ),
                                    ),
                                  ).then((_) => _loadData());
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMiniTag('Member IDs'),
                          _buildMiniTag('SCP'),
                          _buildMiniTag('Campaigns'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                SizedBox(
                  width:
                      450, // Increased width to prevent clipping of fanned-out cards
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isStackHovered = true),
                    onExit: (_) => setState(() => _isStackHovered = false),
                    child: GestureDetector(
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _isStackHovered = !_isStackHovered);
                      },
                      child: SizedBox(
                        height: 400, // Ensure enough height for vertical fan
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            if (_recentBooks.isEmpty)
                              // Fallback if no books
                              _buildDecorativeCard(
                                offset: Offset.zero,
                                opacity: 0.3,
                                isMain: true,
                              )
                            else
                              // Render up to 3 cards in reverse order (bottom first)
                              ...() {
                                final entries = _recentBooks
                                    .take(3)
                                    .toList()
                                    .asMap()
                                    .entries
                                    .toList();

                                // Sort entries so that the hovered card is last (rendered on top)
                                // and others maintain reverse order (2, 1, 0) for proper stacking.
                                entries.sort((a, b) {
                                  if (_hoveredCardIndex != null) {
                                    if (a.key == _hoveredCardIndex) return 1;
                                    if (b.key == _hoveredCardIndex) return -1;
                                  }
                                  return b.key.compareTo(a.key);
                                });

                                return entries.map((entry) {
                                  final index = entry.key;
                                  final book = entry.value;

                                  // Calculate target transform based on hover
                                  double xOffset = 0;
                                  double yOffset = 0;
                                  double rotation = 0;
                                  double scale = 1.0 - (index * 0.05);
                                  double opacity = 1.0 - (index * 0.2);

                                  if (_isStackHovered) {
                                    if (index == 0) {
                                      yOffset = -20;
                                      scale = 1.05;
                                      opacity = 1.0;
                                    } else if (index == 1) {
                                      xOffset = -140;
                                      rotation = -0.05;
                                      opacity = 1.0;
                                      scale = 1.0;
                                    } else if (index == 2) {
                                      xOffset = 140;
                                      rotation = 0.05;
                                      opacity = 1.0;
                                      scale = 1.0;
                                    }
                                  } else {
                                    xOffset = index * 10.0;
                                    yOffset = index * 10.0;
                                  }

                                  // Additional visual pop for the specifically hovered card
                                  if (_hoveredCardIndex == index) {
                                    scale *= 1.05;
                                    yOffset -= 10;
                                  }

                                  return AnimatedPositioned(
                                    key: ValueKey(book.id),
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutBack,
                                    top: 0,
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Transform.translate(
                                        offset: Offset(xOffset, yOffset),
                                        child: Transform.rotate(
                                          angle: rotation,
                                          child: Transform.scale(
                                            scale: scale,
                                            child: MouseRegion(
                                              onEnter: (_) => setState(
                                                () => _hoveredCardIndex = index,
                                              ),
                                              onExit: (_) => setState(() {
                                                // Only clear if we are exiting the specific card
                                                // and not entering another card immediately?
                                                // Actually simple clear is fine, but might flicker if gaps.
                                                // But since cards overlap, enter on next card fires.
                                                if (_hoveredCardIndex ==
                                                    index) {
                                                  _hoveredCardIndex = null;
                                                }
                                              }),
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          BookDetailScreen(
                                                            book: book,
                                                          ),
                                                    ),
                                                  ).then((_) => _loadData());
                                                },
                                                child: MouseRegion(
                                                  cursor: _isStackHovered
                                                      ? SystemMouseCursors.click
                                                      : SystemMouseCursors
                                                            .basic,
                                                  child: GlassContainer(
                                                    width: 200,
                                                    height: 280,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          24,
                                                        ),
                                                    opacity:
                                                        opacity *
                                                        0.2, // Base opacity
                                                    // Highlight if hovered
                                                    // border handled by GlassContainer internally
                                                    color: _isStackHovered
                                                        ? colorScheme.surface
                                                        : null,
                                                    child:
                                                        _buildDraftPreviewContent(
                                                          book,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                });
                              }(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 64),

            // Feature Carousel (Autoscrolling)
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _features.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentFeaturePage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final feature = _features[index];
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = _pageController.page! - index;
                        value = (1 - (value.abs() * 0.2)).clamp(0.0, 1.0);
                      }
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _buildFeatureCard(
                              feature['icon'],
                              feature['title'],
                              feature['subtitle'],
                              feature['color'],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Carousel Indicators with Navigation Arrows
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 16),
                ...List.generate(_features.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentFeaturePage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentFeaturePage == index
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ],
            ),

            const SizedBox(height: 64),

            // Stats Section
            Text(
              'Your progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatMiniCard(
                    'Total Words',
                    _totalWordCount.toString(),
                    Icons.text_fields,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatMiniCard(
                    'Streak',
                    '$_currentStreak days',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatMiniCard(
                    'Projects',
                    _allBooks.length.toString(),
                    Icons.book,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Heatmap
            GlassContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Writing Activity',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  HeatMap(
                    datasets: _dailyStats,
                    colorMode: ColorMode.opacity,
                    showText: false,
                    scrollable: true,
                    colorsets: {
                      1: colorScheme.primary.withValues(alpha: 0.2),
                      500: colorScheme.primary.withValues(alpha: 0.4),
                      1000: colorScheme.primary.withValues(alpha: 0.6),
                      2000: colorScheme.primary.withValues(alpha: 0.8),
                      5000: colorScheme.primary,
                    },
                    onClick: (value) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(value.toString())));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Chart
            GlassContainer(
              height: 250,
              padding: const EdgeInsets.all(24),
              borderRadius: BorderRadius.circular(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: 16,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Word Count Trend',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Expanded(child: _buildLineChart()),
                ],
              ),
            ),

            const SizedBox(height: 64),

            // Recent Drafts
            Text(
              'Recent drafts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: _recentBooks
                  .map((book) => _buildRecentDraftCard(book))
                  .toList(),
            ),

            const SizedBox(height: 32),

            // Start New Draft FAB-like Button
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NewBookScreen(),
                    ),
                  ).then((_) => _loadData());
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GlassContainer(
                    color: colorScheme.primary,
                    opacity: 0.3,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_note, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Start new draft',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElevatedButton(
    String label,
    bool isPrimary, {
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GlassContainer(
          color: isPrimary ? colorScheme.primary : colorScheme.surface,
          opacity: isPrimary ? 0.3 : 0.1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          borderRadius: BorderRadius.circular(32),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTag(String label) {
    return GlassContainer(
      opacity: 0.1,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      borderRadius: BorderRadius.circular(8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    IconData icon,
    String title,
    String subtitle,
    Color accentColor,
  ) {
    return SizedBox(
      width: double.infinity,
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDraftCard(Book book) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(book: book),
            ),
          ).then((_) => _loadData());
        },
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(24),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.book, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Last updated ${_formatDate(book.updatedAt)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Edit',
                    onPressed: () {
                      // Navigate to edit
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookDetailScreen(book: book),
                        ),
                      ).then((_) => _loadData());
                    },
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Delete',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Draft?'),
                          content: Text(
                            'Are you sure you want to delete "${book.title}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await DatabaseService.deleteBook(book.id);
                        _loadData();
                      }
                    },
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraftPreviewContent(Book book) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                book.documentType == DocumentType.scp
                    ? Icons.fingerprint
                    : Icons.menu_book,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  book.documentType == DocumentType.scp ? 'SCP' : 'Draft',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 6,
            width: 80,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'By ${book.author}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${book.chapters.length} Ch',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
              Icon(
                Icons.arrow_forward,
                size: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeCard({
    required Offset offset,
    required double opacity,
    bool isMain = false,
  }) {
    return Transform.translate(
      offset: offset,
      child: GlassContainer(
        width: 200,
        height: 260,
        borderRadius: BorderRadius.circular(32),
        opacity: opacity,
        child: isMain ? _buildDecorativeContent() : null,
      ),
    );
  }

  Widget _buildDecorativeContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Draft',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 8, width: 100, color: Colors.white12),
          const SizedBox(height: 8),
          Container(
            height: 16,
            width: 140,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 8, width: 120, color: Colors.white12),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 20,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 20,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMiniCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    if (_dailyStats.isEmpty) {
      return const Center(child: Text('No writing data yet'));
    }

    final sortedDates = _dailyStats.keys.toList()..sort();
    final spots = <FlSpot>[];

    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), _dailyStats[sortedDates[i]]!.toDouble()));
    }

    // Only show last 7 days of activity in the chart for clarity
    final displaySpots = spots.length > 7
        ? spots.sublist(spots.length - 7)
        : spots;
    // Normalized X for the sublist
    final normalizedSpots = <FlSpot>[];
    for (int i = 0; i < displaySpots.length; i++) {
      normalizedSpots.add(FlSpot(i.toDouble(), displaySpots[i].y));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: normalizedSpots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildCreditsSection(
    BuildContext context,
    String title,
    String content,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.5,
              color: colorScheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
