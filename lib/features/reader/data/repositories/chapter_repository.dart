import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../domain/models/chapter.dart';

class ChapterRepository {
  final supa.SupabaseClient _client;

  ChapterRepository(this._client);

  Future<Chapter?> getChapter(String bookId, int chapterNumber) async {
    try {
      final response = await _client
          .from('chapters')
          .select()
          .eq('book_id', bookId)
          .eq('chapter_number', chapterNumber)
          .maybeSingle();

      if (response == null) {
        // Mock fallback for testing
        if (bookId == 'mock_book_1') {
          return const Chapter(
            id: 'mock_chapter_1',
            bookId: 'mock_book_1',
            chapterNumber: 1,
            title: 'Chapter 1: The Pilot',
            content: 'Once when I was six years old I saw a magnificent picture in a book, called True Stories from Nature, about the primeval forest. It was a picture of a boa constrictor in the act of swallowing an animal. Here is a copy of the drawing.\n\nIn the book it said: "Boa constrictors swallow their prey whole, without chewing it. After that they are not able to move, and they sleep through the six months that they need for digestion."\n\nI pondered deeply, then, over the adventures of the jungle. And after some work with a colored pencil I succeeded in making my first drawing. My Drawing Number One. It looked like this:\n\nI showed my masterpiece to the grown-ups, and asked them whether the drawing frightened them. But they answered: "Frighten? Why should any one be frightened by a hat?"\n\nMy drawing was not a picture of a hat. It was a picture of a boa constrictor digesting an elephant. But since the grown-ups were not able to understand it, I made another drawing: I drew the inside of the boa constrictor, so that the grown-ups could see it clearly. They always need to have things explained. My Drawing Number Two looked like this:\n\nThe grown-ups\' response, this time, was to advise me to lay aside my drawings of boa constrictors, whether from the inside or the outside, and devote myself instead to geography, history, arithmetic and grammar. That is why, at the age of six, I gave up what might have been a magnificent career as a painter. I had been disheartened by the failure of my Drawing Number One and my Drawing Number Two. Grown-ups never understand anything by themselves, and it is tiresome for children to be always and forever explaining things to them.',
            wordCount: 250,
          );
        }
        return null;
      }
      return Chapter.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch chapter: $e');
    }
  }

  Future<List<Chapter>> getChaptersForBook(String bookId) async {
    try {
      final response = await _client
          .from('chapters')
          .select('id, book_id, chapter_number, title, word_count')
          .eq('book_id', bookId)
          .order('chapter_number', ascending: true);
      return (response as List<dynamic>).map((json) => Chapter.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch chapters: $e');
    }
  }
}
