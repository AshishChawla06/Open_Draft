class Story {
  final String id;
  final String title;
  final String content;
  final String author;
  final String? coverUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Story({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    this.coverUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Mock data generator
  static List<Story> getMockStories() {
    return List.generate(
      10,
      (index) => Story(
        id: 'story_$index',
        title: 'The Glass Chronicle ${index + 1}',
        content: 'Once upon a time in a land of glass...',
        author: 'Author ${index + 1}',
        createdAt: DateTime.now().subtract(Duration(days: index)),
        updatedAt: DateTime.now(),
      ),
    );
  }
}
