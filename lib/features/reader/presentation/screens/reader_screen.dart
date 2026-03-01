import 'package:flutter/material.dart';
import '../../controllers/audio_sync_controller.dart';
import '../../services/dictionary_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/text_parser.dart';
import '../../models/text_token.dart';
import '../widgets/interactive_paragraph.dart';
import '../../providers/reader_provider.dart';
class ReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final int chapterNumber;

  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.chapterNumber,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late List<List<TextToken>> _parsedParagraphs;
  late AudioSyncController _audioController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Mock audio controller setup, same as before but without hardcoded text
    _audioController = AudioSyncController(
      timestamps: [
        AudioTimestamp(sentenceIndex: 0, start: const Duration(seconds: 0), end: const Duration(seconds: 6)),
        AudioTimestamp(sentenceIndex: 1, start: const Duration(seconds: 6), end: const Duration(seconds: 14)),
        AudioTimestamp(sentenceIndex: 2, start: const Duration(seconds: 14), end: const Duration(seconds: 19)),
        AudioTimestamp(sentenceIndex: 3, start: const Duration(seconds: 19), end: const Duration(seconds: 22)),
      ],
    );
    _audioController.init('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');
  }

  void _initAudioAndParse(String content) {
    final paragraphs = content.split('\n').where((p) => p.trim().isNotEmpty).toList();
    _parsedParagraphs = List.generate(
      paragraphs.length,
      (index) => TextParser.parseParagraph(paragraphs[index], index),
    );
  }

  @override
  void dispose() {
    _audioController.dispose();
    super.dispose();
  }

  void _onWordTapped(TextToken token) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.2,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<DictionaryResult?>(
              future: DictionaryService.lookupWord(token.text),
              builder: (context, snapshot) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        token.text,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (snapshot.hasData && snapshot.data != null) ...[
                        Row(
                          children: [
                            if (snapshot.data!.phonetic.isNotEmpty)
                              Text(
                                snapshot.data!.phonetic,
                                style: const TextStyle(color: Colors.grey, fontSize: 18),
                              ),
                            const SizedBox(width: 12),
                            if (snapshot.data!.partOfSpeech.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  snapshot.data!.partOfSpeech,
                                  style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Definition",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.data!.definition,
                          style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black54),
                        ),
                        if (snapshot.data!.example.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            "Example",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "\"${snapshot.data!.example}\"",
                            style: const TextStyle(fontSize: 16, height: 1.5, fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        ],
                      ] else ...[
                        const Text(
                          "No translation found.",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Original context:\nParagraph: ${token.paragraphIndex}, Sentence: ${token.sentenceIndex}",
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.bookmark_add),
                        label: const Text("加入生词本 (Add to Vocab)"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(chapterProvider(ChapterRequest(bookId: widget.bookId, chapterNumber: widget.chapterNumber)));

    return Scaffold(
      appBar: AppBar(
        title: Text('Chapter ${widget.chapterNumber}', style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold)),
        actions: [
          if (_isInitialized)
            ValueListenableBuilder<bool>(
              valueListenable: _audioController.isPlaying,
              builder: (context, isPlaying, _) {
                return IconButton(
                  icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                  iconSize: 32,
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: _audioController.togglePlayPause,
                  tooltip: isPlaying ? 'Pause Audio' : 'Play Audio',
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: chapterAsync.when(
          data: (chapter) {
            if (chapter == null) {
              return const Center(child: Text("Chapter not found."));
            }
            
            // Init logic only once when data arrives
            if (!_isInitialized) {
              _initAudioAndParse(chapter.content);
              _isInitialized = true;
            }

            return ValueListenableBuilder<int?>(
              valueListenable: _audioController.activeSentenceIndex,
              builder: (context, activeIndex, _) {
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  itemCount: _parsedParagraphs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 28),
                  itemBuilder: (context, index) {
                    return InteractiveParagraph(
                      tokens: _parsedParagraphs[index],
                      onWordTap: _onWordTapped,
                      activeSentenceIndex: activeIndex,
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text("Error: $error")),
        ),
      ),
    );
  }
}