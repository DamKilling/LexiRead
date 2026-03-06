import '../models/text_token.dart';

class TextParser {
  /// Parses a given paragraph string into a list of TextTokens.
  /// It separates readable words from punctuations/spaces.
  /// [startingSentenceIndex] is the global index of the first sentence in this paragraph.
  /// Returns a tuple of the parsed tokens and the NEXT available global sentence index.
  static (List<TextToken>, int) parseParagraph(String paragraph, int paragraphIndex, int startingSentenceIndex) {
    List<TextToken> tokens = [];
    
    // Regular expression to match words (including hyphens and apostrophes)
    // OR non-word characters (spaces, punctuation).
    RegExp exp = RegExp(r"([a-zA-Z\-']+)|([^a-zA-Z\-']+)");
    Iterable<RegExpMatch> matches = exp.allMatches(paragraph);
    
    int currentSentenceIndex = startingSentenceIndex;
    const abbreviations = {'mr', 'mrs', 'ms', 'dr', 'prof', 'sr', 'jr', 'st', 'vs', 'etc', 'ie', 'eg', 'vol', 'inc', 'ltd', 'co', 'corp', 'phd'};

    for (final match in matches) {
      String wordOrPunc = match.group(0)!;
      // If group(1) is not null, it matched the word part.
      bool isWord = match.group(1) != null;

      tokens.add(TextToken(
        text: wordOrPunc,
        isWord: isWord,
        sentenceIndex: currentSentenceIndex,
        paragraphIndex: paragraphIndex,
      ));

      // If the token is punctuation ending a sentence (., ?, !), increment the sentence index.
      // We check if the non-word token contains a sentence-ending character.
      if (!isWord && RegExp(r'[.?!]').hasMatch(wordOrPunc)) {
        bool isAbbreviation = false;
        
        // If the punctuation only contains periods (no ? or !), we check if it follows a known abbreviation or initial
        if (wordOrPunc.contains('.') && !wordOrPunc.contains('?') && !wordOrPunc.contains('!')) {
          if (tokens.length >= 2) {
            final previousToken = tokens[tokens.length - 2];
            if (previousToken.isWord) {
              final prevWordLower = previousToken.text.toLowerCase();
              if (abbreviations.contains(prevWordLower)) {
                isAbbreviation = true;
              } else if (previousToken.text.length == 1 && previousToken.text.toUpperCase() == previousToken.text) {
                // Single uppercase letter, like 'A.' or 'J. K. Rowling'
                isAbbreviation = true;
              }
            }
          }
        }

        if (!isAbbreviation) {
          currentSentenceIndex++;
        }
      }
    }
    return (tokens, currentSentenceIndex);
  }
}
