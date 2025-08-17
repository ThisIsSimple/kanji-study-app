import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import '../config/supabase_config.dart';
import '../models/models.dart';
import '../models/word_example_model.dart';
import '../models/study_record_model.dart';
import '../models/daily_study_stats.dart';

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
  
  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      
      // Trigger the Google Sign In process
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;
      
      if (accessToken == null || idToken == null) {
        throw Exception('Failed to get Google tokens');
      }
      
      // Store anonymous user ID if exists
      final anonymousUserId = currentUser?.id;
      final isAnonymous = currentUser?.isAnonymous ?? false;
      
      // Always sign in with Google OAuth
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      // If was anonymous, update the new user's metadata to indicate previous anonymous ID
      if (isAnonymous && anonymousUserId != null) {
        try {
          await _client.auth.updateUser(
            UserAttributes(
              data: {
                'previous_anonymous_id': anonymousUserId,
                'linked_from_anonymous': true,
              },
            ),
          );
          debugPrint('Linked Google account from anonymous user: $anonymousUserId');
          
          // TODO: Implement server-side data migration from anonymous to Google user
        } catch (e) {
          debugPrint('Failed to update user metadata after Google sign in: $e');
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      rethrow;
    }
  }
  
  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    try {
      // Check if Apple Sign In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign In is not available on this device');
      }
      
      // Request credential for Apple ID
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      final idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('Failed to get Apple ID token');
      }
      
      // Store anonymous user ID if exists
      final anonymousUserId = currentUser?.id;
      final isAnonymous = currentUser?.isAnonymous ?? false;
      
      // Always sign in with Apple OAuth
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );
      
      // If was anonymous, update the new user's metadata to indicate previous anonymous ID
      if (isAnonymous && anonymousUserId != null) {
        try {
          String? displayName;
          if (credential.givenName != null || credential.familyName != null) {
            displayName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
          }
          
          await _client.auth.updateUser(
            UserAttributes(
              data: {
                'previous_anonymous_id': anonymousUserId,
                'linked_from_anonymous': true,
                'username': displayName ?? credential.email?.split('@')[0] ?? 'Apple User',
              },
            ),
          );
          debugPrint('Linked Apple account from anonymous user: $anonymousUserId');
          
          // TODO: Implement server-side data migration from anonymous to Apple user
        } catch (e) {
          debugPrint('Failed to update user metadata after Apple sign in: $e');
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      rethrow;
    }
  }
  
  /// Sign in with Kakao
  Future<bool> signInWithKakao() async {
    try {
      // Check if KakaoTalk is installed
      bool isInstalled = await kakao.isKakaoTalkInstalled();
      
      if (isInstalled) {
        try {
          await kakao.UserApi.instance.loginWithKakaoTalk();
        } catch (e) {
          debugPrint('Failed to login with KakaoTalk: $e');
          // If login with KakaoTalk fails, try login with Kakao account
          await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        // Login with Kakao account (web browser)
        await kakao.UserApi.instance.loginWithKakaoAccount();
      }
      
      // Get user information from Kakao
      kakao.User kakaoUser = await kakao.UserApi.instance.me();
      debugPrint('Kakao user info: ${kakaoUser.id}, ${kakaoUser.kakaoAccount?.email}');
      
      // Check if user is currently anonymous
      final isAnonymous = currentUser?.isAnonymous ?? false;
      final anonymousUserId = currentUser?.id;
      
      if (isAnonymous && anonymousUserId != null) {
        debugPrint('Current user is anonymous, attempting to link with Kakao account');
        
        // Since Kakao is not a native Supabase provider, we need to use a different approach
        // Option 1: Use email/password with Kakao email (if available)
        final kakaoEmail = kakaoUser.kakaoAccount?.email;
        
        if (kakaoEmail != null && kakaoEmail.isNotEmpty) {
          try {
            // First, try to sign up with the Kakao email
            // Use Kakao ID as a pseudo-password (this should be handled more securely in production)
            final pseudoPassword = 'kakao_${kakaoUser.id}_user';
            
            // Try to sign in first in case user already exists
            try {
              await _client.auth.signInWithPassword(
                email: kakaoEmail,
                password: pseudoPassword,
              );
              debugPrint('Signed in with existing Kakao-linked account');
            } catch (signInError) {
              // If sign in fails, create new account
              await _client.auth.signUp(
                email: kakaoEmail,
                password: pseudoPassword,
                data: {
                  'provider': 'kakao',
                  'username': kakaoUser.kakaoAccount?.profile?.nickname ?? 'Kakao User',
                  'kakao_id': kakaoUser.id.toString(),
                  'previous_anonymous_id': anonymousUserId,
                },
              );
              debugPrint('Created new Kakao-linked account');
            }
            
            // TODO: Migrate anonymous user data to new account
            // This would require backend functions to transfer data from anonymous user to new user
            
            return true;
          } catch (e) {
            debugPrint('Failed to link Kakao account: $e');
            
            // Fallback: Just update the anonymous user's metadata
            await _client.auth.updateUser(
              UserAttributes(
                data: {
                  'provider': 'kakao',
                  'username': kakaoUser.kakaoAccount?.profile?.nickname ?? 'Kakao User',
                  'kakao_id': kakaoUser.id.toString(),
                  'kakao_email': kakaoEmail,
                },
              ),
            );
            debugPrint('Updated anonymous user metadata with Kakao info');
            return true;
          }
        } else {
          // No email available, just update metadata
          await _client.auth.updateUser(
            UserAttributes(
              data: {
                'provider': 'kakao',
                'username': kakaoUser.kakaoAccount?.profile?.nickname ?? 'Kakao User',
                'kakao_id': kakaoUser.id.toString(),
              },
            ),
          );
          debugPrint('Updated anonymous user metadata with Kakao info (no email)');
          return true;
        }
      } else {
        // Not anonymous, use regular OAuth flow if configured in Supabase
        // Note: This requires Kakao to be configured as a provider in Supabase
        debugPrint('User is not anonymous, using regular OAuth flow');
        await _client.auth.signInWithOAuth(
          OAuthProvider.kakao,
          authScreenLaunchMode: LaunchMode.inAppWebView,
        );
        return true;
      }
    } catch (e) {
      debugPrint('Kakao sign in error: $e');
      rethrow;
    }
  }
  
  /// Check if current user is anonymous
  bool get isAnonymousUser {
    return currentUser?.isAnonymous ?? false;
  }
  
  /// Get linked providers for current user
  List<String> get linkedProviders {
    final identities = currentUser?.appMetadata['providers'] as List<dynamic>?;
    return identities?.map((e) => e.toString()).toList() ?? [];
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
        createdAt: DateTime.now().toUtc(), // Save in UTC
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
  
  // ============= Calendar Methods =============
  
  /// Get daily study statistics for a date range
  Future<List<DailyStudyStats>> getDailyStudyStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!isLoggedIn) return [];
    
    try {
      // Convert local dates to UTC for querying
      final utcStartDate = DateTime(startDate.year, startDate.month, startDate.day).toUtc();
      final utcEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59).toUtc();
      
      // Get study records for the date range
      final response = await _client
          .from('study_records')
          .select()
          .eq('user_id', currentUser!.id)
          .gte('created_at', utcStartDate.toIso8601String())
          .lte('created_at', utcEndDate.toIso8601String())
          .order('created_at', ascending: true);
      
      final records = (response as List)
          .map((data) => StudyRecord.fromJson(data))
          .toList();
      
      // Group records by local date
      final Map<String, List<StudyRecord>> groupedRecords = {};
      for (final record in records) {
        // Use local time for grouping
        final localDate = record.createdAt!;
        final dateKey = '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
        if (!groupedRecords.containsKey(dateKey)) {
          groupedRecords[dateKey] = [];
        }
        groupedRecords[dateKey]!.add(record);
      }
      
      // Create DailyStudyStats for each date
      final List<DailyStudyStats> dailyStats = [];
      for (final entry in groupedRecords.entries) {
        final date = DateTime.parse(entry.key);
        final dayRecords = entry.value;
        
        int kanjiStudied = 0;
        int wordsStudied = 0;
        int totalCompleted = 0;
        int totalForgot = 0;
        final List<StudyItem> studyItems = [];
        
        // Track unique items studied
        final Set<String> uniqueKanji = {};
        final Set<String> uniqueWords = {};
        
        for (final record in dayRecords) {
          final itemKey = '${record.type.value}-${record.targetId}';
          
          if (record.type == StudyType.kanji && !uniqueKanji.contains(itemKey)) {
            uniqueKanji.add(itemKey);
            kanjiStudied++;
          } else if (record.type == StudyType.word && !uniqueWords.contains(itemKey)) {
            uniqueWords.add(itemKey);
            wordsStudied++;
          }
          
          if (record.status == StudyStatus.completed) {
            totalCompleted++;
          } else if (record.status == StudyStatus.forgot) {
            totalForgot++;
          }
          
          // Create StudyItem
          studyItems.add(StudyItem(
            id: record.targetId,
            type: record.type.value,
            name: '', // We'll need to fetch the actual names if needed
            status: record.status.value,
            studiedAt: record.createdAt!,
          ));
        }
        
        dailyStats.add(DailyStudyStats(
          date: date,
          kanjiStudied: kanjiStudied,
          wordsStudied: wordsStudied,
          totalCompleted: totalCompleted,
          totalForgot: totalForgot,
          studyItems: studyItems,
        ));
      }
      
      return dailyStats;
    } catch (e) {
      debugPrint('Error getting daily study stats: $e');
      return [];
    }
  }
  
  /// Get monthly study statistics
  Future<Map<DateTime, DailyStudyStats>> getMonthlyStudyStats({
    required int year,
    required int month,
  }) async {
    if (!isLoggedIn) return {};
    
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
      
      final dailyStats = await getDailyStudyStats(
        startDate: startDate,
        endDate: endDate,
      );
      
      final Map<DateTime, DailyStudyStats> statsMap = {};
      for (final stats in dailyStats) {
        // Normalize date to remove time component
        final normalizedDate = DateTime(stats.date.year, stats.date.month, stats.date.day);
        statsMap[normalizedDate] = stats;
      }
      
      return statsMap;
    } catch (e) {
      debugPrint('Error getting monthly study stats: $e');
      return {};
    }
  }
  
  /// Get weekly study statistics (for ProfileScreen)
  Future<List<DailyStudyStats>> getWeeklyStudyStats() async {
    if (!isLoggedIn) return [];
    
    try {
      final now = DateTime.now();
      final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      final endOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      
      return await getDailyStudyStats(
        startDate: startOfWeek,
        endDate: endOfWeek,
      );
    } catch (e) {
      debugPrint('Error getting weekly study stats: $e');
      return [];
    }
  }
  
  /// Get study items for a specific date with details
  Future<List<Map<String, dynamic>>> getDateStudyDetails(DateTime date) async {
    if (!isLoggedIn) return [];
    
    try {
      // Convert local date to UTC for querying
      final startOfDay = DateTime(date.year, date.month, date.day).toUtc();
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toUtc();
      
      // Get study records for the specific date
      final response = await _client
          .from('study_records')
          .select()
          .eq('user_id', currentUser!.id)
          .gte('created_at', startOfDay.toIso8601String())
          .lte('created_at', endOfDay.toIso8601String())
          .order('created_at', ascending: false);
      
      final records = (response as List)
          .map((data) => StudyRecord.fromJson(data))
          .toList();
      
      // Fetch details for each item
      final List<Map<String, dynamic>> detailedItems = [];
      
      for (final record in records) {
        Map<String, dynamic>? itemDetails;
        
        if (record.type == StudyType.kanji) {
          // Fetch kanji details
          final kanjiResponse = await _client
              .from('kanji')
              .select('character, meanings')
              .eq('id', record.targetId)
              .maybeSingle();
          
          if (kanjiResponse != null) {
            itemDetails = {
              'type': 'kanji',
              'character': kanjiResponse['character'],
              'meanings': (kanjiResponse['meanings'] as List).join(', '),
              'status': record.status.value,
              'studiedAt': record.createdAt!.toIso8601String(),
            };
          }
        } else if (record.type == StudyType.word) {
          // Fetch word details
          final wordResponse = await _client
              .from('words')
              .select('word, reading')
              .eq('id', record.targetId)
              .maybeSingle();
          
          if (wordResponse != null) {
            itemDetails = {
              'type': 'word',
              'word': wordResponse['word'],
              'reading': wordResponse['reading'],
              'status': record.status.value,
              'studiedAt': record.createdAt!.toIso8601String(),
            };
          }
        }
        
        if (itemDetails != null) {
          detailedItems.add(itemDetails);
        }
      }
      
      return detailedItems;
    } catch (e) {
      debugPrint('Error getting date study details: $e');
      return [];
    }
  }
}