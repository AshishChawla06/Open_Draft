import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_background.dart';
import '../widgets/logo_header.dart';
import '../services/database_service.dart';
import '../enums/sort_option.dart';
import '../enums/view_layout.dart';
import '../models/document_type.dart';
import '../widgets/document_type_badge.dart';
import 'book_detail_screen.dart';
import 'new_book_screen.dart';
import 'dashboard_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'templates_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Book? selectedBook;
  SortOption _sortOption = SortOption.dateUpdated;
  ViewLayout _viewLayout = ViewLayout.largeGrid;
  List<Book> _books = [];
  DocumentType? _documentTypeFilter; // null = show all
  String? _tagFilter; // null = show all
  // ignore: unused_field
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadBooks();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final sortIndex =
          prefs.getInt('sortOption') ?? SortOption.dateUpdated.index;
      _sortOption = SortOption.values[sortIndex];

      final layoutIndex =
          prefs.getInt('viewLayout') ?? ViewLayout.largeGrid.index;
      _viewLayout = ViewLayout.values[layoutIndex];
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sortOption', _sortOption.index);
    await prefs.setInt('viewLayout', _viewLayout.index);
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    // Load books from database (handles both web and mobile)
    final books = await DatabaseService.getAllBooks();
    setState(() {
      _books = books;
      _isLoading = false;
    });
  }

  List<Book> get _sortedBooks {
    // Filter by document type first
    var books = _documentTypeFilter == null
        ? List<Book>.from(_books)
        : _books
              .where((book) => book.documentType == _documentTypeFilter)
              .toList();

    // Then filter by tag if selected
    if (_tagFilter != null) {
      books = books.where((book) => book.tags.contains(_tagFilter)).toList();
    }

    // Then sort
    switch (_sortOption) {
      case SortOption.title:
        books.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.author:
        books.sort((a, b) => a.author.compareTo(b.author));
        break;
      case SortOption.dateCreated:
        books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.dateUpdated:
        books.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }
    return books;
  }

  // Get all unique tags from all books
  List<String> get _allTags {
    final tags = <String>{};
    for (final book in _books) {
      tags.addAll(book.tags);
    }
    return tags.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final books = _sortedBooks;
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return GlassBackground(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            if (isWideScreen)
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.8),
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.folder_outlined),
                    selectedIcon: Icon(Icons.folder),
                    label: Text('Projects'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_customize_outlined),
                    selectedIcon: Icon(Icons.dashboard_customize),
                    label: Text('Templates'),
                  ),
                ],
              ),
            if (isWideScreen) const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: _selectedIndex == 0
                  ? const DashboardScreen()
                  : (_selectedIndex == 1
                        ? (isWideScreen
                              ? _buildProjectsDesktopLayout(books)
                              : _buildProjectsMobileLayout(books))
                        : const TemplatesScreen()),
            ),
          ],
        ),
        bottomNavigationBar: !isWideScreen
            ? NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) =>
                    setState(() => _selectedIndex = index),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.folder_outlined),
                    selectedIcon: Icon(Icons.folder),
                    label: 'Projects',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_customize_outlined),
                    selectedIcon: Icon(Icons.dashboard_customize),
                    label: 'Templates',
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildProjectsDesktopLayout(List<Book> books) =>
      _buildProjectsContent(books, true);

  Widget _buildProjectsMobileLayout(List<Book> books) =>
      _buildProjectsContent(books, false);

  Widget _buildProjectsContent(List<Book> books, bool isWideScreen) {
    return CustomScrollView(
      slivers: [
        if (isWideScreen)
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            pinned: true,
            automaticallyImplyLeading: false,
            title: const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: LogoHeader(size: 30, showText: true),
            ),
            actions: [
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
                tooltip: 'Search',
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                tooltip: 'Settings',
              ),
              const SizedBox(width: 16),
            ],
            flexibleSpace: GlassContainer(
              borderRadius: BorderRadius.zero,
              blur: 20,
              opacity: 0.2,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (!isWideScreen)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 64, bottom: 32),
              child: const LogoHeader(),
            ),
          ),
        if (!isWideScreen)
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            pinned: true,
            title: Text(
              'Projects',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            flexibleSpace: GlassContainer(
              borderRadius: BorderRadius.zero,
              blur: 20,
              opacity: 0.2,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildControls(),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            16,
            isWideScreen
                ? 16
                : 16, // Reduced top padding for desktop as it's not overlapping
            16,
            16,
          ),
          sliver: _viewLayout == ViewLayout.list
              ? SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == books.length) {
                      return _buildNewBookCard();
                    }
                    return _buildListBookCard(books[index]);
                  }, childCount: books.length + 1),
                )
              : SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(isWideScreen),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: _getChildAspectRatio(),
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == books.length) {
                      return _buildNewBookCard();
                    }
                    return _buildBookCard(books[index]);
                  }, childCount: books.length + 1),
                ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      children: [
        // Document Type Filter
        Expanded(
          flex: 2,
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            borderRadius: BorderRadius.circular(16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DocumentType?>(
                value: _documentTypeFilter,
                hint: const Text('All Documents'),
                isExpanded: true,
                icon: Icon(
                  Icons.filter_list,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                items: [
                  const DropdownMenuItem<DocumentType?>(
                    value: null,
                    child: Text('All Documents'),
                  ),
                  DropdownMenuItem(
                    value: DocumentType.novel,
                    child: Row(
                      children: [
                        Icon(
                          Icons.book_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text('Novel Writer'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: DocumentType.scp,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Color(0xFFFF4444),
                        ),
                        const SizedBox(width: 8),
                        const Text('SCP Writer'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _documentTypeFilter = value);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Sort Option
        Expanded(
          flex: 2,
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            borderRadius: BorderRadius.circular(16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SortOption>(
                value: _sortOption,
                isExpanded: true,
                icon: Icon(
                  Icons.sort,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                items: SortOption.values.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(
                      option.displayName,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortOption = value);
                    _savePreferences();
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Tag Filter
        if (_allTags.isNotEmpty)
          SizedBox(
            width: 150,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: BorderRadius.circular(16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _tagFilter,
                  hint: const Text('All Tags'),
                  isExpanded: true,
                  icon: const Icon(Icons.label_outline, size: 20),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Tags'),
                    ),
                    ..._allTags.map(
                      (tag) => DropdownMenuItem(value: tag, child: Text(tag)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _tagFilter = value);
                  },
                ),
              ),
            ),
          ),
        const SizedBox(width: 8),
        _buildLayoutToggle(ViewLayout.smallGrid, Icons.grid_on),
        _buildLayoutToggle(ViewLayout.largeGrid, Icons.grid_view),
        _buildLayoutToggle(ViewLayout.list, Icons.view_list),
      ],
    );
  }

  Widget _buildLayoutToggle(ViewLayout layout, IconData icon) {
    final isSelected = _viewLayout == layout;
    return IconButton(
      onPressed: () {
        setState(() => _viewLayout = layout);
        _savePreferences();
      },
      icon: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      tooltip: layout.name,
      style: IconButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
      ),
    );
  }

  int _getCrossAxisCount(bool isWideScreen) {
    if (_viewLayout == ViewLayout.smallGrid) {
      return isWideScreen ? 4 : 3;
    }
    return isWideScreen ? 3 : 2;
  }

  double _getChildAspectRatio() {
    if (_viewLayout == ViewLayout.smallGrid) {
      return 0.6;
    }
    return 0.65;
  }

  Widget _buildListBookCard(Book book) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
        ).then((_) => _loadBooks());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: GlassContainer(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surface,
          opacity: 0.1,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: book.coverUrl != null
                    ? (kIsWeb
                          ? Image.network(
                              book.coverUrl!,
                              width: 60,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildFallbackCover(width: 60, height: 90),
                            )
                          : Image.file(
                              File(book.coverUrl!),
                              width: 60,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildFallbackCover(width: 60, height: 90),
                            ))
                    : _buildFallbackCover(width: 60, height: 90),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${book.author}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.article,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${book.chapters.length} chapters',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(book.updatedAt),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackCover({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: Center(
        child: Icon(
          Icons.book,
          color: Theme.of(context).colorScheme.primary,
          size: (width ?? 100) * 0.5,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildBookCard(Book book) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
        ).then((_) => _loadBooks());
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Hero(
                  tag: 'book-cover-${book.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: book.coverUrl != null
                        ? (kIsWeb
                              ? Image.network(
                                  book.coverUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildFallbackCover(),
                                )
                              : Image.file(
                                  File(book.coverUrl!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildFallbackCover(),
                                ))
                        : _buildFallbackCover(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              book.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              book.author,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DocumentTypeBadge(documentType: book.documentType),
                Text(
                  '${book.chapters.length} chs',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewBookCard() {
    final isSCPMode = _documentTypeFilter == DocumentType.scp;
    final isNovelMode = _documentTypeFilter == DocumentType.novel;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewBookScreen(
              documentType: isSCPMode
                  ? DocumentType.scp
                  : (isNovelMode ? DocumentType.novel : DocumentType.novel),
            ),
          ),
        );
        _loadBooks();
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        color: isSCPMode
            ? const Color(0xFF1A1A1A)
            : Theme.of(context).colorScheme.primaryContainer,
        opacity: 0.2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSCPMode
                  ? Icons.warning_amber_rounded
                  : Icons.add_circle_outline,
              size: 64,
              color: isSCPMode
                  ? const Color(0xFFFF4444)
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              isSCPMode ? 'New SCP Article' : 'New Book',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSCPMode
                    ? const Color(0xFFFF4444)
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
