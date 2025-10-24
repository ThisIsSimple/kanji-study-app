import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard_session_model.dart';
import 'supabase_service.dart';

class FlashcardService {
  static final FlashcardService _instance = FlashcardService._internal();
  static FlashcardService get instance => _instance;

  FlashcardService._internal();

  final SupabaseService _supabaseService = SupabaseService.instance;
  FlashcardSession? _currentSession;

  static const String _sessionKey = 'current_flashcard_session';

  /// Get current active session
  FlashcardSession? get currentSession => _currentSession;

  /// Check if there's an active session
  bool get hasActiveSession => _currentSession != null && !_currentSession!.isCompleted;

  /// Create a new flashcard session from a list of items
  Future<FlashcardSession> createSession(String itemType, List<int> itemIds) async {
    if (itemIds.isEmpty) {
      throw Exception('Cannot create flashcard session with empty item list');
    }

    final session = FlashcardSession(
      itemType: itemType,
      itemIds: itemIds,
      startTime: DateTime.now(),
    );

    _currentSession = session;
    await _saveSession(session);

    debugPrint('Created flashcard session with ${itemIds.length} $itemType items');
    return session;
  }

  /// Load saved session from storage
  Future<FlashcardSession?> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_sessionKey);

      if (sessionJson != null) {
        final session = FlashcardSession.fromJsonString(sessionJson);
        _currentSession = session;
        debugPrint('Loaded flashcard session with ${session.itemIds.length} ${session.itemType} items');
        return session;
      }
    } catch (e) {
      debugPrint('Error loading flashcard session: $e');
    }

    return null;
  }

  /// Save session to storage
  Future<void> _saveSession(FlashcardSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, session.toJsonString());
    } catch (e) {
      debugPrint('Error saving flashcard session: $e');
    }
  }

  /// Clear current session
  Future<void> clearSession() async {
    _currentSession = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    debugPrint('Cleared flashcard session');
  }

  /// Record a flashcard result and move to next card
  Future<FlashcardSession> recordResult({
    required int itemId,
    required bool isCorrect,
  }) async {
    if (_currentSession == null) {
      throw Exception('No active flashcard session');
    }

    final result = FlashcardResult(
      itemType: _currentSession!.itemType,
      itemId: itemId,
      isCorrect: isCorrect,
      timestamp: DateTime.now(),
    );

    // Add result to session
    var updatedSession = _currentSession!.copyWithResult(result);

    // Move to next card
    updatedSession = updatedSession.copyWithNextCard();

    _currentSession = updatedSession;
    await _saveSession(updatedSession);

    // Record to study_records if session is completed
    if (updatedSession.isCompleted) {
      await _recordStudySession(updatedSession);
    }

    return updatedSession;
  }

  /// Skip current card without recording result
  Future<FlashcardSession> skipCard() async {
    if (_currentSession == null) {
      throw Exception('No active flashcard session');
    }

    final updatedSession = _currentSession!.copyWithNextCard();
    _currentSession = updatedSession;
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

      debugPrint('Recorded ${session.results.length} ${session.itemType} flashcard results to study_records');
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
  Future<FlashcardSession?> resumeOrCreateSession(String itemType, List<int> itemIds) async {
    // Try to load existing session
    final existingSession = await loadSession();

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
