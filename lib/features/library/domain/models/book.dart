class Book {
  final String id;
  final String title;
  final String coverUrl;
  final String author;
  final String difficultyLevel;
  final int totalChapters;
  final String description;
  final String? categoryRaw;

  const Book({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.author,
    required this.difficultyLevel,
    required this.totalChapters,
    required this.description,
    this.categoryRaw,
  });

  String get displayCategory {
    if (categoryRaw != null && categoryRaw!.isNotEmpty) return categoryRaw!;
    final descLower = description.toLowerCase();
    if (descLower.contains('science fiction') || descLower.contains('sci-fi')) return 'Sci-Fi';
    if (descLower.contains('fantasy')) return 'Fantasy';
    if (descLower.contains('mystery')) return 'Mystery';
    if (descLower.contains('horror') || descLower.contains('gothic') || descLower.contains('vampire') || descLower.contains('dracula')) return 'Horror';
    if (descLower.contains('romance') || descLower.contains('love')) return 'Romance';
    if (descLower.contains('adventure')) return 'Adventure';
    if (descLower.contains('classic')) return 'Classic';
    return 'Other';
  }
}
