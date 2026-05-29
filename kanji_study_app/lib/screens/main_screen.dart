import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../l10n/localization_extensions.dart';
import 'home_screen.dart';
import 'kanji_screen.dart';
import 'words_screen.dart';
import 'quiz_dashboard_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Shared state for meaning visibility across tabs
  bool _kanjiShowMeanings = true;
  bool _wordsShowMeanings = true;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onKanjiMeaningsToggle(bool value) {
    setState(() {
      _kanjiShowMeanings = value;
    });
  }

  void _onWordsMeaningsToggle(bool value) {
    setState(() {
      _wordsShowMeanings = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FScaffold(
      childPad: false,
      footer: FBottomNavigationBar(
        index: _selectedIndex,
        onChange: _onItemTapped,
        children: [
          FBottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 0
                  ? PhosphorIconsFill.house
                  : PhosphorIconsRegular.house,
            ),
            label: Text(l10n.home),
          ),
          FBottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 1
                  ? PhosphorIconsFill.translate
                  : PhosphorIconsRegular.translate,
            ),
            label: Text(l10n.kanji),
          ),
          FBottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 2
                  ? PhosphorIconsFill.bookOpen
                  : PhosphorIconsRegular.bookOpen,
            ),
            label: Text(l10n.words),
          ),
          FBottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 3
                  ? PhosphorIconsFill.question
                  : PhosphorIconsRegular.question,
            ),
            label: Text(l10n.quiz),
          ),
          FBottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 4
                  ? PhosphorIconsFill.user
                  : PhosphorIconsRegular.user,
            ),
            label: Text(l10n.profile),
          ),
        ],
      ),
      child: IndexedStack(
        index: _selectedIndex,
        children: [
          const HomeScreen(),
          KanjiScreen(
            showMeanings: _kanjiShowMeanings,
            onMeaningsToggle: _onKanjiMeaningsToggle,
          ),
          WordsScreen(
            showMeanings: _wordsShowMeanings,
            onMeaningsToggle: _onWordsMeaningsToggle,
          ),
          const QuizDashboardScreen(),
          const ProfileScreen(),
        ],
      ),
    );
  }
}
