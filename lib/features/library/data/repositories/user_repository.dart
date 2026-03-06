import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../domain/models/user_progress.dart';

class UserRepository {
  final supa.SupabaseClient _client;

  UserRepository(this._client);

  Future<UserProgress> getUserProgress(String userId) async {
    try {
      final response = await _client
          .from('user_progress')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Return default progress if no record exists yet
        return const UserProgress();
      }

      return UserProgress(
        consecutiveDays: response['consecutive_days'] as int? ?? 0,
        totalWordsRead: response['total_words_read'] as int? ?? 0,
        booksCompleted: response['books_completed'] as int? ?? 0,
        currentBookChaptersRead: 0, // This will be calculated from user_book_progress later
      );
    } catch (e) {
      // Fallback for errors
      return const UserProgress();
    }
  }

  // Optionally create default progress when user signs up
  Future<void> initializeUserProgress(String userId) async {
    await _client.from('user_progress').upsert({
      'user_id': userId,
      'consecutive_days': 0,
      'total_words_read': 0,
      'books_completed': 0,
      'last_read_date': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }

  // Update progress after completing a chapter
  Future<void> markChapterCompleted({
    required String userId,
    required String bookId,
    required int chapterNumber,
    required int wordCount,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      
      // 1. Update user_book_progress
      await _client.from('user_book_progress').upsert(
        {
          'user_id': userId,
          'book_id': bookId,
          'current_chapter_number': chapterNumber + 1, // Move to next chapter
          'last_read_at': now,
        },
        onConflict: 'user_id, book_id',
      );

      // 2. Fetch existing global progress to update word count and streak
      final progress = await getUserProgress(userId);
      
      // Calculate consecutive days
      int newConsecutiveDays = progress.consecutiveDays;
      final response = await _client
          .from('user_progress')
          .select('last_read_date')
          .eq('user_id', userId)
          .maybeSingle();
          
      if (response != null && response['last_read_date'] != null) {
        final lastReadDate = DateTime.parse(response['last_read_date'] as String);
        final today = DateTime.now();
        final difference = DateTime(today.year, today.month, today.day)
            .difference(DateTime(lastReadDate.year, lastReadDate.month, lastReadDate.day))
            .inDays;
            
        if (difference == 1) {
          newConsecutiveDays++; // Read yesterday and today
        } else if (difference > 1) {
          newConsecutiveDays = 1; // Streak broken
        }
        // If difference == 0, already read today, keep current streak
      } else {
        newConsecutiveDays = 1; // First day reading
      }

      // 3. Update global user_progress
      await _client.from('user_progress').upsert(
        {
          'user_id': userId,
          'consecutive_days': newConsecutiveDays,
          'total_words_read': progress.totalWordsRead + wordCount,
          'last_read_date': now,
          'updated_at': now,
        },
        onConflict: 'user_id',
      );
      
    } catch (e) {
      print('Error updating progress: $e');
      rethrow;
    }
  }
}
