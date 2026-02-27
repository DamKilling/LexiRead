class UserProgress {
  final int consecutiveDays;
  final int totalWordsRead;
  final int booksCompleted;
  final int currentBookChaptersRead;

  const UserProgress({
    this.consecutiveDays = 0,
    this.totalWordsRead = 0,
    this.booksCompleted = 0,
    this.currentBookChaptersRead = 0,
  });
}
