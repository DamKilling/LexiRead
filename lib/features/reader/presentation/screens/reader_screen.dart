import 'package:flutter/material.dart';
import '../../utils/text_parser.dart';
import '../../models/text_token.dart';
import '../widgets/interactive_paragraph.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  // Dummy data for MVP testing
  final List<String> _mockParagraphs = [
    "It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.",
    "However little known the feelings or views of such a man may be on his first entering a neighbourhood, this truth is so well fixed in the minds of the surrounding families, that he is considered the rightful property of some one or other of their daughters.",
    "\"My dear Mr. Bennet,\" said his lady to him one day, \"have you heard that Netherfield Park is let at last?\"",
    "Mr. Bennet replied that he had not.",
  ];

  late List<List<TextToken>> _parsedParagraphs;
  
  // State to simulate audio sync highlight
  int? _activeSentenceIndex;

  @override
  void initState() {
    super.initState();
    // Parse paragraphs on init to avoid parsing on every build
    _parsedParagraphs = List.generate(
      _mockParagraphs.length,
      (index) => TextParser.parseParagraph(_mockParagraphs[index], index),
    );
  }

  void _onWordTapped(TextToken token) {
    // Show mock translation bottom sheet
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                token.text,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "[Mock Phonetic] • /mɒk/",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                "n. 这是一个模拟的翻译结果。\nv. 点击单词即可触发此底部弹窗。\n\n所属段落: ${token.paragraphIndex}\n所属句子: ${token.sentenceIndex}",
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.add),
                  label: const Text("加入生词本"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chapter 1'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_fill),
            onPressed: () {
              // Simulate audio playing (cycling through sentences)
              setState(() {
                if (_activeSentenceIndex == null) {
                  _activeSentenceIndex = 0;
                } else if (_activeSentenceIndex! < 4) {
                  _activeSentenceIndex = _activeSentenceIndex! + 1;
                } else {
                  _activeSentenceIndex = null;
                }
              });
            },
            tooltip: 'Simulate Audio Play',
          )
        ],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          itemCount: _parsedParagraphs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            return InteractiveParagraph(
              tokens: _parsedParagraphs[index],
              onWordTap: _onWordTapped,
              activeSentenceIndex: _activeSentenceIndex,
            );
          },
        ),
      ),
    );
  }
}
