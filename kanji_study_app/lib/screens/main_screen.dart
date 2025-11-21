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
    return Scaffold(
      body: IndexedStack(
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
          const QuizListScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: FBottomNavigationBar(
        index: _selectedIndex,
        onChange: _onItemTapped,
        children: [
          FBottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 0
                  ? PhosphorIconsFill.house
                  : PhosphorIconsRegular.house,
            ),
            label: const Text('홈'),
          ),
          FBottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 1
                  ? PhosphorIconsFill.translate
                  : PhosphorIconsRegular.translate,
            ),
            label: const Text('한자'),
          ),
          FBottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 2
                  ? PhosphorIconsFill.bookOpen
                  : PhosphorIconsRegular.bookOpen,
            ),
            label: const Text('단어'),
          ),
          FBottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 3
                  ? PhosphorIconsFill.question
                  : PhosphorIconsRegular.question,
            ),
            label: const Text('퀴즈'),
          ),
          FBottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 4
                  ? PhosphorIconsFill.user
                  : PhosphorIconsRegular.user,
            ),
            label: const Text('프로필'),
          ),
        ],
      ),
    );
  }
}
