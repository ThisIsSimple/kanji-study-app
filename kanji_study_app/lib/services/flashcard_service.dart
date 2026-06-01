import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard_session_model.dart';
import '../models/study_record_model.dart';
import 'connectivity_service.dart';
import 'connectivity_sync_helper.dart';
import 'supabase_service.dart';
import 'study_record_service.dart';

class FlashcardService {
  static final FlashcardService _instance = FlashcardService._internal();
  static FlashcardService get instance => _instance;

  FlashcardService._internal();

  final SupabaseService _supabaseService = SupabaseService.instance;
  final StudyRecordService _studyRecordService = StudyRecordService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  late final ConnectivitySyncHelper _syncHelper = ConnectivitySyncHelper(
    label: 'FlashcardService',
    onReconnect: syncPendingFlashcardSessions,
    connectivityService: _connectivityService,
  );

  static const _pendingSessionsKey = 'pending_flashcard_sessions';

  // 단어와 한자 세션을 각각 독립적으로 관리
  FlashcardSession? _wordSession;
  FlashcardSession? _kanjiSession;
  bool _isInitialized = false;
  bool _isSyncingPendingSessions = false;
  Future<void> _pendingQueueTail = Future.value();

  // itemType별로 다른 키 사용
  String _getSessionKey(String itemType) => 'flashcard_session_$itemType';

  Future<void> initialize() async {
    if (!_isInitialized) {
      _isInitialized = true;
      _syncHelper.listen();
    }
    await syncPendingFlashcardSessions();
  }

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
      sessionClientId: _createSessionClientId(),
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
        var session = FlashcardSession.fromJsonString(sessionJson);
        if (session.sessionClientId == null) {
          session = _withSessionClientId(session);
          await _saveSession(session);
        }

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

  /// Save session to storage
  Future<void> _saveSession(FlashcardSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = _getSessionKey(session.itemType);
      await prefs.setString(sessionKey, session.toJsonString());
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
  }

  /// Clear all sessions
  Future<void> clearAllSessions() async {
    _wordSession = null;
    _kanjiSession = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getSessionKey('word'));
    await prefs.remove(_getSessionKey('kanji'));
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

      // Record each flashcard result using StudyRecordService
      // This updates local DB + memory cache + Supabase (if online)
      for (final result in session.results) {
        await _studyRecordService.addRecord(
          type: StudyType.fromString(result.itemType),
          targetId: result.itemId,
          status: result.isCorrect ? StudyStatus.completed : StudyStatus.forgot,
        );
      }

      debugPrint(
        'Recorded ${session.results.length} ${session.itemType} flashcard results to study_records',
      );

      // Also save to flashcard_sessions table for detailed history
      final sessionWithClientId = _withSessionClientId(session);
      final savedRemotely = await _saveFlashcardSessionToServer(
        userId,
        sessionWithClientId,
      );
      if (!savedRemotely) {
        await _enqueuePendingCompletedSession(userId, sessionWithClientId);
      }
    } catch (e) {
      debugPrint('Error recording study session: $e');
    }
  }

  /// Save flashcard session and results to Supabase (flashcard_sessions, flashcard_results tables)
  Future<bool> _saveFlashcardSessionToServer(
    String userId,
    FlashcardSession session,
  ) async {
    try {
      final client = _supabaseService.client;
      final sessionWithClientId = _withSessionClientId(session);

      final sessionData = await client
          .from('flashcard_sessions')
          .upsert({
            'user_id': userId,
            'session_client_id': sessionWithClientId.sessionClientId,
            'item_type': sessionWithClientId.itemType,
            'total_count': sessionWithClientId.itemIds.length,
            'correct_count': sessionWithClientId.correctCount,
            'incorrect_count': sessionWithClientId.incorrectCount,
            'started_at': sessionWithClientId.startTime.toIso8601String(),
            'completed_at': sessionWithClientId.endTime?.toIso8601String(),
          }, onConflict: 'user_id,session_client_id')
          .select('id')
          .single();

      final sessionId = sessionData['id'] as int;

      await client
          .from('flashcard_results')
          .delete()
          .eq('session_id', sessionId);

      if (sessionWithClientId.results.isNotEmpty) {
        final resultsData = sessionWithClientId.results
            .map(
              (result) => {
                'session_id': sessionId,
                'target_id': result.itemId,
                'is_correct': result.isCorrect,
                'answered_at': result.timestamp.toIso8601String(),
              },
            )
            .toList();

        await client.from('flashcard_results').insert(resultsData);
      }

      debugPrint(
        'Saved flashcard session (id: $sessionId, client: ${sessionWithClientId.sessionClientId}) with ${sessionWithClientId.results.length} results to server',
      );
      return true;
    } catch (e) {
      debugPrint('Error saving flashcard session to server: $e');
      return false;
    }
  }

  Future<void> syncPendingFlashcardSessions() async {
    if (_isSyncingPendingSessions) return;
    if (!_connectivityService.isOnline || !_supabaseService.isInitialized) {
      return;
    }

    final currentUserId = _supabaseService.currentUser?.id;
    if (currentUserId == null) return;

    _isSyncingPendingSessions = true;
    try {
      final pendingSessions = await _loadPendingCompletedSessions();
      if (pendingSessions.isEmpty) return;

      final syncedSessionClientIds = <String>{};
      for (final pending in pendingSessions) {
        if (pending.userId != currentUserId) {
          continue;
        }

        final saved = await _saveFlashcardSessionToServer(
          pending.userId,
          pending.session,
        );
        if (saved) {
          syncedSessionClientIds.add(pending.sessionClientId);
        }
      }

      if (syncedSessionClientIds.isNotEmpty) {
        await _removeSyncedPendingCompletedSessions(
          currentUserId,
          syncedSessionClientIds,
        );
      }
    } finally {
      _isSyncingPendingSessions = false;
    }
  }

  /// Fetch user's flashcard session history from server
  Future<List<Map<String, dynamic>>> getFlashcardHistory({
    String? itemType,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        return [];
      }

      final query = _supabaseService.client
          .from('flashcard_sessions')
          .select()
          .eq('user_id', userId);

      // Apply item_type filter if specified
      final filteredQuery = itemType != null
          ? query.eq('item_type', itemType)
          : query;

      final data = await filteredQuery
          .order('started_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching flashcard history: $e');
      return [];
    }
  }

  /// Fetch detailed results for a specific session
  Future<List<Map<String, dynamic>>> getSessionResults(int sessionId) async {
    try {
      final data = await _supabaseService.client
          .from('flashcard_results')
          .select()
          .eq('session_id', sessionId)
          .order('answered_at');

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching session results: $e');
      return [];
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

  Future<void> _enqueuePendingCompletedSession(
    String userId,
    FlashcardSession session,
  ) async {
    final sessionWithClientId = _withSessionClientId(session);
    await _withPendingQueueLock(() async {
      final pendingSessions = await _loadPendingCompletedSessions();
      final pending = _PendingFlashcardSession(
        userId: userId,
        session: sessionWithClientId,
      );

      final existingIndex = pendingSessions.indexWhere(
        (item) => item.sessionClientId == pending.sessionClientId,
      );
      if (existingIndex >= 0) {
        pendingSessions[existingIndex] = pending;
      } else {
        pendingSessions.add(pending);
      }

      await _savePendingCompletedSessions(pendingSessions);
    });
  }

  Future<void> _removeSyncedPendingCompletedSessions(
    String userId,
    Set<String> syncedSessionClientIds,
  ) async {
    if (syncedSessionClientIds.isEmpty) return;

    await _withPendingQueueLock(() async {
      final pendingSessions = await _loadPendingCompletedSessions();
      final remaining = pendingSessions.where((pending) {
        if (pending.userId != userId) return true;
        return !syncedSessionClientIds.contains(pending.sessionClientId);
      }).toList();

      await _savePendingCompletedSessions(remaining);
    });
  }

  Future<T> _withPendingQueueLock<T>(Future<T> Function() action) {
    final run = _pendingQueueTail.then((_) => action());
    _pendingQueueTail = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  Future<List<_PendingFlashcardSession>> _loadPendingCompletedSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedSessions = prefs.getStringList(_pendingSessionsKey) ?? [];
    final pendingSessions = <_PendingFlashcardSession>[];

    for (final encoded in encodedSessions) {
      try {
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;
        pendingSessions.add(_PendingFlashcardSession.fromJson(decoded));
      } catch (e) {
        debugPrint('Error parsing pending flashcard session: $e');
      }
    }

    return pendingSessions;
  }

  Future<void> _savePendingCompletedSessions(
    List<_PendingFlashcardSession> pendingSessions,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (pendingSessions.isEmpty) {
      await prefs.remove(_pendingSessionsKey);
      return;
    }

    await prefs.setStringList(
      _pendingSessionsKey,
      pendingSessions.map((pending) => jsonEncode(pending.toJson())).toList(),
    );
  }

  FlashcardSession _withSessionClientId(FlashcardSession session) {
    final existing = session.sessionClientId;
    if (existing != null && existing.isNotEmpty) return session;
    return session.copyWithSessionClientId(_createSessionClientId());
  }

  String _createSessionClientId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    return 'flashcard-${DateTime.now().microsecondsSinceEpoch}-${hex.join()}';
  }

  @visibleForTesting
  Future<void> enqueuePendingCompletedSessionForTest(
    String userId,
    FlashcardSession session,
  ) => _enqueuePendingCompletedSession(userId, session);

  @visibleForTesting
  Future<void> removeSyncedPendingCompletedSessionsForTest(
    String userId,
    Set<String> syncedSessionClientIds,
  ) => _removeSyncedPendingCompletedSessions(userId, syncedSessionClientIds);

  @visibleForTesting
  Future<List<Map<String, dynamic>>>
  loadPendingCompletedSessionsForTest() async {
    final pendingSessions = await _loadPendingCompletedSessions();
    return pendingSessions.map((pending) => pending.toJson()).toList();
  }
}

class _PendingFlashcardSession {
  const _PendingFlashcardSession({required this.userId, required this.session});

  final String userId;
  final FlashcardSession session;

  String get sessionClientId => session.sessionClientId ?? '';

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'session': session.toJson()};
  }

  factory _PendingFlashcardSession.fromJson(Map<String, dynamic> json) {
    return _PendingFlashcardSession(
      userId: json['userId'] as String,
      session: FlashcardSession.fromJson(
        json['session'] as Map<String, dynamic>,
      ),
    );
  }
}
