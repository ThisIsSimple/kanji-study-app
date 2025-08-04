import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/kanji_example.dart';
import '../models/user_progress.dart';

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
        'hiragana': example.hiragana,
        'korean': example.korean,
        'source': example.source ?? 'gemini',
        'created_at': example.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      }).toList();
      
      await _client.from(SupabaseConfig.kanjiExamplesTable).insert(data);
    } catch (e) {
      debugPrint('Error saving kanji examples: $e');
      rethrow;
    }
  }
  
  /// Get kanji examples from database
  Future<List<KanjiExample>> getKanjiExamples(String character) async {
    if (!isLoggedIn) return [];
    
    try {
      final response = await _client
          .from(SupabaseConfig.kanjiExamplesTable)
          .select()
          .eq('user_id', currentUser!.id)
          .eq('kanji_character', character)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((data) => KanjiExample(
                japanese: data['japanese'],
                hiragana: data['hiragana'],
                korean: data['korean'],
                source: data['source'],
                createdAt: data['created_at'] != null 
                    ? DateTime.parse(data['created_at']) 
                    : null,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error getting kanji examples: $e');
      rethrow;
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
}