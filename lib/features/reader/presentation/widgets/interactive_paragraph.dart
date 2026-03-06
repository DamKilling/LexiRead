import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../models/text_token.dart';

class InteractiveParagraph extends StatefulWidget {
  final List<TextToken> tokens;
  final Function(TextToken wordToken) onWordTap;
  final Function(int sentenceIndex)? onTranslateSentence;
  final int? activeSentenceIndex;
  final bool isHeader;
  const InteractiveParagraph({
    super.key,
    required this.tokens,
    required this.onWordTap,
    this.onTranslateSentence,
    this.activeSentenceIndex,
    this.isHeader = false,
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
    // Determine if this entire paragraph acts like a header or subheader
    // We check if it has tokens, and all word tokens are uppercase.
    final wordTokens = widget.tokens.where((t) => t.isWord).toList();
    final bool isAllUppercase = wordTokens.isNotEmpty && wordTokens.every((t) => t.text == t.text.toUpperCase());
    final bool isShortSubtitle = widget.tokens.length < 15 && !widget.tokens.any((t) => t.text.contains('.') && t != widget.tokens.last);
    final bool shouldRenderAsHeader = widget.isHeader || (isAllUppercase && isShortSubtitle);

    return RichText(
      textAlign: shouldRenderAsHeader ? TextAlign.center : TextAlign.left,
      text: TextSpan(
        children: List.generate(widget.tokens.length, (index) {
          final token = widget.tokens[index];
          final isHighlight = token.sentenceIndex == widget.activeSentenceIndex;
          final isLastTokenOfSentence = index == widget.tokens.length - 1 || widget.tokens[index].sentenceIndex != widget.tokens[index + 1].sentenceIndex;

          // Adjust styles if it's a header
          double fontSize = shouldRenderAsHeader ? 28 : 20;
          FontWeight fontWeight = shouldRenderAsHeader ? FontWeight.bold : (token.isWord ? FontWeight.w400 : FontWeight.normal);
          double height = shouldRenderAsHeader ? 1.4 : 1.8;

          return TextSpan(
            children: [
              TextSpan(
                text: token.text,
                style: GoogleFonts.lora(
                  fontSize: fontSize,
                  height: height, 
                  color: isHighlight
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                  backgroundColor: isHighlight
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.transparent,
                  fontWeight: fontWeight,
                ),
                recognizer: _recognizers[index],
              ),
              if (isLastTokenOfSentence && widget.onTranslateSentence != null && !shouldRenderAsHeader)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: GestureDetector(
                    onTap: () => widget.onTranslateSentence!(token.sentenceIndex),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4.0, right: 8.0),
                      child: Icon(
                        Icons.g_translate,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}
