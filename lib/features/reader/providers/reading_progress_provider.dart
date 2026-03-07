import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final readingProgressProvider = StateNotifierProvider<ReadingProgressNotifier, void>((ref) {
  return ReadingProgressNotifier();
});

class ReadingProgressNotifier extends StateNotifier<void> {
  ReadingProgressNotifier() : super(null);

  Future<void> saveProgress(String bookId, int chapter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastReadBookId', bookId);
    await prefs.setInt('lastReadChapter_$bookId', chapter);
  }

  Future<String?> getLastReadBookId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastReadBookId');
  }

  Future<int?> getLastReadChapter(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('lastReadChapter_$bookId');
  }

  Future<SharedPreferences> getPrefs() async {
    return await SharedPreferences.getInstance();
  }
}
