import 'dart:math';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/word_model.dart';
import '../models/word_flashcard_adapter.dart';
import '../services/word_service.dart';
import '../services/flashcard_service.dart';
import '../widgets/word_list_item.dart';
import '../widgets/flashcard_count_selector.dart';
import '../widgets/app_scaffold.dart';
import 'word_detail_screen.dart';
import 'flashcard_screen.dart';
import '../constants/app_spacing.dart';

class WordsScreen extends StatefulWidget {
  const WordsScreen({super.key});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  final WordService _wordService = WordService.instance;
  final FlashcardService _flashcardService = FlashcardService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Word> _filteredWords = [];
  String _searchQuery = '';
  final Set<int> _selectedJlptLevels = {};
  bool _isLoading = true;
  bool _showOnlyFavorites = false;


  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      if (!_wordService.isInitialized) {
        await _wordService.init();
      }
      if (mounted) {
        _applyFilters();
      }
    } catch (e) {
      debugPrint('Error loading words: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    setState(() {
      List<Word> words;

      if (_showOnlyFavorites) {
        words = _wordService.getFavoriteWords();
      } else {
        words = _wordService.allWords;
      }

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        words = words.where((word) => word.matchesQuery(_searchQuery)).toList();
      }

      // Apply JLPT level filters
      if (_selectedJlptLevels.isNotEmpty) {
        words = words
            .where((word) => _selectedJlptLevels.contains(word.jlptLevel))
            .toList();
      }

      _filteredWords = words;
    });
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _applyFilters();
  }

  void _toggleJlptFilter(int level) {
    setState(() {
      if (_selectedJlptLevels.contains(level)) {
        _selectedJlptLevels.remove(level);
      } else {
        _selectedJlptLevels.add(level);
      }
      _applyFilters();
    });
  }

  void _toggleFavoriteFilter() {
    setState(() {
      _showOnlyFavorites = !_showOnlyFavorites;
      _applyFilters();
    });
  }



  Future<void> _startFlashcardSession() async {
    if (_filteredWords.isEmpty) {
      final theme = FTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('학습할 단어가 없습니다', style: TextStyle()),
          backgroundColor: theme.colors.destructive,
        ),
      );
      return;
    }

    // Check if there's an active word session
    final existingSession = await _flashcardService.loadSessionByType('word');

    if (existingSession != null && !existingSession.isCompleted && mounted) {
      // Ask user if they want to resume or start new
      showDialog(
        context: context,
        builder: (context) {
          final theme = FTheme.of(context);
          return AlertDialog(
            title: Text(
              '진행 중인 학습',
              style: theme.typography.lg.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              '이전에 진행 중이던 플래시카드 학습이 있습니다.\n계속하시겠습니까?',
              style: theme.typography.base.copyWith(),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await _flashcardService.clearSession('word');
                  if (!mounted) return;
                  navigator.pop();
                  await _showCountSelectorAndStart();
                },
                child: Text('새로 시작', style: TextStyle()),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _navigateToFlashcard(_filteredWords, existingSession);
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
      _filteredWords.length,
    );

    if (selectedCount != null && mounted) {
      // 랜덤으로 단어 선택
      final selectedWords = _selectRandomWords(_filteredWords, selectedCount);
      _navigateToFlashcard(selectedWords, null);
    }
  }

  List<Word> _selectRandomWords(List<Word> words, int count) {
    if (count >= words.length) return words;

    final random = Random();
    final selectedIndices = <int>{};

    // 중복 없이 랜덤 인덱스 생성
    while (selectedIndices.length < count) {
      selectedIndices.add(random.nextInt(words.length));
    }

    return selectedIndices.map((i) => words[i]).toList();
  }

  void _navigateToFlashcard(List<Word> selectedWords, dynamic session) {
    // Convert selected words to FlashcardItem using adapter
    final flashcardItems = selectedWords
        .map((word) => WordFlashcardAdapter(word))
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = FTheme.of(context);
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'JLPT 레벨 필터',
                          style: theme.typography.lg.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            '완료',
                            style: TextStyle(
                              color: theme.colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ...List.generate(5, (index) {
                    final level = 5 - index; // N5 to N1
                    final isSelected = _selectedJlptLevels.contains(level);

                    return ListTile(
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (_) {
                          setModalState(() {
                            _toggleJlptFilter(level);
                          });
                          setState(() {}); // Update main screen
                        },
                        activeColor: theme.colors.primary,
                      ),
                      title: Text(
                        'JLPT N$level',
                        style: theme.typography.base.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        setModalState(() {
                          _toggleJlptFilter(level);
                        });
                        setState(() {}); // Update main screen
                      },
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
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
        IconButton(
          icon: Stack(
            children: [
              Icon(PhosphorIconsRegular.funnel, size: 20),
              if (_selectedJlptLevels.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: _showFilterBottomSheet,
        ),
      ],
      searchController: _searchController,
      onSearchChanged: (value) => _onSearchChanged(value),
      onSearchClosed: () {
        setState(() {
          _searchQuery = '';
          _applyFilters();
        });
      },
      searchHint: '일본어, 한글, 후리가나로 검색...',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Flashcard start button
                if (_filteredWords.isNotEmpty)
                  Padding(
                    padding: AppSpacing.buttonPadding,
                    child: FCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  PhosphorIconsRegular.graduationCap,
                                  size: 20,
                                  color: theme.colors.primary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '학습 시작',
                                  style: theme.typography.sm.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colors.foreground,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            FButton(
                              onPress: _startFlashcardSession,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      PhosphorIconsRegular.cards,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '플래시카드 학습 (${_filteredWords.length}개)',
                                      style: theme.typography.base.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _wordService.reloadData();
                      _applyFilters();
                    },
                    child: _filteredWords.isEmpty
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
                                            ? '즐겨찾기한 단어가 없습니다'
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
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            itemCount: _filteredWords.length,
                            key: ValueKey(_filteredWords.length),
                            itemBuilder: (context, index) {
                              // Safety check to prevent RangeError
                              if (index >= _filteredWords.length) {
                                return const SizedBox.shrink();
                              }
                              final word = _filteredWords[index];
                              return WordListItem(
                                key: ValueKey(word.id),
                                word: word,
                                isFavorite: _wordService.isFavorite(word.id),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => WordDetailScreen(
                                        word: word,
                                        wordList: _filteredWords,
                                        currentIndex: index,
                                      ),
                                    ),
                                  );
                                },
                                onFavoriteToggle: () {
                                  setState(() {
                                    _wordService.toggleFavorite(word.id);
                                    if (_showOnlyFavorites) {
                                      _applyFilters();
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
