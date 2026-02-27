import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/book.dart';
import '../domain/models/user_progress.dart';

// --- Mock Data ---

final _mockBooks = [
  const Book(
    id: '1',
    title: 'The Little Prince',
    author: 'Antoine de Saint-Exupéry',
    coverUrl: 'https://via.placeholder.com/150x220.png?text=Little+Prince',
    difficultyLevel: 'A2',
    totalChapters: 27,
    description: 'A pilot stranded in the desert meets a young prince fallen to Earth from a tiny asteroid.',
  ),
  const Book(
    id: '2',
    title: 'Alice in Wonderland',
    author: 'Lewis Carroll',
    coverUrl: 'https://via.placeholder.com/150x220.png?text=Alice',
    difficultyLevel: 'B1',
    totalChapters: 12,
    description: 'A young girl falls through a rabbit hole into a fantasy world.',
  ),
  const Book(
    id: '3',
    title: '1984',
    author: 'George Orwell',
    coverUrl: 'https://via.placeholder.com/150x220.png?text=1984',
    difficultyLevel: 'B2',
    totalChapters: 24,
    description: 'A dystopian social science fiction novel and cautionary tale.',
  ),
];

const _mockProgress = UserProgress(
  consecutiveDays: 12,
  totalWordsRead: 45200,
  booksCompleted: 2,
  currentBookChaptersRead: 4,
);

// --- Providers ---

final libraryBooksProvider = Provider<List<Book>>((ref) {
  return _mockBooks;
});

final userProgressProvider = Provider<UserProgress>((ref) {
  return _mockProgress;
});

// Which book is currently being read (mocking it to the first one)
final currentReadingBookProvider = Provider<Book?>((ref) {
  final books = ref.watch(libraryBooksProvider);
  return books.isNotEmpty ? books.first : null;
});
