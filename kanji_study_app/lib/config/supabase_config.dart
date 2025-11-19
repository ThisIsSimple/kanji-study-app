/// Supabase configuration constants
class SupabaseConfig {
  // Supabase URL and Anon Key
  static const String supabaseUrl = 'https://kasxghygpyiyxsjzhomn.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_0d_TYnZ1PBpAkuJW5sgmuA_Kfu6EtYr';

  // Table names
  static const String usersTable = 'users';
  static const String userProgressTable = 'user_progress';
  static const String kanjiTable = 'kanji';
  static const String kanjiExamplesTable = 'kanji_examples';
  static const String studySessionsTable = 'study_sessions';
  static const String studyRecordsTable = 'study_records';
  static const String quizSetsTable = 'quiz_sets';
  static const String quizQuestionsTable = 'quiz_questions';
  static const String quizAttemptsTable = 'quiz_attempts';
  static const String quizAnswersTable = 'quiz_answers';
  static const String audioFilesTable = 'audio_files';

  // Home Dashboard tables
  static const String achievementsTable = 'achievements';
  static const String userAchievementsTable = 'user_achievements';
  static const String dailyGoalsTable = 'daily_goals';

  // Views
  static const String leaderboardWeeklyView = 'leaderboard_weekly';

  // Storage buckets
  static const String profilePicturesBucket = 'profile-pictures';
  static const String studyMaterialsBucket = 'study-materials';
}
