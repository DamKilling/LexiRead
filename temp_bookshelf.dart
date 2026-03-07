import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/library_provider.dart';
import '../widgets/book_card.dart';
import '../../domain/models/book.dart';

class BookshelfView extends ConsumerWidget {
  const BookshelfView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBook = ref.watch(currentReadingBookProvider);
    final filteredBooksAsync = ref.watch(filteredBooksProvider);
    final filterState = ref.watch(libraryFilterProvider);
    final filterNotifier = ref.read(libraryFilterProvider.notifier);

    final categories = ['All', 'Classic', 'Horror', 'Mystery', 'Fantasy', 'Adventure', 'Romance', 'Sci-Fi', 'Other'];
    final difficulties = ['All', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'N/A'];

    final allBooks = ref.watch(libraryBooksProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Continue Reading',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 20),
          currentBook.when(
            data: (data) {
              if (data == null) return const SizedBox.shrink();
              final book = data['book'] as Book;
              final chapter = data['chapter'] as int;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GestureDetector(
                  onTap: () => context.push('/reader/${book.id}/$chapter'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          // Cover Image placeholder
                          Container(
                            width: 72,
                            height: 108,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: book.coverUrl.isNotEmpty
                                ? Image.network(book.coverUrl, fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.book, size: 32, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2));
                                  })
                                : Icon(Icons.book, size: 32, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                          ),
                          const SizedBox(width: 20),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Level ${book.difficultyLevel} â€?Chapter $chapter',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Resume',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Library',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => _buildFilterSheet(context, filterState, filterNotifier, difficulties),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search your books...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => filterNotifier.setSearchQuery(value),
            ),
          ),
          const SizedBox(height: 16),
          // Category Chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = filterState.category == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      filterNotifier.setCategory(category);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          filteredBooksAsync.when(
            data: (books) {
              if (books.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.menu_book, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'No books found matching your filters.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => filterNotifier.reset(),
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: books.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return BookCard(book: books[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFilterSheet(BuildContext context, LibraryFilterState filterState, LibraryFilterNotifier filterNotifier, List<String> difficulties) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () {
                    filterNotifier.reset();
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Difficulty', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: difficulties.map((diff) {
                final isSelected = filterState.difficulty == diff;
                return ChoiceChip(
                  label: Text(diff),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) filterNotifier.setDifficulty(diff);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Reading Status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusChip('All', ReadingStatus.all, filterState, filterNotifier),
                _buildStatusChip('Not Started', ReadingStatus.notStarted, filterState, filterNotifier),
                _buildStatusChip('Reading', ReadingStatus.reading, filterState, filterNotifier),
                _buildStatusChip('Finished', ReadingStatus.finished, filterState, filterNotifier),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, ReadingStatus status, LibraryFilterState filterState, LibraryFilterNotifier filterNotifier) {
    final isSelected = filterState.status == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) filterNotifier.setStatus(status);
      },
    );
  }
}
