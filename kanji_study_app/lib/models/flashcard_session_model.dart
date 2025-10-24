import 'dart:convert';

/// Represents a single flashcard result
class FlashcardResult {
  final String itemType;  // 'word' or 'kanji'
  final int itemId;       // word_id or kanji_id
  final bool isCorrect;   // true = knew it, false = didn't know
  final DateTime timestamp;

  const FlashcardResult({
    required this.itemType,
    required this.itemId,
    required this.isCorrect,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemType': itemType,
      'itemId': itemId,
      'isCorrect': isCorrect,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FlashcardResult.fromJson(Map<String, dynamic> json) {
    return FlashcardResult(
      itemType: json['itemType'] as String? ?? 'word',  // 하위 호환성
      itemId: json['itemId'] as int? ?? json['wordId'] as int,  // 하위 호환성
      isCorrect: json['isCorrect'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Represents a flashcard study session
class FlashcardSession {
  final String itemType;  // 'word' or 'kanji'
  final List<int> itemIds;  // word_ids or kanji_ids
  final int currentIndex;
  final List<FlashcardResult> results;
  final DateTime startTime;
  final DateTime? endTime;

  const FlashcardSession({
    required this.itemType,
    required this.itemIds,
    this.currentIndex = 0,
    this.results = const [],
    required this.startTime,
    this.endTime,
  });

  /// Check if the session is completed
  bool get isCompleted => currentIndex >= itemIds.length;

  /// Get the current item ID
  int? get currentItemId {
    if (currentIndex < itemIds.length) {
      return itemIds[currentIndex];
    }
    return null;
  }

  /// 하위 호환성을 위한 getter (deprecated)
  @deprecated
  int? get currentWordId => currentItemId;

  /// Get progress percentage (0-100)
  double get progressPercentage {
    if (itemIds.isEmpty) return 0;
    return (currentIndex / itemIds.length * 100).clamp(0, 100);
  }

  /// Get number of correct answers
  int get correctCount => results.where((r) => r.isCorrect).length;

  /// Get number of incorrect answers
  int get incorrectCount => results.where((r) => !r.isCorrect).length;

  /// Get accuracy percentage
  double get accuracyPercentage {
    if (results.isEmpty) return 0;
    return (correctCount / results.length * 100).clamp(0, 100);
  }

  /// Create a new session with updated current index
  FlashcardSession copyWithNextCard() {
    return FlashcardSession(
      itemType: itemType,
      itemIds: itemIds,
      currentIndex: currentIndex + 1,
      results: results,
      startTime: startTime,
      endTime: currentIndex + 1 >= itemIds.length ? DateTime.now() : null,
    );
  }

  /// Create a new session with an added result
  FlashcardSession copyWithResult(FlashcardResult result) {
    return FlashcardSession(
      itemType: itemType,
      itemIds: itemIds,
      currentIndex: currentIndex,
      results: [...results, result],
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'itemType': itemType,
      'itemIds': itemIds,
      'currentIndex': currentIndex,
      'results': results.map((r) => r.toJson()).toList(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory FlashcardSession.fromJson(Map<String, dynamic> json) {
    return FlashcardSession(
      itemType: json['itemType'] as String? ?? 'word',  // 하위 호환성
      itemIds: (json['itemIds'] as List?)?.cast<int>() ??
               (json['wordIds'] as List).cast<int>(),  // 하위 호환성
      currentIndex: json['currentIndex'] as int,
      results: (json['results'] as List)
          .map((r) => FlashcardResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
    );
  }

  /// Convert to JSON string
  String toJsonString() => json.encode(toJson());

  /// Create from JSON string
  static FlashcardSession fromJsonString(String jsonString) {
    return FlashcardSession.fromJson(json.decode(jsonString));
  }
}
