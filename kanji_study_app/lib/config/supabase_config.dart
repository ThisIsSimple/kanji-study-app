/// Supabase configuration constants
class SupabaseConfig {
  // Supabase URL and Anon Key
  static const String supabaseUrl = 'https://kasxghygpyiyxsjzhomn.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_0d_TYnZ1PBpAkuJW5sgmuA_Kfu6EtYr';
  
  // Table names
  static const String usersTable = 'users';
  static const String userProgressTable = 'user_progress';
  static const String kanjiExamplesTable = 'kanji_examples';
  static const String studySessionsTable = 'study_sessions';
  static const String quizResultsTable = 'quiz_results';
  
  // Storage buckets
  static const String profilePicturesBucket = 'profile-pictures';
  static const String studyMaterialsBucket = 'study-materials';
}