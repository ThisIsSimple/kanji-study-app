import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'home_screen.dart';
import 'kanji_screen.dart';
import 'words_screen.dart';
import 'quiz_list_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const KanjiScreen(),
    const WordsScreen(),
    const QuizListScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.colors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.colors.background,
          selectedItemColor: theme.colors.primary,
          unselectedItemColor: theme.colors.mutedForeground,
          selectedLabelStyle: theme.typography.sm.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'SUITE',
          ),
          unselectedLabelStyle: theme.typography.sm.copyWith(
            fontFamily: 'SUITE',
          ),
          items: [
            BottomNavigationBarItem(
              icon: Icon(PhosphorIconsRegular.house),
              activeIcon: Icon(PhosphorIconsFill.house),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIconsRegular.translate),
              activeIcon: Icon(PhosphorIconsFill.translate),
              label: '한자',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIconsRegular.bookOpen),
              activeIcon: Icon(PhosphorIconsFill.bookOpen),
              label: '단어',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIconsRegular.question),
              activeIcon: Icon(PhosphorIconsFill.question),
              label: '퀴즈',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIconsRegular.user),
              activeIcon: Icon(PhosphorIconsFill.user),
              label: '프로필',
            ),
          ],
        ),
      ),
    );
  }
}
