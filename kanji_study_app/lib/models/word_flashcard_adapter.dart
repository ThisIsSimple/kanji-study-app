import 'package:flutter/material.dart';
import 'flashcard_item.dart';
import 'word_model.dart';

/// Word 모델을 FlashcardItem 인터페이스로 변환하는 어댑터
class WordFlashcardAdapter implements FlashcardItem {
  final Word word;

  WordFlashcardAdapter(this.word);

  @override
  int get id => word.id;

  @override
  String get itemType => 'word';

  @override
  String get frontText => word.word;

  @override
  String? get frontBadge => 'JLPT N${word.jlptLevel}';

  @override
  int? get frontBadgeColor {
    // JLPT 레벨별 색상
    switch (word.jlptLevel) {
      case 1:
        return Colors.red.toARGB32();
      case 2:
        return Colors.orange.toARGB32();
      case 3:
        return Colors.amber.toARGB32();
      case 4:
        return Colors.lightGreen.toARGB32();
      case 5:
        return Colors.blue.toARGB32();
      default:
        return Colors.grey.toARGB32();
    }
  }

  @override
  String get backText => word.word;

  @override
  String? get backReading => word.reading;

  @override
  List<FlashcardMeaning> get backMeanings =>
      word.meanings
          .map((m) => FlashcardMeaning(
                category: m.partOfSpeech,
                meaning: m.meaning,
              ))
          .toList();
}
