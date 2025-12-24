import '../models/book.dart';
import '../models/chapter.dart';
import '../models/search_result.dart';
import 'database_service.dart';

class SearchService {
  /// Search across all books and chapters
  static Future<List<SearchResult>> searchAllBooks(String query) async {
    if (query.trim().isEmpty) return [];

    final books = await DatabaseService.getAllBooks();
    final results = <SearchResult>[];

    for (final book in books) {
      final bookResults = await searchInBook(book, query);
      results.addAll(bookResults);
    }

    return results;
  }

  /// Search within a specific book
  static Future<List<SearchResult>> searchInBook(
    Book book,
    String query,
  ) async {
    if (query.trim().isEmpty) return [];

    final results = <SearchResult>[];
    final lowercaseQuery = query.toLowerCase();

    for (final chapter in book.chapters) {
      final chapterResults = _searchInChapter(
        book.id,
        book.title,
        chapter,
        lowercaseQuery,
      );
      results.addAll(chapterResults);
    }

    return results;
  }

  /// Search within a specific chapter
  static List<SearchResult> _searchInChapter(
    String bookId,
    String bookTitle,
    Chapter chapter,
    String query,
  ) {
    final results = <SearchResult>[];
    final content = chapter.content.toLowerCase();
    final originalContent = chapter.content;

    int position = 0;
    while (true) {
      position = content.indexOf(query, position);
      if (position == -1) break;

      // Extract snippet (50 chars before and after)
      final snippetStart = (position - 50).clamp(0, content.length);
      final snippetEnd = (position + query.length + 50).clamp(
        0,
        originalContent.length,
      );
      String snippet = originalContent.substring(snippetStart, snippetEnd);

      // Add ellipsis if needed
      if (snippetStart > 0) snippet = '...$snippet';
      if (snippetEnd < originalContent.length) snippet = '$snippet...';

      results.add(
        SearchResult(
          bookId: bookId,
          bookTitle: bookTitle,
          chapterId: chapter.id,
          chapterTitle: chapter.title,
          snippet: snippet,
          position: position,
        ),
      );

      position += query.length;
    }

    return results;
  }
}
