class SearchResult {
  final String bookId;
  final String bookTitle;
  final String chapterId;
  final String chapterTitle;
  final String snippet;
  final int position;

  SearchResult({
    required this.bookId,
    required this.bookTitle,
    required this.chapterId,
    required this.chapterTitle,
    required this.snippet,
    required this.position,
  });
}
