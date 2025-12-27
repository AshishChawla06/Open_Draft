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
    // Sort by updated date descending and take top 3
    books.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (mounted) {
      setState(() {
        _recentBooks = books.take(3).toList();
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
                  icon: const Icon(Icons.person_outline),
                  onPressed: () {
                    // Profile/Account placeholder
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
                // Interactive Drafts Stack
                SizedBox(
                  width: 300,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isStackHovered = true),
                    onExit: (_) => setState(() => _isStackHovered = false),
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
                            ..._recentBooks
                                .take(3)
                                .toList()
                                .asMap()
                                .entries
                                .map((entry) {
                                  final index = entry.key;
                                  final book = entry.value;
                                  // 0 = Top, 1 = Middle, 2 = Bottom (visually)
                                  // But we render in reverse order of index likely, or z-index needs management.
                                  // Actually, we want index 0 on TOP. So standard map order puts 0 at bottom of stack in Flutter Stack?
                                  // No, first child is bottom-most.
                                  // So we need to reverse the list OR manage z-indexes.
                                  // Let's iterate normally but calculate transforms based on visual stack order.
                                  // We want index 0 (Most recent) on TOP. So it should be LAST in the children list.
                                  return MapEntry(index, book);
                                })
                                .toList()
                                .reversed // Reverse so index 0 is drawn LAST (Top)
                                .map((entry) {
                                  final index = entry.key; // 0, 1, 2
                                  final book = entry.value;

                                  // Calculate target transform based on hover
                                  double xOffset = 0;
                                  double yOffset = 0;
                                  double rotation = 0;
                                  double scale =
                                      1.0 -
                                      (index * 0.05); // Standard scale down
                                  double opacity =
                                      1.0 - (index * 0.2); // Faded deeper cards

                                  if (_isStackHovered) {
                                    // Fan out horizontally
                                    // Index 0 (Top): Center
                                    // Index 1: Left
                                    // Index 2: Right
                                    if (index == 0) {
                                      // Top card moves up slightly
                                      yOffset = -20;
                                      scale = 1.05;
                                      opacity = 1.0;
                                    } else if (index == 1) {
                                      // Second card moves left
                                      xOffset = -180; // Increased spacing
                                      rotation = -0.05; // Reduced rotation
                                      opacity = 1.0;
                                      scale = 1.0;
                                    } else if (index == 2) {
                                      // Third card moves right
                                      xOffset = 180; // Increased spacing
                                      rotation = 0.05; // Reduced rotation
                                      opacity = 1.0;
                                      scale = 1.0;
                                    }
                                  } else {
                                    // Stacked state
                                    // Index 0: (0,0)
                                    // Index 1: (10, 10)
                                    // Index 2: (20, 20)
                                    xOffset = index * 10.0;
                                    yOffset = index * 10.0;
                                  }

                                  return AnimatedPositioned(
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
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        BookDetailScreen(
                                                          book: book,
                                                        ), // Open details
                                                  ),
                                                ).then((_) => _loadData());
                                              },
                                              child: MouseRegion(
                                                cursor: _isStackHovered
                                                    ? SystemMouseCursors.click
                                                    : SystemMouseCursors.basic,
                                                child: GlassContainer(
                                                  width: 200,
                                                  height: 280,
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  opacity: opacity * 0.2,
                                                  // Enhance opacity for readability when hovered
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
                                  );
                                }),
                        ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
