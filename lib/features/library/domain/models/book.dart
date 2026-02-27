class Book {
  final String id;
  final String title;
  final String coverUrl;
  final String author;
  final String difficultyLevel;
  final int totalChapters;
  final String description;

  const Book({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.author,
    required this.difficultyLevel,
    required this.totalChapters,
    required this.description,
  });
}
