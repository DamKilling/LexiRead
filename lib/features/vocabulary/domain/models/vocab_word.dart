class VocabWord {
  final String id;
  final String word;
  final String phonetic;
  final String translation;
  final String contextSentence;
  final DateTime addedAt;

  const VocabWord({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.translation,
    required this.contextSentence,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'phonetic': phonetic,
      'translation': translation,
      'contextSentence': contextSentence,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory VocabWord.fromJson(Map<String, dynamic> map) {
    return VocabWord(
      id: map['id'],
      word: map['word'],
      phonetic: map['phonetic'] ?? '',
      translation: map['translation'] ?? '',
      contextSentence: map['contextSentence'] ?? '',
      addedAt: DateTime.parse(map['addedAt']),
    );
  }
}
