import 'dart:convert';
import 'package:http/http.dart' as http;

class DictionaryResult {
  final String word;
  final String phonetic;
  final String partOfSpeech;
  final String definition;
  final String example;
  final String translation; // Chinese translation

  DictionaryResult({
    required this.word,
    required this.phonetic,
    required this.partOfSpeech,
    required this.definition,
    required this.example,
    this.translation = '',
  });
}
class DictionaryService {
  /// Fetches word definition from the Free Dictionary API
  static Future<DictionaryResult?> lookupWord(String word) async {
    // Clean the word from punctuation just in case
    final cleanWord = word.replaceAll(RegExp(r'[^\w\s\-]'), '').toLowerCase();
    if (cleanWord.isEmpty) return null;

    String phonetic = '';
    String partOfSpeech = '';
    String definition = 'No definition found.';
    String example = '';
    String translation = '';

    try {
      // 1. Fetch English definition
      final engResponse = await http.get(
        Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$cleanWord'),
      );

      if (engResponse.statusCode == 200) {
        final List<dynamic> data = json.decode(engResponse.body);
        if (data.isNotEmpty) {
          final entry = data[0];
          
          phonetic = entry['phonetic'] ?? '';
          if (phonetic.isEmpty && entry['phonetics'] != null && (entry['phonetics'] as List).isNotEmpty) {
            phonetic = entry['phonetics'][0]['text'] ?? '';
          }

          if (entry['meanings'] != null && (entry['meanings'] as List).isNotEmpty) {
            final meaning = entry['meanings'][0];
            partOfSpeech = meaning['partOfSpeech'] ?? '';
            
            if (meaning['definitions'] != null && (meaning['definitions'] as List).isNotEmpty) {
              final def = meaning['definitions'][0];
              definition = def['definition'] ?? '';
              example = def['example'] ?? '';
            }
          }
        }
      }
    } catch (e) {
      // Ignore English dict errors, continue to translation
    }

    try {
      // 2. Fetch Chinese translation via MyMemory API
      final transResponse = await http.get(
        Uri.parse('https://api.mymemory.translated.net/get?q=$cleanWord&langpair=en|zh-CN'),
      );

      if (transResponse.statusCode == 200) {
        final transData = json.decode(transResponse.body);
        if (transData['responseData'] != null) {
          translation = transData['responseData']['translatedText'] ?? '';
        }
      }
    } catch (e) {
      // Ignore translation errors
    }

    if (phonetic.isEmpty && definition == 'No definition found.' && translation.isEmpty) {
      return null;
    }

    return DictionaryResult(
      word: cleanWord,
      phonetic: phonetic,
      partOfSpeech: partOfSpeech,
      definition: definition,
      example: example,
      translation: translation,
    );
  }

  /// Translates a full sentence from English to Chinese using MyMemory API
  static Future<String?> translateSentence(String sentence) async {
    if (sentence.trim().isEmpty) return null;

    try {
      final uri = Uri.parse('https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(sentence)}&langpair=en|zh-CN');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['responseData'] != null) {
          return data['responseData']['translatedText'];
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
