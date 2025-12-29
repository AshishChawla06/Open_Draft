import '../models/book.dart';
import '../services/database_service.dart';

class StatsService {
  /// Gets the total word count across all books.
  static int getTotalWordCount(List<Book> books) {
    int total = 0;
    for (var book in books) {
      for (var chapter in book.chapters) {
        total += _calculateWordCount(chapter.content);
      }
    }
    return total;
  }

  /// Gets the word count for a specific book.
  static int getBookWordCount(Book book) {
    int total = 0;
    for (var chapter in book.chapters) {
      total += _calculateWordCount(chapter.content);
    }
    return total;
  }

  /// Calculates the current writing streak in days.
  static Future<int> getCurrentStreak() async {
    final stats = await DatabaseService.getDailyStats();
    if (stats.isEmpty) return 0;

    final sortedDates = stats.keys.toList()..sort((a, b) => b.compareTo(a));

    DateTime today = DateTime.now();
    DateTime checkDate = DateTime(today.year, today.month, today.day);

    int streak = 0;

    // Check if there's activity today or yesterday to continue the streak
    bool activeRecently = false;
    for (var date in sortedDates) {
      DateTime d = DateTime(date.year, date.month, date.day);
      if (d.isAtSameMomentAs(checkDate) ||
          d.isAtSameMomentAs(checkDate.subtract(const Duration(days: 1)))) {
        activeRecently = true;
        break;
      }
    }

    if (!activeRecently) return 0;

    for (int i = 0; i < 365; i++) {
      DateTime d = checkDate.subtract(Duration(days: i));
      bool found = false;
      for (var date in sortedDates) {
        DateTime sd = DateTime(date.year, date.month, date.day);
        if (sd.isAtSameMomentAs(d)) {
          found = true;
          break;
        }
      }

      if (found) {
        streak++;
      } else {
        // If we didn't find activity for today but did for yesterday, streak continues.
        // If we didn't find activity for today and it's index 0, check yesterday.
        if (i == 0) continue;
        break;
      }
    }

    return streak;
  }

  /// Gets the average words per day based on active days.
  static Future<double> getAverageWordsPerActiveDay() async {
    final stats = await DatabaseService.getDailyStats();
    if (stats.isEmpty) return 0;

    int totalWords = 0;
    stats.forEach((_, count) => totalWords += count);

    return totalWords / stats.length;
  }

  static int _calculateWordCount(String content) {
    if (content.trim().isEmpty) return 0;
    // Simple word count fallback
    return content
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
  }
}
