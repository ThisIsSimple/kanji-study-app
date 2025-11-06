/// 한국어 훈독과 음독을 포맷팅하는 유틸리티 함수
///
/// 포맷팅 규칙:
/// - 훈독 1개, 음독 1개: "훈독 음독" (예: "노래 가")
/// - 훈독 여러개, 음독 1개: "A훈독/B훈독 음독" (예: "당나라/당황할 당")
/// - 훈독 1개, 음독 여러개: "훈독 A음독/B음독" (예: "값 가/치")
/// - 훈독과 음독 모두 여러개: "A훈독 A음독/B훈독 B음독" (예: "내릴 강/항복할 항")
String formatKoreanReadings(List<String> kunReadings, List<String> onReadings) {
  if (kunReadings.isEmpty && onReadings.isEmpty) {
    return '';
  }

  // 훈독만 있는 경우
  if (kunReadings.isNotEmpty && onReadings.isEmpty) {
    return kunReadings.join('/');
  }

  // 음독만 있는 경우
  if (kunReadings.isEmpty && onReadings.isNotEmpty) {
    return onReadings.join('/');
  }

  // 훈독 1개, 음독 1개
  if (kunReadings.length == 1 && onReadings.length == 1) {
    return '${kunReadings[0]} ${onReadings[0]}';
  }

  // 훈독 여러개, 음독 1개
  if (kunReadings.length > 1 && onReadings.length == 1) {
    return '${kunReadings.join('/')} ${onReadings[0]}';
  }

  // 훈독 1개, 음독 여러개
  if (kunReadings.length == 1 && onReadings.length > 1) {
    return '${kunReadings[0]} ${onReadings.join('/')}';
  }

  // 훈독과 음독 모두 여러개
  if (kunReadings.length > 1 && onReadings.length > 1) {
    // 훈독과 음독의 개수가 같은 경우: 1:1 매칭
    if (kunReadings.length == onReadings.length) {
      final List<String> pairs = [];
      for (int i = 0; i < kunReadings.length; i++) {
        pairs.add('${kunReadings[i]} ${onReadings[i]}');
      }
      return pairs.join('/');
    }

    // 훈독과 음독의 개수가 다른 경우
    // 음독이 더 적은 경우: 마지막 음독을 반복 사용
    if (onReadings.length < kunReadings.length) {
      final List<String> pairs = [];
      for (int i = 0; i < kunReadings.length; i++) {
        final onIndex = i < onReadings.length ? i : onReadings.length - 1;
        pairs.add('${kunReadings[i]} ${onReadings[onIndex]}');
      }
      return pairs.join('/');
    }

    // 훈독이 더 적은 경우: 훈독을 모두 표시하고 나머지 음독 추가
    if (kunReadings.length < onReadings.length) {
      final List<String> pairs = [];
      for (int i = 0; i < kunReadings.length; i++) {
        pairs.add('${kunReadings[i]} ${onReadings[i]}');
      }
      // 남은 음독들 추가
      if (kunReadings.length < onReadings.length) {
        final remainingOn = onReadings.sublist(kunReadings.length);
        pairs.add(remainingOn.join('/'));
      }
      return pairs.join('/');
    }
  }

  // 기본값 (예상치 못한 경우)
  return '${kunReadings.join('/')} ${onReadings.join('/')}';
}

/// 한국어 읽기 정보가 있는지 확인
bool hasKoreanReadings(List<String> kunReadings, List<String> onReadings) {
  return kunReadings.isNotEmpty || onReadings.isNotEmpty;
}
