import 'dart:convert';

/// Represents a single flashcard result
class FlashcardResult {
  final int wordId;
  final bool isCorrect; // true = knew it, false = didn't know
  final DateTime timestamp;

  const FlashcardResult({
    required this.wordId,
    required this.isCorrect,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'wordId': wordId,
      'isCorrect': isCorrect,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FlashcardResult.fromJson(Map<String, dynamic> json) {
    return FlashcardResult(
      wordId: json['wordId'] as int,
      isCorrect: json['isCorrect'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Represents a flashcard study session
class FlashcardSession {
  final List<int> wordIds;
  final int currentIndex;
  final List<FlashcardResult> results;
  final DateTime startTime;
  final DateTime? endTime;

  const FlashcardSession({
    required this.wordIds,
    this.currentIndex = 0,
    this.results = const [],
    required this.startTime,
    this.endTime,
  });

  /// Check if the session is completed
  bool get isCompleted => currentIndex >= wordIds.length;

  /// Get the current word ID
  int? get currentWordId {
    if (currentIndex < wordIds.length) {
      return wordIds[currentIndex];
    }
    return null;
  }

  /// Get progress percentage (0-100)
  double get progressPercentage {
    if (wordIds.isEmpty) return 0;
    return (currentIndex / wordIds.length * 100).clamp(0, 100);
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
      wordIds: wordIds,
      currentIndex: currentIndex + 1,
      results: results,
      startTime: startTime,
      endTime: currentIndex + 1 >= wordIds.length ? DateTime.now() : null,
    );
  }

  /// Create a new session with an added result
  FlashcardSession copyWithResult(FlashcardResult result) {
    return FlashcardSession(
      wordIds: wordIds,
      currentIndex: currentIndex,
      results: [...results, result],
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'wordIds': wordIds,
      'currentIndex': currentIndex,
      'results': results.map((r) => r.toJson()).toList(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory FlashcardSession.fromJson(Map<String, dynamic> json) {
    return FlashcardSession(
      wordIds: (json['wordIds'] as List).cast<int>(),
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
