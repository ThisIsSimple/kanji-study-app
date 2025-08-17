import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/date_symbol_data_local.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/notification_service.dart';
import 'services/gemini_service.dart';
import 'services/supabase_service.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Kakao SDK
  // TODO: Replace with your actual Kakao native app key
  KakaoSdk.init(nativeAppKey: '88ec2313b07c9ce230ae930ac839549c');
  
  // Initialize timezone
  tz.initializeTimeZones();
  
  // Initialize date formatting for Korean and Japanese locales
  await initializeDateFormatting('ko_KR', null);
  await initializeDateFormatting('ja_JP', null);
  
  // Initialize Supabase
  await SupabaseService.instance.init();
  
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
        child: StreamBuilder<AuthState>(
          stream: SupabaseService.instance.authStateChanges(),
          builder: (context, snapshot) {
            // Check session and return appropriate screen
            if (snapshot.hasData && snapshot.data!.session != null) {
              return child!;
            }
            // No session, always show login screen regardless of navigation stack
            return const LoginScreen();
          },
        ),
      ),
      home: const MainScreen(),
    );
  }
}