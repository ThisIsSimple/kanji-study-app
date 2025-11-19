import 'dart:math';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/kanji_model.dart';
import '../models/kanji_flashcard_adapter.dart';
import '../services/kanji_service.dart';
import '../services/flashcard_service.dart';

import '../widgets/flashcard_count_selector.dart';
import '../widgets/kanji_grid_card.dart';
import '../widgets/app_scaffold.dart';
import 'study_screen.dart';
import 'flashcard_screen.dart';
import '../constants/app_spacing.dart';

class KanjiScreen extends StatefulWidget {
  const KanjiScreen({super.key});

  @override
  State<KanjiScreen> createState() => _KanjiScreenState();
}

class _KanjiScreenState extends State<KanjiScreen> {
  final KanjiService _kanjiService = KanjiService.instance;
  final FlashcardService _flashcardService = FlashcardService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Kanji> _allKanji = [];
  List<Kanji> _filteredKanji = [];
  String _searchQuery = '';
  bool _isLoading = true;

  bool _showOnlyFavorites = false;

  @override
  void initState() {
    super.initState();
    _loadKanji();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadKanji({bool forceReload = false}) async {
    try {
      if (forceReload) {
        await _kanjiService.reloadData();
      } else {
        await _kanjiService.init();
      }
      setState(() {
        _allKanji = _kanjiService.getAllKanji();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _filteredKanji = _allKanji.where((kanji) {
      // Apply favorite filter
      if (_showOnlyFavorites && !_kanjiService.isFavorite(kanji.character)) {
        return false;
      }

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesCharacter = kanji.character.contains(query);
        final matchesMeaning = kanji.meanings.any(
          (meaning) => meaning.toLowerCase().contains(query),
        );
        final matchesJapaneseReading = kanji.readings.all.any(
          (reading) => reading.toLowerCase().contains(query),
        );
        final matchesKoreanReading = [
          ...kanji.koreanOnReadings,
          ...kanji.koreanKunReadings,
        ].any((reading) => reading.toLowerCase().contains(query));

        if (!matchesCharacter &&
            !matchesMeaning &&
            !matchesJapaneseReading &&
            !matchesKoreanReading) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  void _toggleFavoriteFilter() {
    setState(() {
      _showOnlyFavorites = !_showOnlyFavorites;
      _applyFilters();
    });
  }

  void _navigateToStudy(Kanji kanji) {
    final index = _filteredKanji.indexOf(kanji);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudyScreen(
          kanji: kanji,
          kanjiList: _filteredKanji,
          currentIndex: index >= 0 ? index : 0,
        ),
      ),
    ).then((_) {
      // Refresh the UI when returning from detail screen
      setState(() {});
    });
  }

  Future<void> _startFlashcardSession() async {
    if (_filteredKanji.isEmpty) {
      final theme = FTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('학습할 한자가 없습니다'),
          backgroundColor: theme.colors.destructive,
        ),
      );
      return;
    }

    // Check if there's an active kanji session
    final existingSession = await _flashcardService.loadSessionByType('kanji');

    if (existingSession != null && !existingSession.isCompleted && mounted) {
      // Ask user if they want to resume or start new
      showDialog(
        context: context,
        builder: (context) {
          final theme = FTheme.of(context);
          return AlertDialog(
            title: Text(
              '진행 중인 학습',
              style: theme.typography.lg.copyWith(fontWeight: FontWeight.bold),
            ),
            content: Text('이전에 진행 중이던 플래시카드 학습이 있습니다.\n계속하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await _flashcardService.clearSession('kanji');
                  if (!mounted) return;
                  navigator.pop();
                  await _showCountSelectorAndStart();
                },
                child: Text('새로 시작'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _navigateToFlashcard(_filteredKanji, existingSession);
                },
                child: Text(
                  '이어하기',
                  style: TextStyle(
                    color: theme.colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      await _showCountSelectorAndStart();
    }
  }

  Future<void> _showCountSelectorAndStart() async {
    // 개수 선택 다이얼로그 표시
    final selectedCount = await FlashcardCountSelector.show(
      context,
      _filteredKanji.length,
    );

    if (selectedCount != null && mounted) {
      // 랜덤으로 한자 선택
      final selectedKanji = _selectRandomKanji(_filteredKanji, selectedCount);
      _navigateToFlashcard(selectedKanji, null);
    }
  }

  List<Kanji> _selectRandomKanji(List<Kanji> kanjiList, int count) {
    if (count >= kanjiList.length) return kanjiList;

    final random = Random();
    final selectedIndices = <int>{};

    // 중복 없이 랜덤 인덱스 생성
    while (selectedIndices.length < count) {
      selectedIndices.add(random.nextInt(kanjiList.length));
    }

    return selectedIndices.map((i) => kanjiList[i]).toList();
  }

  void _navigateToFlashcard(List<Kanji> selectedKanji, dynamic session) {
    // Convert selected kanji to FlashcardItem using adapter
    final flashcardItems = selectedKanji
        .map((kanji) => KanjiFlashcardAdapter(kanji))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FlashcardScreen(items: flashcardItems, initialSession: session),
      ),
    ).then((_) {
      // Refresh when coming back
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return AppScaffold(
      actions: [
        IconButton(
          icon: Icon(
            _showOnlyFavorites
                ? PhosphorIconsFill.star
                : PhosphorIconsRegular.star,
            color: _showOnlyFavorites ? Colors.amber : null,
            size: 20,
          ),
          onPressed: _toggleFavoriteFilter,
        ),
      ],
      searchController: _searchController,
      onSearchChanged: (value) => _onSearchChanged(),
      onSearchClosed: () {
        setState(() {
          _searchQuery = '';
          _applyFilters();
        });
      },
      searchHint: '한자, 의미, 읽기로 검색...',
      floatingActionButton: _filteredKanji.isNotEmpty
          ? FloatingActionButton(
              onPressed: _startFlashcardSession,
              backgroundColor: theme.colors.primary,
              child: Icon(
                PhosphorIconsFill.graduationCap,
                color: Colors.white,
                size: 28,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadKanji(forceReload: true),
              child: _filteredKanji.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: FCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  PhosphorIconsRegular.magnifyingGlass,
                                  size: 48,
                                  color: theme.colors.mutedForeground,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  _showOnlyFavorites
                                      ? '즐겨찾기한 한자가 없습니다'
                                      : '검색 결과가 없습니다',
                                  style: theme.typography.base.copyWith(
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: AppSpacing.sm,
                            mainAxisSpacing: AppSpacing.sm,
                          ),
                      itemCount: _filteredKanji.length,
                      itemBuilder: (context, index) {
                        final kanji = _filteredKanji[index];
                        return KanjiGridCard(
                          kanji: kanji,
                          onTap: () => _navigateToStudy(kanji),
                          onFavoriteToggle: () {
                            setState(() {
                              _kanjiService.toggleFavorite(kanji.character);
                              if (_showOnlyFavorites) {
                                _applyFilters();
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
