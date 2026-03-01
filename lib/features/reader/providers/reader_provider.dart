import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/chapter_repository.dart';
import '../domain/models/chapter.dart';

final chapterRepositoryProvider = Provider<ChapterRepository>((ref) {
  return ChapterRepository(Supabase.instance.client);
});

// A family provider that takes (bookId, chapterNumber) and returns the specific chapter data.
// We use a simple class or record to hold the parameters.
class ChapterRequest {
  final String bookId;
  final int chapterNumber;
  ChapterRequest({required this.bookId, required this.chapterNumber});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterRequest &&
          runtimeType == other.runtimeType &&
          bookId == other.bookId &&
          chapterNumber == other.chapterNumber;

  @override
  int get hashCode => bookId.hashCode ^ chapterNumber.hashCode;
}

final chapterProvider = FutureProvider.family<Chapter?, ChapterRequest>((ref, request) async {
  final repository = ref.watch(chapterRepositoryProvider);
  return repository.getChapter(request.bookId, request.chapterNumber);
});
