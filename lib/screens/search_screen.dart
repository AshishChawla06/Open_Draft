import 'package:flutter/material.dart';
import '../models/search_result.dart';
import '../services/search_service.dart';
import '../services/database_service.dart';
import '../widgets/glass_container.dart';
import 'editor_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchResult> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);

    final results = await SearchService.searchAllBooks(query);

    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  Future<void> _navigateToResult(SearchResult result) async {
    // Load the full book to pass to the editor
    final books = await DatabaseService.getAllBooks();
    final book = books.firstWhere((b) => b.id == result.bookId);
    final chapter = book.chapters.firstWhere((c) => c.id == result.chapterId);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(book: book, chapter: chapter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search across all books...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                : null,
          ),
          onChanged: _performSearch,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Search across all books and chapters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "${_searchController.text}"',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    // Group results by book
    final groupedResults = <String, List<SearchResult>>{};
    for (final result in _results) {
      groupedResults.putIfAbsent(result.bookTitle, () => []).add(result);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedResults.length,
      itemBuilder: (context, index) {
        final bookTitle = groupedResults.keys.elementAt(index);
        final bookResults = groupedResults[bookTitle]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                bookTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ...bookResults.map((result) => _buildResultTile(result)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildResultTile(SearchResult result) {
    return GestureDetector(
      onTap: () => _navigateToResult(result),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.chapterTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _highlightQuery(result.snippet, _searchController.text),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _highlightQuery(String text, String query) {
    // Simple highlighting - in a real app you'd use RichText
    // For now, we'll just return the snippet
    return text;
  }
}
