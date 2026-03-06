import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../providers/library_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _isSearchingExternal = false;
  List<dynamic> _externalResults = [];
  String? _externalError;

  void _onSearchChanged(String value) {
    setState(() {
      _query = value;
    });
  }

  Future<void> _searchExternal() async {
    if (_query.trim().isEmpty) return;
    
    setState(() {
      _isSearchingExternal = true;
      _externalError = null;
      _externalResults = [];
    });

    try {
      // Connect to our local FastAPI server
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/search/external?q=${Uri.encodeComponent(_query)}'));
      
      if (response.statusCode == 200) {
        setState(() {
          _externalResults = jsonDecode(response.body);
          _isSearchingExternal = false;
        });
      } else {
        setState(() {
          _externalError = 'Failed to load external books: ${response.statusCode}';
          _isSearchingExternal = false;
        });
      }
    } catch (e) {
      setState(() {
        _externalError = 'Connection error. Is the backend server running?\n$e';
        _isSearchingExternal = false;
      });
    }
  }

  Future<void> _importBook(dynamic book) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/import'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'source': book['source'],
          'external_id': book['id'],
          'title': book['title'],
          'author': book['author'],
          'cover_url': book['cover_url'],
          'text_url': book['text_url'],
          'subjects': book['subjects'] ?? [],
        }),
      );

      if (context.mounted) {
        Navigator.pop(context); // Close dialog
      }

      if (response.statusCode == 200) {
        ref.invalidate(libraryBooksProvider);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Import successful!')),
          );
          setState(() {
            book['is_imported'] = true;
          });
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import failed: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allBooksAsync = ref.watch(libraryBooksProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search library or web...',
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
          onSubmitted: (_) => _searchExternal(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
              setState(() {
                _externalResults = [];
              });
            },
          ),
        ],
      ),
      body: _query.isEmpty
          ? const Center(child: Text('Type to search local library or external sources'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Local Library',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  allBooksAsync.when(
                    data: (books) {
                      final localMatches = books.where((b) {
                        return b.title.toLowerCase().contains(_query.toLowerCase()) ||
                               b.author.toLowerCase().contains(_query.toLowerCase());
                      }).toList();

                      if (localMatches.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 24.0),
                          child: Text('No matching books found locally.'),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: localMatches.length,
                        itemBuilder: (context, index) {
                          final book = localMatches[index];
                          return ListTile(
                            leading: book.coverUrl.isNotEmpty
                                ? Image.network(book.coverUrl, width: 40, height: 60, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.book))
                                : const Icon(Icons.book),
                            title: Text(book.title),
                            subtitle: Text(book.author),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/reader/${book.id}/1'),
                          );
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, s) => Text('Error loading local books: $e'),
                  ),
                  
                  const Divider(height: 48),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'External Sources',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton.icon(
                        onPressed: _searchExternal,
                        icon: const Icon(Icons.travel_explore),
                        label: const Text('Search Web'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_isSearchingExternal)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    )),
                    
                  if (_externalError != null)
                    Text(_externalError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    
                  if (!_isSearchingExternal && _externalResults.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _externalResults.length,
                      itemBuilder: (context, index) {
                        final book = _externalResults[index];
                        final bool isImported = book['is_imported'] ?? false;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: book['cover_url'] != null
                                ? Image.network(book['cover_url'], width: 40, height: 60, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.book))
                                : const Icon(Icons.book),
                            title: Text(book['title'], maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text(book['author']),
                            trailing: isImported
                                ? const TextButton(onPressed: null, child: Text('Imported'))
                                : ElevatedButton(
                                    onPressed: () => _importBook(book),
                                    child: const Text('Import'),
                                  ),
                          ),
                        );
                      },
                    ),
                    
                  if (!_isSearchingExternal && _externalResults.isEmpty && _query.isNotEmpty && _externalError == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 24.0),
                      child: Center(child: Text('Click "Search Web" to find books online.')),
                    ),
                ],
              ),
            ),
    );
  }
}
