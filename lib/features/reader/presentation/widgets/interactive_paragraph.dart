import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../models/text_token.dart';

class InteractiveParagraph extends StatefulWidget {
  final List<TextToken> tokens;
  final Function(TextToken wordToken) onWordTap;
  final int? activeSentenceIndex;

  const InteractiveParagraph({
    super.key,
    required this.tokens,
    required this.onWordTap,
    this.activeSentenceIndex,
  });

  @override
  State<InteractiveParagraph> createState() => _InteractiveParagraphState();
}

class _InteractiveParagraphState extends State<InteractiveParagraph> {
  // Store recognizers to dispose them later to prevent memory leaks
  late List<TapGestureRecognizer?> _recognizers;

  @override
  void initState() {
    super.initState();
    _initRecognizers();
  }

  @override
  void didUpdateWidget(covariant InteractiveParagraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tokens != widget.tokens) {
      _disposeRecognizers();
      _initRecognizers();
    }
  }

  void _initRecognizers() {
    _recognizers = widget.tokens.map((token) {
      if (token.isWord) {
        return TapGestureRecognizer()
          ..onTap = () => widget.onWordTap(token);
      }
      return null;
    }).toList();
  }

  void _disposeRecognizers() {
    for (var recognizer in _recognizers) {
      recognizer?.dispose();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: List.generate(widget.tokens.length, (index) {
          final token = widget.tokens[index];
          final isHighlight = token.sentenceIndex == widget.activeSentenceIndex;

          return TextSpan(
            text: token.text,
            style: TextStyle(
              fontSize: 18,
              height: 1.8, // Better reading experience
              color: isHighlight
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
              backgroundColor: isHighlight
                  ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : Colors.transparent,
              fontWeight: token.isWord ? FontWeight.w400 : FontWeight.normal,
            ),
            recognizer: _recognizers[index],
          );
        }),
      ),
    );
  }
}
