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

      if (response == null) return null;
      return Chapter.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch chapter: $e');
    }
  }

  Future<List<Chapter>> getChaptersForBook(String bookId) async {
    try {
      final response = await _client
          .from('chapters')
          .select()
          .eq('book_id', bookId)
          .order('chapter_number');

      return (response as List<dynamic>).map((json) => Chapter.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch chapters: $e');
    }
  }
}
