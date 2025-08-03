import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone
  tz.initializeTimeZones();
  
  // Initialize notification service
  await NotificationService.instance.init();
  
  runApp(const KanjiStudyApp());
}

class KanjiStudyApp extends StatelessWidget {
  const KanjiStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanji Study',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => FTheme(
        data: FThemes.zinc.light,
        child: child!,
      ),
      home: const HomeScreen(),
    );
  }
}