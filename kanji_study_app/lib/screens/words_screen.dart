import 'dart:math';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/word_model.dart';
import '../models/word_flashcard_adapter.dart';
import '../services/word_service.dart';
import '../services/flashcard_service.dart';
import '../services/study_record_service.dart';
import '../widgets/word_list_item.dart';
import '../widgets/flashcard_count_selector.dart';
import '../widgets/custom_header.dart';
import 'word_detail_screen.dart';
import 'flashcard_screen.dart';
import '../constants/app_spacing.dart';

class WordsScreen extends StatefulWidget {
  final bool showMeanings;
  final ValueChanged<bool>? onMeaningsToggle;

  const WordsScreen({
    super.key,
    this.showMeanings = true,
    this.onMeaningsToggle,
  });

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  final WordService _wordService = WordService.instance;
  final FlashcardService _flashcardService = FlashcardService.instance;
  final StudyRecordService _studyRecordService = StudyRecordService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Word> _filteredWords = [];
  String _searchQuery = '';
  final Set<int> _selectedJlptLevels = {};
  bool _isLoading = true;
  bool _showOnlyFavorites = false;
  bool _isSearchMode = false;

  // Study status filter: null=전체, 'not_studied', 'completed', 'forgot'
  String? _selectedStudyFilter;

  @override
  void initState() {
    super.initState();
    _loadWords();
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
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
      // Load study status cache
      await _loadStudyStatusCache();
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

  Future<void> _loadStudyStatusCache() async {
    // Initialize StudyRecordService if not already initialized
    if (!_studyRecordService.isInitialized) {
      await _studyRecordService.initialize();
    }
    // StudyRecordService already maintains the cache internally
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

      // Apply study status filter
      if (_selectedStudyFilter != null) {
        words = words.where((word) {
          final status = _studyRecordService.getStatus('word', word.id);
          switch (_selectedStudyFilter) {
            case 'not_studied':
              return status == null;
            case 'completed':
              return status == 'completed' || status == 'mastered';
            case 'forgot':
              return status == 'forgot';
            default:
              return true;
          }
        }).toList();
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

  void _toggleMeanings() {
    widget.onMeaningsToggle?.call(!widget.showMeanings);
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        _searchQuery = '';
        _applyFilters();
      }
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
      showFDialog(
        context: context,
        builder: (context, style, animation) => FDialog(
          style: style,
          animation: animation,
          direction: Axis.horizontal,
          title: const Text('진행 중인 학습'),
          body: const Text('이전에 진행 중이던 플래시카드 학습이 있습니다.\n계속하시겠습니까?'),
          actions: [
            FButton(
              style: FButtonStyle.outline(),
              onPress: () async {
                final navigator = Navigator.of(context);
                await _flashcardService.clearSession('word');
                if (!mounted) return;
                navigator.pop();
                await _showCountSelectorAndStart();
              },
              child: const Text('새로 시작'),
            ),
            FButton(
              onPress: () {
                Navigator.of(context).pop();
                _navigateToFlashcard(_filteredWords, existingSession);
              },
              child: const Text('이어하기'),
            ),
          ],
        ),
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
    ).then((_) async {
      // Refresh study status cache when coming back
      await _loadStudyStatusCache();
      if (mounted) {
        _applyFilters();
      }
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = FTheme.of(context);
            return Container(
              decoration: BoxDecoration(
                color: theme.colors.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Drag handle
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: theme.colors.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          // Title
                          Text(
                            '필터',
                            style: theme.typography.lg.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Study Status Filter Section
                          Text(
                            '학습 상태',
                            style: theme.typography.sm.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Study status options
                          ...[
                            (null, '전체'),
                            ('not_studied', '미학습'),
                            ('completed', '학습 완료'),
                            ('forgot', '까먹은 단어'),
                          ].map((option) {
                            final value = option.$1;
                            final label = option.$2;
                            final isSelected = _selectedStudyFilter == value;

                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  _selectedStudyFilter = value;
                                });
                                _applyFilters();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 4,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? theme.colors.primary
                                              : theme.colors.border,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? Center(
                                              child: Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: theme.colors.primary,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      label,
                                      style: theme.typography.base.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 20),

                          // JLPT Level Section
                          Text(
                            'JLPT 등급',
                            style: theme.typography.sm.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // JLPT Level checkboxes (horizontal)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(5, (index) {
                              final level = 5 - index; // N5 to N1
                              final isSelected = _selectedJlptLevels.contains(
                                level,
                              );

                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    _toggleJlptFilter(level);
                                  });
                                  setState(() {}); // Update main screen
                                },
                                child: Row(
                                  children: [
                                    FCheckbox(
                                      value: isSelected,
                                      onChange: (_) {
                                        setModalState(() {
                                          _toggleJlptFilter(level);
                                        });
                                        setState(() {}); // Update main screen
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'N$level',
                                      style: theme.typography.sm.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    // Bottom button
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: FButton(
                          onPress: () => Navigator.pop(context),
                          child: const Text('완료'),
                        ),
                      ),
                    ),
                  ],
                ),
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

    return Scaffold(
      backgroundColor: theme.colors.background,
      floatingActionButton: _filteredWords.isNotEmpty
          ? FloatingActionButton(
              heroTag: 'words_flashcard_fab',
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
      body: Column(
        children: [
          _isSearchMode
              ? CustomHeader(
                  title: Expanded(
                    child: FTextField(
                      controller: _searchController,
                      hint: '일본어, 한글, 후리가나로 검색...',
                      autofocus: true,
                    ),
                  ),
                  rightActions: [
                    HeaderActionButton(
                      icon: Icon(PhosphorIconsRegular.x, size: 20),
                      onPressed: _toggleSearchMode,
                    ),
                  ],
                )
              : CustomHeader(
                  leftActions: [
                    HeaderActionButton(
                      icon: Icon(
                        widget.showMeanings
                            ? PhosphorIconsRegular.eye
                            : PhosphorIconsRegular.eyeClosed,
                        size: 20,
                      ),
                      onPressed: _toggleMeanings,
                    ),
                  ],
                  rightActions: [
                    HeaderActionButton(
                      icon: Icon(
                        _showOnlyFavorites
                            ? PhosphorIconsFill.star
                            : PhosphorIconsRegular.star,
                        size: 20,
                      ),
                      onPressed: _toggleFavoriteFilter,
                    ),
                    HeaderActionButton(
                      icon: Stack(
                        children: [
                          Icon(PhosphorIconsRegular.funnel, size: 20),
                          if (_selectedJlptLevels.isNotEmpty ||
                              _selectedStudyFilter != null)
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
                    HeaderActionButton(
                      icon: Icon(
                        PhosphorIconsRegular.magnifyingGlass,
                        size: 20,
                      ),
                      onPressed: _toggleSearchMode,
                    ),
                  ],
                ),
          Expanded(
            child: _isLoading
                ? const Center(child: FCircularProgress())
                : RefreshIndicator(
                    onRefresh: () async {
                      await _wordService.reloadData();
                      if (mounted) {
                        _applyFilters();
                      }
                    },
                    child: _filteredWords.isEmpty
                        ? Center(
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
                          )
                        : ListView.separated(
                            padding: EdgeInsets.all(AppSpacing.md),
                            itemCount: _filteredWords.length,
                            key: ValueKey(_filteredWords.length),
                            separatorBuilder: (context, index) {
                              return const SizedBox(
                                height: 12,
                              ); // 원하는 간격(px) 만큼 높이 지정
                            },
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
                                showMeaning: widget.showMeanings,
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
                                  ).then((_) {
                                    // Refresh filters when coming back (study status may have changed)
                                    if (mounted) {
                                      setState(() {
                                        _applyFilters();
                                      });
                                    }
                                  });
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
