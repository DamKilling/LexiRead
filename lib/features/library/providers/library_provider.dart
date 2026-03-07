import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/repositories/book_repository.dart';
import '../data/repositories/user_repository.dart';
import '../domain/models/book.dart';
import '../domain/models/user_progress.dart';
import '../../reader/providers/reading_progress_provider.dart';
// --- Repositories ---

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepository(Supabase.instance.client);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(Supabase.instance.client);
});

// --- Async Data Providers ---

final libraryBooksProvider = FutureProvider<List<Book>>((ref) async {
  final repository = ref.watch(bookRepositoryProvider);
  return repository.getBooks();
});

final userProgressProvider = FutureProvider<UserProgress>((ref) async {
  final authState = ref.watch(authStateChangesProvider).value;
  final userId = authState?.session?.user.id;

  if (userId == null) return const UserProgress();

  final repository = ref.watch(userRepositoryProvider);
  return repository.getUserProgress(userId);
});

enum ReadingStatus { all, notStarted, reading, finished }

final bookProgressMapProvider = FutureProvider<Map<String, int>>((ref) async {
  // Just read from the same source as ReadingProgressNotifier
  final progressNotifier = ref.read(readingProgressProvider.notifier);
  final prefs = await progressNotifier.getPrefs();
  
  final Map<String, int> progressMap = {};
  final keys = prefs.getKeys();
  for (final key in keys) {
    if (key.startsWith('lastReadChapter_')) {
      final bookId = key.substring('lastReadChapter_'.length);
      progressMap[bookId] = prefs.getInt(key) ?? 1;
    }
  }
  return progressMap;
});

class LibraryFilterState {
  final String category;
  final String difficulty;
  final ReadingStatus status;
  final String searchQuery;

  const LibraryFilterState({
    this.category = 'All',
    this.difficulty = 'All',
    this.status = ReadingStatus.all,
    this.searchQuery = '',
  });

  LibraryFilterState copyWith({
    String? category,
    String? difficulty,
    ReadingStatus? status,
    String? searchQuery,
  }) {
    return LibraryFilterState(
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class LibraryFilterNotifier extends StateNotifier<LibraryFilterState> {
  LibraryFilterNotifier() : super(const LibraryFilterState());

  void setCategory(String category) => state = state.copyWith(category: category);
  void setDifficulty(String difficulty) => state = state.copyWith(difficulty: difficulty);
  void setStatus(ReadingStatus status) => state = state.copyWith(status: status);
  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);
  void reset() => state = const LibraryFilterState();
}

final libraryFilterProvider = StateNotifierProvider<LibraryFilterNotifier, LibraryFilterState>((ref) {
  return LibraryFilterNotifier();
});

final filteredBooksProvider = FutureProvider<List<Book>>((ref) async {
  final allBooks = await ref.watch(libraryBooksProvider.future);
  final filter = ref.watch(libraryFilterProvider);
  final progressMap = await ref.watch(bookProgressMapProvider.future);

  return allBooks.where((book) {
    // Search Query Filter
    if (filter.searchQuery.isNotEmpty) {
      final query = filter.searchQuery.toLowerCase();
      if (!book.title.toLowerCase().contains(query) &&
          !book.author.toLowerCase().contains(query)) {
        return false;
      }
    }
    // Category Filter
    if (filter.category != 'All') {
      if (book.displayCategory != filter.category) return false;
    }
    // Difficulty Filter
    if (filter.difficulty != 'All') {
      if (book.difficultyLevel != filter.difficulty) return false;
    }
    // Reading Status Filter
    if (filter.status != ReadingStatus.all) {
      final currentChapter = progressMap[book.id];
      final isNotStarted = currentChapter == null || currentChapter <= 1;
      final isFinished = currentChapter != null && currentChapter >= book.totalChapters && book.totalChapters > 1;
      final isReading = !isNotStarted && !isFinished;

      if (filter.status == ReadingStatus.notStarted && !isNotStarted) return false;
      if (filter.status == ReadingStatus.reading && !isReading) return false;
      if (filter.status == ReadingStatus.finished && !isFinished) return false;
    }
    return true;
  }).toList();
});

// Which book is currently being read
final currentReadingBookProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final books = await ref.watch(libraryBooksProvider.future);
  if (books.isEmpty) return null;

  final progressNotifier = ref.read(readingProgressProvider.notifier);
  final lastBookId = await progressNotifier.getLastReadBookId();
  
  Book? targetBook;
  int targetChapter = 1;

  if (lastBookId != null) {
    try {
      targetBook = books.firstWhere((b) => b.id == lastBookId);
      final chapter = await progressNotifier.getLastReadChapter(lastBookId);
      if (chapter != null) {
        targetChapter = chapter;
      }
    } catch (e) {
      // Book not found in library anymore
      targetBook = books.first;
    }
  } else {
    targetBook = books.first;
  }

  return {
    'book': targetBook,
    'chapter': targetChapter,
  };
});
