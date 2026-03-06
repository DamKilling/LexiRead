import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../domain/models/book.dart';

class BookRepository {
  final supa.SupabaseClient _client;

  BookRepository(this._client);

  Future<List<Book>> getBooks() async {
    final response = await _client.from('books').select().order('created_at');
    
    if ((response as List<dynamic>).isEmpty) {
      // Return mock data if database is empty for testing
      return [
        const Book(
          id: 'mock_book_1',
          title: 'The Little Prince',
          author: 'Antoine de Saint-Exupéry',
          coverUrl: 'https://images.unsplash.com/photo-1590845947698-8924d7409b56?q=80&w=500',
          difficultyLevel: 'A2',
          totalChapters: 27,
          description: 'A timeless tale of a young prince visiting various planets.',
        ),
        const Book(
          id: 'mock_book_2',
          title: 'Alice in Wonderland',
          author: 'Lewis Carroll',
          coverUrl: 'https://images.unsplash.com/photo-1629196914275-f5f48eca52af?q=80&w=500',
          difficultyLevel: 'B1',
          totalChapters: 12,
          description: 'A young girl falls through a rabbit hole into a fantasy world.',
        ),
      ];
    }

    return response.map((json) {
      return Book(
        id: json['id'] as String,
        title: json['title'] as String,
        author: json['author'] as String,
        coverUrl: json['cover_url'] as String? ?? '',
        difficultyLevel: json['difficulty_level'] as String? ?? 'N/A',
        totalChapters: json['total_chapters'] as int? ?? 0,
        description: json['description'] as String? ?? '',
      );
    }).toList();
  }
}
