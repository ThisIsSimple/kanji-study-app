import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/date_symbol_data_local.dart';
import 'services/notification_service.dart';
import 'services/gemini_service.dart';
import 'services/supabase_service.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';
import 'utils/nickname_generator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone
  tz.initializeTimeZones();
  
  // Initialize date formatting for Korean locale
  await initializeDateFormatting('ko_KR', null);
  
  // Initialize Supabase
  await SupabaseService.instance.init();
  
  // Handle anonymous authentication and nickname generation
  final supabaseService = SupabaseService.instance;
  
  // 1. Check if user has a session, if not, sign in anonymously
  if (!supabaseService.isLoggedIn) {
    try {
      await supabaseService.signInAnonymously();
      debugPrint('Signed in anonymously');
    } catch (e) {
      debugPrint('Failed to sign in anonymously: $e');
    }
  }
  
  // 2. Check if user has a nickname (for both new and existing anonymous users)
  if (supabaseService.isLoggedIn) {
    try {
      debugPrint('Checking user profile for nickname...');
      debugPrint('Current user ID: ${supabaseService.currentUser?.id}');
      
      final profile = await supabaseService.getUserProfile();
      debugPrint('Retrieved profile: $profile');
      
      // 3. Generate nickname if user doesn't have one
      if (profile == null || profile['username'] == null || profile['username'].toString().isEmpty) {
        debugPrint('No nickname found, generating new one...');
        final userId = supabaseService.currentUser!.id;
        final nickname = NicknameGenerator.instance.generate(userId);
        debugPrint('Generated nickname: $nickname');
        
        try {
          await supabaseService.updateUserProfile(username: nickname);
          debugPrint('Successfully saved nickname to Supabase');
        } catch (updateError) {
          debugPrint('Failed to save nickname to Supabase: $updateError');
        }
      } else {
        debugPrint('User already has nickname: ${profile['username']}');
      }
    } catch (e) {
      debugPrint('Error checking/generating nickname: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  } else {
    debugPrint('User is not logged in after anonymous sign-in attempt');
  }
  
  // Initialize notification service
  await NotificationService.instance.init();
  
  // Initialize Gemini service
  await GeminiService.instance.init();
  
  runApp(const KanjiStudyApp());
}

class KanjiStudyApp extends StatelessWidget {
  const KanjiStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanji Study',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(),
      builder: (context, child) => FTheme(
        data: FThemes.zinc.light,
        child: child!,
      ),
      home: const MainScreen(),
    );
  }
}