import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';
import '../models/word_example_model.dart';
import '../models/study_record_model.dart';

/// Singleton service for managing Supabase operations
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  static SupabaseService get instance => _instance;
  
  SupabaseService._internal();
  
  late final SupabaseClient _client;
  
  /// Get the Supabase client
  SupabaseClient get client => _client;
  
  /// Get the current user
  User? get currentUser => _client.auth.currentUser;
  
  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;
  
  /// Initialize Supabase
  Future<void> init() async {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
      rethrow;
    }
  }
  
  // ============= Auth Methods =============
  
  /// Sign in anonymously
  Future<AuthResponse> signInAnonymously() async {
    try {
      final response = await _client.auth.signInAnonymously();
      return response;
    } catch (e) {
      debugPrint('Anonymous sign in error: $e');
      rethrow;
    }
  }
  
  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: username != null ? {'username': username} : null,
      );
      return response;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }
  
  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }
  
  /// Listen to auth state changes
  Stream<AuthState> authStateChanges() {
    return _client.auth.onAuthStateChange;
  }
  
  // ============= User Progress Methods =============
  
  /// Save user progress to database
  Future<void> saveUserProgress(UserProgress progress) async {
    if (!isLoggedIn) return;
    
    try {
      await _client.from(SupabaseConfig.userProgressTable).upsert({
        'user_id': currentUser!.id,
        'kanji_character': progress.kanjiCharacter,
        'last_studied': progress.lastStudied.toIso8601String(),
        'study_count': progress.studyCount,
        'mastered': progress.mastered,
      });
    } catch (e) {
      debugPrint('Error saving user progress: $e');
      rethrow;
    }
  }
  
  /// Get all user progress
  Future<List<UserProgress>> getUserProgress() async {
    if (!isLoggedIn) return [];
    
    try {
      final response = await _client
          .from(SupabaseConfig.userProgressTable)
          .select()
          .eq('user_id', currentUser!.id);
      
      return (response as List)
          .map((data) => UserProgress(
                kanjiCharacter: data['kanji_character'],
                lastStudied: DateTime.parse(data['last_studied']),
                studyCount: data['study_count'],
                mastered: data['mastered'],
              ))
          .toList();
    } catch (e) {
      debugPrint('Error getting user progress: $e');
      rethrow;
    }
  }
  
  /// Get progress for specific kanji
  Future<UserProgress?> getKanjiProgress(String character) async {
    if (!isLoggedIn) return null;
    
    try {
      final response = await _client
          .from(SupabaseConfig.userProgressTable)
          .select()
          .eq('user_id', currentUser!.id)
          .eq('kanji_character', character)
          .maybeSingle();
      
      if (response == null) return null;
      
      return UserProgress(
        kanjiCharacter: response['kanji_character'],
        lastStudied: DateTime.parse(response['last_studied']),
        studyCount: response['study_count'],
        mastered: response['mastered'],
      );
    } catch (e) {
      debugPrint('Error getting kanji progress: $e');
      rethrow;
    }
  }
  
  // ============= Kanji Examples Methods =============
  
  /// Save generated kanji examples to database
  Future<void> saveKanjiExamples(String character, List<KanjiExample> examples) async {
    if (!isLoggedIn) return;
    
    try {
      final data = examples.map((example) => {
        'user_id': currentUser!.id,
        'kanji_character': character,
        'japanese': example.japanese,
        'furigana': example.furigana,
        'korean': example.korean,
        'explanation': example.explanation,
        'source': example.source ?? 'gemini',
        'created_at': example.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      }).toList();
      
      await _client.from(SupabaseConfig.kanjiExamplesTable).insert(data);
    } catch (e) {
      debugPrint('Error saving kanji examples: $e');
      rethrow;
    }
  }
  
  /// Get kanji examples from database by kanji_id
  Future<List<KanjiExample>> getKanjiExamples(int kanjiId) async {
    try {
      // Get both public examples and user's own examples
      var query = _client
          .from(SupabaseConfig.kanjiExamplesTable)
          .select()
          .eq('kanji_id', kanjiId);
      
      // If logged in, get user's examples and public examples
      // If not logged in, only get public examples (user_id is null)
      if (isLoggedIn) {
        query = query.or('user_id.eq.${currentUser!.id},user_id.is.null');
      } else {
        query = query.isFilter('user_id', null);
      }
      
      final response = await query.order('created_at', ascending: false);
      
      return (response as List)
          .map((data) => KanjiExample(
                japanese: data['japanese'],
                furigana: data['furigana'] ?? data['hiragana'] ?? '', // DB에서 furigana 컬럼 사용
                korean: data['korean'],
                explanation: data['explanation'],
                source: data['source'],
                createdAt: data['created_at'] != null 
                    ? DateTime.parse(data['created_at']) 
                    : null,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error getting kanji examples: $e');
      return []; // Return empty list instead of rethrowing
    }
  }
  
  /// Get word examples from database by word_id
  Future<List<WordExample>> getWordExamples(int wordId) async {
    try {
      // Get both public examples and user's own examples
      var query = _client
          .from('word_examples')
          .select()
          .eq('word_id', wordId);
      
      // If logged in, get user's examples and public examples
      // If not logged in, only get public examples (user_id is null)
      if (isLoggedIn) {
        query = query.or('user_id.eq.${currentUser!.id},user_id.is.null');
      } else {
        query = query.isFilter('user_id', null);
      }
      
      final response = await query.order('created_at', ascending: false);
      
      return (response as List)
          .map((data) => WordExample.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error getting word examples: $e');
      return [];
    }
  }
  
  // ============= Study Session Methods =============
  
  /// Record a study session
  Future<void> recordStudySession({
    required DateTime startTime,
    required DateTime endTime,
    required int kanjiStudied,
    required int kanjiMastered,
  }) async {
    if (!isLoggedIn) return;
    
    try {
      await _client.from(SupabaseConfig.studySessionsTable).insert({
        'user_id': currentUser!.id,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'kanji_studied': kanjiStudied,
        'kanji_mastered': kanjiMastered,
        'duration_minutes': endTime.difference(startTime).inMinutes,
      });
    } catch (e) {
      debugPrint('Error recording study session: $e');
      rethrow;
    }
  }
  
  /// Get study statistics
  Future<Map<String, dynamic>> getStudyStatistics() async {
    if (!isLoggedIn) return {};
    
    try {
      // Get total study sessions
      final sessionsResponse = await _client
          .from(SupabaseConfig.studySessionsTable)
          .select('count')
          .eq('user_id', currentUser!.id)
          .single();
      
      // Get total study time
      final timeResponse = await _client
          .from(SupabaseConfig.studySessionsTable)
          .select('duration_minutes')
          .eq('user_id', currentUser!.id);
      
      int totalMinutes = 0;
      for (final session in timeResponse as List) {
        totalMinutes += (session['duration_minutes'] as int?) ?? 0;
      }
      
      // Get streak (consecutive days)
      final streakResponse = await _client
          .from(SupabaseConfig.studySessionsTable)
          .select('start_time')
          .eq('user_id', currentUser!.id)
          .order('start_time', ascending: false);
      
      int streak = 0;
      final streakList = streakResponse as List;
      if (streakList.isNotEmpty) {
        DateTime? lastDate;
        for (final session in streakList) {
          final sessionDate = DateTime.parse(session['start_time']).toLocal();
          if (lastDate == null) {
            streak = 1;
            lastDate = sessionDate;
          } else {
            final dayDiff = lastDate.difference(sessionDate).inDays;
            if (dayDiff == 1) {
              streak++;
              lastDate = sessionDate;
            } else {
              break;
            }
          }
        }
      }
      
      return {
        'total_sessions': sessionsResponse['count'] ?? 0,
        'total_minutes': totalMinutes,
        'streak_days': streak,
      };
    } catch (e) {
      debugPrint('Error getting study statistics: $e');
      return {};
    }
  }
  
  // ============= User Profile Methods =============
  
  /// Update user profile
  Future<void> updateUserProfile({
    String? username,
    String? avatarUrl,
  }) async {
    if (!isLoggedIn) return;
    
    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      
      await _client.from(SupabaseConfig.usersTable).upsert({
        'id': currentUser!.id,
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }
  
  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isLoggedIn) return null;
    
    try {
      final response = await _client
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();
      
      return response;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }
  
  // ============= Quiz Methods =============
  
  /// Create a new quiz set
  Future<QuizSet?> createQuizSet({
    required String title,
    String? description,
    int? difficultyLevel,
    String? category,
    required List<int> kanjiIds,
    bool isPublic = false,
  }) async {
    if (!isLoggedIn) return null;
    
    try {
      final data = {
        'title': title,
        'description': description,
        'created_by': currentUser!.id,
        'difficulty_level': difficultyLevel,
        'category': category,
        'kanji_ids': kanjiIds,
        'is_public': isPublic,
      };
      
      final response = await _client
          .from(SupabaseConfig.quizSetsTable)
          .insert(data)
          .select()
          .single();
      
      return QuizSet.fromJson(response);
    } catch (e) {
      debugPrint('Error creating quiz set: $e');
      rethrow;
    }
  }
  
  /// Get public quiz sets and user's own quiz sets
  Future<List<QuizSet>> getQuizSets({String? category}) async {
    try {
      var query = _client.from(SupabaseConfig.quizSetsTable).select();
      
      if (category != null) {
        query = query.eq('category', category);
      }
      
      if (isLoggedIn) {
        query = query.or('is_public.eq.true,created_by.eq.${currentUser!.id}');
      } else {
        query = query.eq('is_public', true);
      }
      
      final response = await query.order('created_at', ascending: false);
      
      return (response as List).map((data) => QuizSet.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error getting quiz sets: $e');
      rethrow;
    }
  }
  
  /// Get quiz questions for a quiz set
  Future<List<QuizQuestion>> getQuizQuestions(int quizSetId) async {
    try {
      final response = await _client
          .from(SupabaseConfig.quizQuestionsTable)
          .select()
          .eq('quiz_set_id', quizSetId)
          .order('order_index');
      
      return (response as List).map((data) => QuizQuestion.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error getting quiz questions: $e');
      rethrow;
    }
  }
  
  /// Create quiz questions
  Future<void> createQuizQuestions(List<QuizQuestion> questions) async {
    if (!isLoggedIn) return;
    
    try {
      final data = questions.map((q) => q.toJsonForCreate()).toList();
      await _client.from(SupabaseConfig.quizQuestionsTable).insert(data);
    } catch (e) {
      debugPrint('Error creating quiz questions: $e');
      rethrow;
    }
  }
  
  /// Start a quiz attempt
  Future<QuizAttempt?> startQuizAttempt(int quizSetId) async {
    if (!isLoggedIn) return null;
    
    try {
      final data = {
        'user_id': currentUser!.id,
        'quiz_set_id': quizSetId,
      };
      
      final response = await _client
          .from(SupabaseConfig.quizAttemptsTable)
          .insert(data)
          .select()
          .single();
      
      return QuizAttempt.fromJson(response);
    } catch (e) {
      debugPrint('Error starting quiz attempt: $e');
      rethrow;
    }
  }
  
  /// Complete a quiz attempt
  Future<void> completeQuizAttempt({
    required int attemptId,
    required int score,
    required int totalPoints,
    required int timeTakenSeconds,
  }) async {
    if (!isLoggedIn) return;
    
    try {
      final data = {
        'completed_at': DateTime.now().toIso8601String(),
        'score': score,
        'total_points': totalPoints,
        'time_taken_seconds': timeTakenSeconds,
      };
      
      await _client
          .from(SupabaseConfig.quizAttemptsTable)
          .update(data)
          .eq('id', attemptId);
    } catch (e) {
      debugPrint('Error completing quiz attempt: $e');
      rethrow;
    }
  }
  
  /// Save quiz answer
  Future<void> saveQuizAnswer(QuizAnswer answer) async {
    if (!isLoggedIn) return;
    
    try {
      await _client
          .from(SupabaseConfig.quizAnswersTable)
          .insert(answer.toJsonForCreate());
    } catch (e) {
      debugPrint('Error saving quiz answer: $e');
      rethrow;
    }
  }
  
  /// Get user's quiz attempts
  Future<List<QuizAttempt>> getUserQuizAttempts({int? quizSetId}) async {
    if (!isLoggedIn) return [];
    
    try {
      var query = _client
          .from(SupabaseConfig.quizAttemptsTable)
          .select()
          .eq('user_id', currentUser!.id);
      
      if (quizSetId != null) {
        query = query.eq('quiz_set_id', quizSetId);
      }
      
      final response = await query.order('started_at', ascending: false);
      
      return (response as List).map((data) => QuizAttempt.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error getting user quiz attempts: $e');
      rethrow;
    }
  }
  
  /// Get quiz answers for an attempt
  Future<List<QuizAnswer>> getQuizAnswers(int attemptId) async {
    if (!isLoggedIn) return [];
    
    try {
      final response = await _client
          .from(SupabaseConfig.quizAnswersTable)
          .select()
          .eq('attempt_id', attemptId)
          .order('answered_at');
      
      return (response as List).map((data) => QuizAnswer.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error getting quiz answers: $e');
      rethrow;
    }
  }
  
  /// Get all kanji from database
  Future<List<Map<String, dynamic>>> getAllKanji({int? grade, int? jlpt}) async {
    try {
      var query = _client.from(SupabaseConfig.kanjiTable)
          .select('*, korean_on_readings, korean_kun_readings');
      
      if (grade != null) {
        query = query.eq('grade', grade);
      }
      
      if (jlpt != null) {
        query = query.eq('jlpt', jlpt);
      }
      
      final response = await query.order('id', ascending: true);
      
      // Transform data to match expected format
      final List<Map<String, dynamic>> result = [];
      for (final item in response as List) {
        result.add({
          'id': item['id'],
          'character': item['character'],
          'meanings': item['meanings'],
          'readings': {
            'on': item['on_readings'] ?? [],
            'kun': item['kun_readings'] ?? [],
          },
          'korean_on_readings': item['korean_on_readings'] ?? [],
          'korean_kun_readings': item['korean_kun_readings'] ?? [],
          'grade': item['grade'],
          'jlpt': item['jlpt'],
          'strokeCount': item['stroke_count'],
          'frequency': item['frequency'],
          'examples': [],
        });
      }
      
      return result;
    } catch (e) {
      debugPrint('Error getting all kanji: $e');
      rethrow;
    }
  }
  
  // ============= Study Records Methods =============
  
  /// Record a study session for a kanji or word
  Future<void> recordStudy({
    required StudyType type,
    required int targetId,
    required StudyStatus status,
    String? notes,
  }) async {
    if (!isLoggedIn) return;
    
    try {
      final record = StudyRecord(
        userId: currentUser!.id,
        type: type,
        targetId: targetId,
        status: status,
        notes: notes,
      );
      
      await _client.from('study_records').insert(record.toJsonForCreate());
    } catch (e) {
      debugPrint('Error recording study: $e');
      rethrow;
    }
  }
  
  /// Get all study records for current user
  Future<List<StudyRecord>> getStudyRecords({
    StudyType? type,
    int? targetId,
    StudyStatus? status,
    int? limit,
  }) async {
    if (!isLoggedIn) return [];
    
    try {
      var query = _client
          .from('study_records')
          .select()
          .eq('user_id', currentUser!.id);
      
      if (type != null) {
        query = query.eq('type', type.value);
      }
      
      if (targetId != null) {
        query = query.eq('target_id', targetId);
      }
      
      if (status != null) {
        query = query.eq('status', status.value);
      }
      
      // Apply ordering and limit in one chain
      final finalQuery = limit != null 
          ? query.order('created_at', ascending: false).limit(limit)
          : query.order('created_at', ascending: false);
      
      final response = await finalQuery;
      
      return (response as List)
          .map((data) => StudyRecord.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error getting study records: $e');
      return [];
    }
  }
  
  /// Get study statistics for a specific kanji or word
  Future<StudyStats?> getStudyStats({
    required StudyType type,
    required int targetId,
  }) async {
    if (!isLoggedIn) return null;
    
    try {
      final records = await getStudyRecords(
        type: type,
        targetId: targetId,
      );
      
      if (records.isEmpty) {
        return StudyStats(
          targetId: targetId,
          type: type,
          totalRecords: 0,
          completedCount: 0,
          forgotCount: 0,
          reviewingCount: 0,
          masteredCount: 0,
          recentRecords: [],
        );
      }
      
      int completedCount = 0;
      int forgotCount = 0;
      int reviewingCount = 0;
      int masteredCount = 0;
      
      for (final record in records) {
        switch (record.status) {
          case StudyStatus.completed:
            completedCount++;
            break;
          case StudyStatus.forgot:
            forgotCount++;
            break;
          case StudyStatus.reviewing:
            reviewingCount++;
            break;
          case StudyStatus.mastered:
            masteredCount++;
            break;
        }
      }
      
      return StudyStats(
        targetId: targetId,
        type: type,
        totalRecords: records.length,
        completedCount: completedCount,
        forgotCount: forgotCount,
        reviewingCount: reviewingCount,
        masteredCount: masteredCount,
        firstStudied: records.last.createdAt,
        lastStudied: records.first.createdAt,
        recentRecords: records.take(10).toList(),
      );
    } catch (e) {
      debugPrint('Error getting study stats: $e');
      return null;
    }
  }
  
  /// Get recent study records for all items
  Future<Map<String, StudyStatus>> getRecentStudyStatuses({
    required StudyType type,
    required List<int> targetIds,
  }) async {
    if (!isLoggedIn || targetIds.isEmpty) return {};
    
    try {
      final response = await _client
          .from('study_records')
          .select()
          .eq('user_id', currentUser!.id)
          .eq('type', type.value)
          .inFilter('target_id', targetIds)
          .order('created_at', ascending: false);
      
      final records = (response as List)
          .map((data) => StudyRecord.fromJson(data))
          .toList();
      
      // Group by target_id and get the most recent status
      final Map<String, StudyStatus> statuses = {};
      for (final record in records) {
        final key = '${record.targetId}';
        if (!statuses.containsKey(key)) {
          statuses[key] = record.status;
        }
      }
      
      return statuses;
    } catch (e) {
      debugPrint('Error getting recent study statuses: $e');
      return {};
    }
  }
  
  /// Delete a study record
  Future<void> deleteStudyRecord(int recordId) async {
    if (!isLoggedIn) return;
    
    try {
      await _client
          .from('study_records')
          .delete()
          .eq('id', recordId)
          .eq('user_id', currentUser!.id);
    } catch (e) {
      debugPrint('Error deleting study record: $e');
      rethrow;
    }
  }
}