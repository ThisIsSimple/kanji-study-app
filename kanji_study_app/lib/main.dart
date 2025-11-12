import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'services/notification_service.dart';
import 'services/gemini_service.dart';
import 'services/supabase_service.dart';
import 'services/connectivity_service.dart';
import 'services/local_database_service.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone
  tz.initializeTimeZones();

  // Initialize date formatting for Korean and Japanese locales
  await initializeDateFormatting('ko_KR', null);
  await initializeDateFormatting('ja_JP', null);

  // Initialize connectivity service (before other services)
  await ConnectivityService.instance.initialize();

  // Initialize Supabase
  await SupabaseService.instance.init();

  // Initialize local database service
  await LocalDatabaseService.instance.initialize();

  // Initialize notification service
  await NotificationService.instance.init();

  // Initialize Gemini service
  await GeminiService.instance.init();

  runApp(const KanjiStudyApp());
}

class KanjiStudyApp extends StatefulWidget {
  const KanjiStudyApp({super.key});

  @override
  State<KanjiStudyApp> createState() => _KanjiStudyAppState();
}

class _KanjiStudyAppState extends State<KanjiStudyApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  /// Initialize deep link handling for OAuth callbacks
  Future<void> _initDeepLinks() async {
    // Handle initial link if app was opened from a deep link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('Initial deep link: $initialUri');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Failed to get initial link: $e');
    }

    // Listen for deep links while app is running
    _appLinks.uriLinkStream.listen((uri) {
      debugPrint('Deep link received: $uri');
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Deep link error: $err');
    });
  }

  /// Handle incoming deep links (OAuth callbacks)
  void _handleDeepLink(Uri uri) {
    debugPrint('Handling deep link: $uri');

    // Check if this is a Supabase OAuth callback
    if (uri.scheme == 'space.cordelia273.konnakanji' && uri.host == 'login-callback') {
      debugPrint('Supabase OAuth callback detected');

      // Supabase SDK will automatically handle the OAuth callback
      // The auth state change listener will be triggered
      // No additional handling needed here
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '콘나칸지',
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
