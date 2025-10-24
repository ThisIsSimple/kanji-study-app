import 'package:flutter/material.dart';
import 'flashcard_item.dart';
import 'kanji_model.dart';

/// Kanji 모델을 FlashcardItem 인터페이스로 변환하는 어댑터
class KanjiFlashcardAdapter implements FlashcardItem {
  final Kanji kanji;

  KanjiFlashcardAdapter(this.kanji);

  @override
  int get id => kanji.id;

  @override
  String get itemType => 'kanji';

  @override
  String get frontText => kanji.character;

  @override
  String? get frontBadge => 'JLPT N${kanji.jlpt}';

  @override
  int? get frontBadgeColor {
    // JLPT 레벨별 색상
    switch (kanji.jlpt) {
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
  String get backText => kanji.character;

  @override
  String? get backReading {
    // 음독과 훈독을 모두 표시
    final List<String> readings = [];
    if (kanji.readings.on.isNotEmpty) {
      readings.addAll(kanji.readings.on);
    }
    if (kanji.readings.kun.isNotEmpty) {
      readings.addAll(kanji.readings.kun);
    }
    return readings.isNotEmpty ? readings.join(' / ') : null;
  }

  @override
  List<FlashcardMeaning> get backMeanings {
    final List<FlashcardMeaning> meanings = [];

    // 의미
    if (kanji.meanings.isNotEmpty) {
      meanings.add(FlashcardMeaning(
        category: '의미',
        meaning: kanji.meanings.join(', '),
      ));
    }

    // 음독 (한글 표기)
    if (kanji.koreanOnReadings.isNotEmpty) {
      meanings.add(FlashcardMeaning(
        category: '음독',
        meaning: kanji.koreanOnReadings.join(', '),
      ));
    }

    // 훈독 (한글 표기)
    if (kanji.koreanKunReadings.isNotEmpty) {
      meanings.add(FlashcardMeaning(
        category: '훈독',
        meaning: kanji.koreanKunReadings.join(', '),
      ));
    }

    return meanings;
  }
}
