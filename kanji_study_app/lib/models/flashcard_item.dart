/// 플래시카드로 학습 가능한 모든 항목의 인터페이스
/// Word, Kanji 등 다양한 학습 항목을 플래시카드로 표시하기 위한 추상 인터페이스
abstract class FlashcardItem {
  /// 고유 ID (데이터베이스 ID)
  int get id;

  /// 학습 항목 타입 ('word', 'kanji')
  String get itemType;

  /// 앞면에 표시할 메인 텍스트
  String get frontText;

  /// 앞면 보조 정보 (예: JLPT 레벨, 학년)
  String? get frontBadge;

  /// 앞면 뱃지 색상
  int? get frontBadgeColor;

  /// 뒷면에 표시할 메인 텍스트
  String get backText;

  /// 뒷면에 표시할 읽기 정보 (후리가나, 음훈독 등)
  String? get backReading;

  /// 뒷면에 표시할 의미 목록
  List<FlashcardMeaning> get backMeanings;
}

/// 플래시카드 의미 정보
class FlashcardMeaning {
  final String category;  // 품사, 음/훈독 구분 등
  final String meaning;   // 실제 의미

  const FlashcardMeaning({
    required this.category,
    required this.meaning,
  });
}
