import 'package:flutter/material.dart';
import '../../controllers/audio_sync_controller.dart';
import '../../services/dictionary_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/text_parser.dart';
import '../../models/text_token.dart';
import '../widgets/interactive_paragraph.dart';
import '../../providers/reader_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../library/providers/library_provider.dart';
import '../../../vocabulary/providers/vocab_provider.dart';
import '../widgets/completion_poster.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/reader_settings_provider.dart';
import '../../providers/reading_progress_provider.dart';
import 'package:flutter/services.dart';

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
  }

  void _initAudioAndParse(String content, String? audioUrl, List<AudioTimestamp>? audioTimestamps) {
    final paragraphs = content.split('\n').where((p) => p.trim().isNotEmpty).toList();

    // Fix for abnormally long titles caused by TOC merging in legacy imports
    if (paragraphs.isNotEmpty) {
      String firstPara = paragraphs[0];
      int chapterCount = RegExp(r'CHAPTER|SCENE', caseSensitive: false).allMatches(firstPara).length;
      if (chapterCount > 1 || firstPara.length > 150) {
        int secondChapterIdx = firstPara.indexOf(RegExp(r'CHAPTER|SCENE', caseSensitive: false), 1);
        if (secondChapterIdx != -1) {
          paragraphs[0] = firstPara.substring(0, secondChapterIdx).trim();
        } else {
          paragraphs[0] = firstPara.substring(0, 100) + '...';
        }
      }
    }

    _parsedParagraphs = [];
    int currentGlobalSentenceIndex = 0;

    for (int i = 0; i < paragraphs.length; i++) {
      final result = TextParser.parseParagraph(paragraphs[i], i, currentGlobalSentenceIndex);
      _parsedParagraphs.add(result.$1);
      currentGlobalSentenceIndex = result.$2;
    }

    if (audioTimestamps != null && audioTimestamps.isNotEmpty && audioUrl != null && audioUrl.isNotEmpty) {
      _audioController = AudioSyncController(timestamps: audioTimestamps);
      _audioController.init(audioUrl);
    } else {
      // Fallback empty controller if no audio is available
      _audioController = AudioSyncController(timestamps: []);
    }
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
                        if (snapshot.data!.translation.isNotEmpty) ...[
                          const Text(
                            "中文释义 (Translation)",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.data!.translation,
                            style: const TextStyle(fontSize: 18, height: 1.5, color: Colors.blue, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (snapshot.data!.definition.isNotEmpty && snapshot.data!.definition != 'No definition found.') ...[
                          const Text(
                            "Definition",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.data!.definition,
                            style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black54),
                          ),
                        ],
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
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (snapshot.data != null) {
                                  ref.read(vocabProvider.notifier).addWord(
                                        token.text,
                                        snapshot.data!.phonetic,
                                        snapshot.data!.translation.isNotEmpty ? snapshot.data!.translation : snapshot.data!.definition,
                                        "Paragraph: ${token.paragraphIndex}, Sentence: ${token.sentenceIndex}",
                                      );
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('"${token.text}" added to Vocab', style: GoogleFonts.inter())),
                                  );
                                }
                              },
                              icon: const Icon(Icons.bookmark_add),
                              label: const Text("加入生词本"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: token.text));
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('"${token.text}" copied to clipboard', style: GoogleFonts.inter())),
                                );
                              },
                              icon: const Icon(Icons.copy),
                              label: const Text("复制 (Copy)"),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
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

  void _onTranslateSentenceTapped(int sentenceIndex) {
    // Reconstruct the full sentence
    String fullSentence = '';
    for (var paragraph in _parsedParagraphs) {
      for (var token in paragraph) {
        if (token.sentenceIndex == sentenceIndex) {
          fullSentence += token.text;
        }
      }
    }
    fullSentence = fullSentence.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FutureBuilder<String?>(
          future: DictionaryService.translateSentence(fullSentence),
          builder: (context, snapshot) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24.0,
                right: 24.0,
                top: 16.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      "Original Sentence",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fullSentence,
                      style: GoogleFonts.lora(fontSize: 18, height: 1.5, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Translation",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (snapshot.hasData && snapshot.data != null)
                      Text(
                        snapshot.data!,
                        style: GoogleFonts.inter(fontSize: 18, height: 1.5, color: Colors.black87),
                      )
                    else
                      const Text(
                        "Failed to load translation.",
                        style: TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTableOfContents(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            final chaptersAsync = ref.watch(bookChaptersProvider(widget.bookId));

            return Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Table of Contents',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: chaptersAsync.when(
                    data: (chapters) {
                      if (chapters.isEmpty) return const Center(child: Text("No chapters found."));
                      return ListView.separated(
                        controller: scrollController,
                        itemCount: chapters.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, indent: 24, endIndent: 24),
                        itemBuilder: (context, index) {
                          final chap = chapters[index];
                          final isCurrent = chap.chapterNumber == widget.chapterNumber;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                            title: Text(
                              chap.title,
                              style: TextStyle(
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: isCurrent ? Theme.of(context).colorScheme.primary : Colors.black87,
                              ),
                            ),
                            subtitle: Text('${chap.wordCount} words', style: const TextStyle(fontSize: 12)),
                            trailing: isCurrent ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                            onTap: () {
                              Navigator.pop(context);
                              if (!isCurrent) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReaderScreen(
                                      bookId: widget.bookId,
                                      chapterNumber: chap.chapterNumber,
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(child: Text("Error: $error")),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  void _showSettingsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final settings = ref.watch(readerSettingsProvider);
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Font Size'),
                      Expanded(
                        child: Slider(
                          value: settings.fontSize,
                          min: 14.0,
                          max: 32.0,
                          onChanged: (val) => ref.read(readerSettingsProvider.notifier).updateFontSize(val),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Line Height'),
                      Expanded(
                        child: Slider(
                          value: settings.lineHeight,
                          min: 1.2,
                          max: 2.5,
                          onChanged: (val) => ref.read(readerSettingsProvider.notifier).updateLineHeight(val),
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    title: const Text('Show Translation'),
                    value: settings.showTranslation,
                    onChanged: (val) => ref.read(readerSettingsProvider.notifier).toggleTranslation(val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(chapterProvider(ChapterRequest(bookId: widget.bookId, chapterNumber: widget.chapterNumber)));
    final readerSettings = ref.watch(readerSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chapter ${widget.chapterNumber}', style: GoogleFonts.lora(fontWeight: FontWeight.w600, fontSize: 18)),
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsPanel(context),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.menu_book),
            onPressed: () => _showTableOfContents(context),
            tooltip: 'Table of Contents',
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
              _initAudioAndParse(chapter.content, chapter.audioUrl, chapter.audioTimestamps);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ref.read(readingProgressProvider.notifier).saveProgress(widget.bookId, widget.chapterNumber);
                  setState(() {
                    _isInitialized = true;
                  });
                }
              });

            }
            return ValueListenableBuilder<int?>(
              valueListenable: _audioController.activeSentenceIndex,
              builder: (context, activeIndex, _) {
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  itemCount: _parsedParagraphs.length + 1,
                  separatorBuilder: (context, index) => const SizedBox(height: 28),
                  itemBuilder: (context, index) {
                    if (index == _parsedParagraphs.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                final authState = ref.read(authStateChangesProvider).value;
                                final userId = authState?.session?.user.id;
                                if (userId != null) {
                                  try {
                                    await ref.read(userRepositoryProvider).markChapterCompleted(
                                      userId: userId,
                                      bookId: widget.bookId,
                                      chapterNumber: widget.chapterNumber,
                                      wordCount: chapter.wordCount,
                                    );
                                    if (context.mounted) {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => CompletionPoster(
                                          bookTitle: chapter.title,
                                          chapterNumber: widget.chapterNumber,
                                          wordCount: chapter.wordCount,
                                          onClose: () {
                                            Navigator.of(context).pop(); // pop poster
                                            Navigator.of(context).pop(); // pop reader screen
                                          },
                                          onNextChapter: () {
                                            Navigator.of(context).pop(); // pop poster
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ReaderScreen(
                                                  bookId: widget.bookId,
                                                  chapterNumber: widget.chapterNumber + 1,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error saving progress: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Finish Chapter & Save Progress'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.chapterNumber > 1)
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ReaderScreen(
                                            bookId: widget.bookId,
                                            chapterNumber: widget.chapterNumber - 1,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                                    label: const Text('Previous Chapter'),
                                  ),
                                if (widget.chapterNumber > 1)
                                  const SizedBox(width: 16),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReaderScreen(
                                          bookId: widget.bookId,
                                          chapterNumber: widget.chapterNumber + 1,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                  label: const Text('Next Chapter'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                    return InteractiveParagraph(
                      tokens: _parsedParagraphs[index],
                      onWordTap: _onWordTapped,
                      onTranslateSentence: _onTranslateSentenceTapped,
                      activeSentenceIndex: activeIndex,
                      isHeader: index == 0,
                      fontSize: readerSettings.fontSize,
                      lineHeight: readerSettings.lineHeight,
                      showTranslation: readerSettings.showTranslation,
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