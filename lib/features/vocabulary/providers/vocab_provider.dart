import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/vocab_word.dart';

class VocabNotifier extends StateNotifier<List<VocabWord>> {
  VocabNotifier() : super([]) {
    _loadVocab();
  }

  static const _key = 'user_vocabulary';

  Future<void> _loadVocab() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    state = data.map((e) => VocabWord.fromJson(jsonDecode(e))).toList();
  }

  Future<void> addWord(String word, String phonetic, String translation, String contextSentence) async {
    final newWord = VocabWord(
      id: const Uuid().v4(),
      word: word,
      phonetic: phonetic,
      translation: translation,
      contextSentence: contextSentence,
      addedAt: DateTime.now(),
    );

    // Prevent duplicates
    if (state.any((w) => w.word.toLowerCase() == word.toLowerCase())) {
      return; // Already added
    }

    state = [newWord, ...state];
    await _saveVocab();
  }

  Future<void> removeWord(String id) async {
    state = state.where((w) => w.id != id).toList();
    await _saveVocab();
  }

  Future<void> _saveVocab() async {
    final prefs = await SharedPreferences.getInstance();
    final data = state.map((w) => jsonEncode(w.toJson())).toList();
    await prefs.setStringList(_key, data);
  }
}

final vocabProvider = StateNotifierProvider<VocabNotifier, List<VocabWord>>((ref) {
  return VocabNotifier();
});
