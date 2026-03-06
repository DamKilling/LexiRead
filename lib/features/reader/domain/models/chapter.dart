import '../../controllers/audio_sync_controller.dart';
class Chapter {
  final String id;
  final String bookId;
  final int chapterNumber;
  final String title;
  final String content;
  final String? audioUrl;
  final List<AudioTimestamp>? audioTimestamps;
  final int wordCount;

  const Chapter({
    required this.id,
    required this.bookId,
    required this.chapterNumber,
    required this.title,
    required this.content,
    this.audioUrl,
    this.audioTimestamps,
    this.wordCount = 0,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String,
      bookId: json['book_id'] as String,
      chapterNumber: json['chapter_number'] as int,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      audioUrl: json['audio_url'] as String?,
      audioTimestamps: (json['audio_timestamps'] as List<dynamic>?)
          ?.map((e) => AudioTimestamp.fromJson(e as Map<String, dynamic>))
          .toList(),
      wordCount: json['word_count'] as int? ?? 0,
    );
  }
}
