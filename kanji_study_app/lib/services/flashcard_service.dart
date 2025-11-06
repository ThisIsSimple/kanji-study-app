import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard_session_model.dart';
import 'supabase_service.dart';

class FlashcardService {
  static final FlashcardService _instance = FlashcardService._internal();
  static FlashcardService get instance => _instance;

  FlashcardService._internal();

  final SupabaseService _supabaseService = SupabaseService.instance;

  // 단어와 한자 세션을 각각 독립적으로 관리
  FlashcardSession? _wordSession;
  FlashcardSession? _kanjiSession;

  // itemType별로 다른 키 사용
  String _getSessionKey(String itemType) => 'flashcard_session_$itemType';

  /// Get current active session for specific type
  FlashcardSession? getSession(String itemType) {
    return itemType == 'word' ? _wordSession : _kanjiSession;
  }

  /// Check if there's an active session for specific type
  bool hasActiveSession(String itemType) {
    final session = getSession(itemType);
    return session != null && !session.isCompleted;
  }

  /// Create a new flashcard session from a list of items
  Future<FlashcardSession> createSession(
    String itemType,
    List<int> itemIds,
  ) async {
    if (itemIds.isEmpty) {
      throw Exception('Cannot create flashcard session with empty item list');
    }

    final session = FlashcardSession(
      itemType: itemType,
      itemIds: itemIds,
      startTime: DateTime.now(),
    );

    // itemType에 따라 적절한 세션에 저장
    if (itemType == 'word') {
      _wordSession = session;
    } else {
      _kanjiSession = session;
    }

    await _saveSession(session);

    debugPrint(
      'Created flashcard session with ${itemIds.length} $itemType items',
    );
    return session;
  }

  /// Load saved session from storage for specific type
  Future<FlashcardSession?> loadSessionByType(String itemType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = _getSessionKey(itemType);
      final sessionJson = prefs.getString(sessionKey);

      if (sessionJson != null) {
        final session = FlashcardSession.fromJsonString(sessionJson);

        // 해당 타입의 세션에 저장
        if (itemType == 'word') {
          _wordSession = session;
        } else {
          _kanjiSession = session;
        }

        debugPrint(
          'Loaded $itemType flashcard session with ${session.itemIds.length} items',
        );
        return session;
      }
    } catch (e) {
      debugPrint('Error loading $itemType flashcard session: $e');
    }

    return null;
  }

  /// Load saved session from storage (deprecated - use loadSessionByType instead)
  @Deprecated('Use loadSessionByType instead')
  Future<FlashcardSession?> loadSession() async {
    // 하위 호환성을 위해 word 세션을 로드
    return loadSessionByType('word');
  }

  /// Save session to storage
  Future<void> _saveSession(FlashcardSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = _getSessionKey(session.itemType);
      await prefs.setString(sessionKey, session.toJsonString());
      debugPrint('Saved ${session.itemType} flashcard session');
    } catch (e) {
      debugPrint('Error saving ${session.itemType} flashcard session: $e');
    }
  }

  /// Clear session for specific type
  Future<void> clearSession(String itemType) async {
    if (itemType == 'word') {
      _wordSession = null;
    } else {
      _kanjiSession = null;
    }

    final prefs = await SharedPreferences.getInstance();
    final sessionKey = _getSessionKey(itemType);
    await prefs.remove(sessionKey);
    debugPrint('Cleared $itemType flashcard session');
  }

  /// Clear all sessions
  Future<void> clearAllSessions() async {
    _wordSession = null;
    _kanjiSession = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getSessionKey('word'));
    await prefs.remove(_getSessionKey('kanji'));
    debugPrint('Cleared all flashcard sessions');
  }

  /// Record a flashcard result and move to next card
  Future<FlashcardSession> recordResult({
    required int itemId,
    required bool isCorrect,
    required String itemType, // itemType 파라미터 추가
  }) async {
    final currentSession = getSession(itemType);

    if (currentSession == null) {
      throw Exception('No active $itemType flashcard session');
    }

    final result = FlashcardResult(
      itemType: itemType,
      itemId: itemId,
      isCorrect: isCorrect,
      timestamp: DateTime.now(),
    );

    // Add result to session
    var updatedSession = currentSession.copyWithResult(result);

    // Move to next card
    updatedSession = updatedSession.copyWithNextCard();

    // 해당 타입의 세션 업데이트
    if (itemType == 'word') {
      _wordSession = updatedSession;
    } else {
      _kanjiSession = updatedSession;
    }

    await _saveSession(updatedSession);

    // Record to study_records if session is completed
    if (updatedSession.isCompleted) {
      await _recordStudySession(updatedSession);
    }

    return updatedSession;
  }

  /// Skip current card without recording result
  Future<FlashcardSession> skipCard(String itemType) async {
    final currentSession = getSession(itemType);

    if (currentSession == null) {
      throw Exception('No active $itemType flashcard session');
    }

    final updatedSession = currentSession.copyWithNextCard();

    // 해당 타입의 세션 업데이트
    if (itemType == 'word') {
      _wordSession = updatedSession;
    } else {
      _kanjiSession = updatedSession;
    }

    await _saveSession(updatedSession);

    return updatedSession;
  }

  /// Record study session to Supabase
  Future<void> _recordStudySession(FlashcardSession session) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        debugPrint('No user logged in, skipping study record');
        return;
      }

      // Record each flashcard result as a study record
      for (final result in session.results) {
        final Map<String, dynamic> record = {
          'user_id': userId,
          'study_type': result.itemType,
          'study_date': result.timestamp.toIso8601String().split('T')[0],
          'study_status': result.isCorrect ? 'completed' : 'forgot',
          'created_at': result.timestamp.toIso8601String(),
        };

        // Add item-specific ID field
        if (result.itemType == 'word') {
          record['word_id'] = result.itemId;
        } else if (result.itemType == 'kanji') {
          record['kanji_id'] = result.itemId;
        }

        await _supabaseService.client.from('study_records').insert(record);
      }

      debugPrint(
        'Recorded ${session.results.length} ${session.itemType} flashcard results to study_records',
      );
    } catch (e) {
      debugPrint('Error recording study session: $e');
    }
  }

  /// Get session statistics
  Map<String, dynamic> getSessionStats(FlashcardSession session) {
    return {
      'total': session.itemIds.length,
      'completed': session.results.length,
      'correct': session.correctCount,
      'incorrect': session.incorrectCount,
      'remaining': session.itemIds.length - session.currentIndex,
      'accuracy': session.accuracyPercentage,
      'progress': session.progressPercentage,
    };
  }

  /// Resume or create new session
  Future<FlashcardSession?> resumeOrCreateSession(
    String itemType,
    List<int> itemIds,
  ) async {
    // Try to load existing session for this specific type
    final existingSession = await loadSessionByType(itemType);

    if (existingSession != null && !existingSession.isCompleted) {
      return existingSession;
    }

    // Create new session if no active session exists
    if (itemIds.isNotEmpty) {
      return await createSession(itemType, itemIds);
    }

    return null;
  }
}
