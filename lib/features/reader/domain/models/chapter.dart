class Chapter {
  final String id;
  final String bookId;
  final int chapterNumber;
  final String title;
  final String content;
  final String? audioUrl;
  final int wordCount;

  const Chapter({
    required this.id,
    required this.bookId,
    required this.chapterNumber,
    required this.title,
    required this.content,
    this.audioUrl,
    this.wordCount = 0,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String,
      bookId: json['book_id'] as String,
      chapterNumber: json['chapter_number'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      audioUrl: json['audio_url'] as String?,
      wordCount: json['word_count'] as int? ?? 0,
    );
  }
}
