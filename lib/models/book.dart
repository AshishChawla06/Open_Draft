import 'chapter.dart';
import 'document_type.dart';
import 'scp_metadata.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String? description;
  final String? coverUrl;
  final List<Chapter> chapters;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DocumentType documentType;
  final SCPMetadata? scpMetadata;
  final int? themeColor;
  final List<String> tags;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.coverUrl,
    required this.chapters,
    required this.createdAt,
    required this.updatedAt,
    this.documentType = DocumentType.novel,
    this.scpMetadata,
    this.themeColor,
    this.tags = const [],
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? coverUrl,
    List<Chapter>? chapters,
    DateTime? createdAt,
    DateTime? updatedAt,
    DocumentType? documentType,
    SCPMetadata? scpMetadata,
    int? themeColor,
    List<String>? tags,
    bool clearCover = false,
    bool clearDescription = false,
    bool clearScpMetadata = false,
    bool clearThemeColor = false,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: clearDescription ? null : (description ?? this.description),
      coverUrl: clearCover ? null : (coverUrl ?? this.coverUrl),
      chapters: chapters ?? this.chapters,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      documentType: documentType ?? this.documentType,
      scpMetadata: clearScpMetadata ? null : (scpMetadata ?? this.scpMetadata),
      themeColor: clearThemeColor ? null : (themeColor ?? this.themeColor),
      tags: tags ?? this.tags,
    );
  }

  // Mock data generator
  static List<Book> getMockBooks() {
    return [
      Book(
        id: 'book_1',
        title: 'The Glass Chronicles',
        author: 'Alexandria Reed',
        description: 'A tale of mystery and wonder in a world made of glass.',
        chapters: [
          Chapter(
            id: 'ch_1_1',
            title: 'The Beginning',
            content:
                'Once upon a time in a land of glass, there lived a young girl named Aria. She had always been fascinated by the way light danced through the crystalline structures of her world...\n\nThe city of Vitrea stretched before her, its towers gleaming in the morning sun. Each building was a masterpiece of transparent architecture, reflecting and refracting light in ways that created ever-changing patterns across the streets.',
            order: 1,
            createdAt: DateTime.now().subtract(const Duration(days: 10)),
            updatedAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          Chapter(
            id: 'ch_1_2',
            title: 'The Discovery',
            content:
                'Aria\'s discovery would change everything. Deep in the archives of the Glass Library, she found an ancient manuscript that spoke of a time before the glass...\n\nThe pages were fragile, nearly transparent themselves, and the words seemed to shimmer as she read them. They told of a world of stone and wood, of materials that didn\'t let light pass through.',
            order: 2,
            createdAt: DateTime.now().subtract(const Duration(days: 8)),
            updatedAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
          Chapter(
            id: 'ch_1_3',
            title: 'The Journey Begins',
            content:
                'With the manuscript in hand, Aria set out on a journey to uncover the truth about her world\'s origins...\n\nShe packed light—a few changes of clothes, some provisions, and the precious manuscript wrapped carefully in silk. The road ahead was uncertain, but her determination was as clear as the glass beneath her feet.',
            order: 3,
            createdAt: DateTime.now().subtract(const Duration(days: 6)),
            updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Book(
        id: 'book_2',
        title: 'Shadows of Tomorrow',
        author: 'Marcus Chen',
        description: 'A sci-fi thriller set in a dystopian future.',
        chapters: [
          Chapter(
            id: 'ch_2_1',
            title: 'Awakening',
            content:
                'The year is 2157. Humanity has evolved, but not in the way anyone expected...\n\nDr. Sarah Kim opened her eyes to a world bathed in artificial light. The underground city of New Haven hummed with the sound of machinery and the whispers of ten million souls who had never seen the sun.',
            order: 1,
            createdAt: DateTime.now().subtract(const Duration(days: 15)),
            updatedAt: DateTime.now().subtract(const Duration(days: 7)),
          ),
          Chapter(
            id: 'ch_2_2',
            title: 'The Resistance',
            content:
                'Not everyone accepted the new order. In the shadows, a resistance was forming...\n\nSarah had heard the rumors, whispers of people who remembered the surface, who refused to forget what had been lost. She never imagined she would become one of them.',
            order: 2,
            createdAt: DateTime.now().subtract(const Duration(days: 12)),
            updatedAt: DateTime.now().subtract(const Duration(days: 4)),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      Book(
        id: 'book_3',
        title: 'Whispers in the Wind',
        author: 'Elena Rossi',
        description: 'A romantic fantasy about love that transcends time.',
        chapters: [
          Chapter(
            id: 'ch_3_1',
            title: 'First Encounter',
            content:
                'Their eyes met across the crowded marketplace, and in that instant, centuries of history came flooding back...\n\nLila had always believed in reincarnation, but she never expected to recognize someone from a past life. Yet here he was, the same eyes, the same soul, in a different time.',
            order: 1,
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
            updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
