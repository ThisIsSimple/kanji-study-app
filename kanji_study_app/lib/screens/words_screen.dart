import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../l10n/localization_extensions.dart';
import '../models/word_model.dart';
import '../models/word_flashcard_adapter.dart';
import '../services/language_settings_service.dart';
import '../services/word_service.dart';
import '../services/flashcard_service.dart';
import '../services/study_record_service.dart';
import '../widgets/app_toast.dart';
import '../widgets/word_list_item.dart';
import '../widgets/custom_header.dart';
import '../widgets/kanji_handwriting_sheet.dart';
import 'word_detail_screen.dart';
import '../constants/app_spacing.dart';
import '../utils/study_session_launcher.dart';

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
  final LanguageSettingsService _languageSettings =
      LanguageSettingsService.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Word> _filteredWords = [];
  String _searchQuery = '';
  final Set<int> _selectedJlptLevels = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreWords = false;
  bool _showOnlyFavorites = false;
  bool _isSearchMode = false;
  bool _autofocusSearchField = false;
  int _totalWordCount = 0;
  int _queryGeneration = 0;
  Timer? _searchDebounce;
  static const int _pageSize = 50;

  // Study status filter: null=전체, 'not_studied', 'completed', 'forgot'
  String? _selectedStudyFilter;

  @override
  void initState() {
    super.initState();
    _languageSettings.addListener(_onLanguageSettingsChanged);
    _loadWords();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
  }

  @override
  void dispose() {
    _languageSettings.removeListener(_onLanguageSettingsChanged);
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onLanguageSettingsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadWords() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      if (!_wordService.isInitialized) {
        await _wordService.init();
      }
      await _loadStudyStatusCache();
      await _reloadWords(showLoader: false);
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
    unawaited(_reloadWords());
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), _applyFilters);
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMoreWords) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      unawaited(_loadMoreWords());
    }
  }

  Future<void> _reloadWords({bool showLoader = true}) async {
    final generation = ++_queryGeneration;
    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
        _isLoadingMore = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingMore = false);
    }

    try {
      final wordsFuture = _wordService.queryWords(
        query: _searchQuery,
        jlptLevels: _selectedJlptLevels,
        favoriteOnly: _showOnlyFavorites,
        studyFilter: _selectedStudyFilter,
        limit: _pageSize,
        offset: 0,
      );
      final countFuture = _wordService.countWords(
        query: _searchQuery,
        jlptLevels: _selectedJlptLevels,
        favoriteOnly: _showOnlyFavorites,
        studyFilter: _selectedStudyFilter,
      );
      final words = await wordsFuture;
      final count = await countFuture;

      if (!mounted || generation != _queryGeneration) return;
      setState(() {
        _filteredWords = words;
        _totalWordCount = count;
        _hasMoreWords = words.length < count;
      });
    } catch (e) {
      debugPrint('Error querying words: $e');
      if (!mounted || generation != _queryGeneration) return;
      setState(() {
        _filteredWords = [];
        _totalWordCount = 0;
        _hasMoreWords = false;
      });
    } finally {
      if (mounted && generation == _queryGeneration) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreWords() async {
    if (!_hasMoreWords || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    final generation = _queryGeneration;
    try {
      final words = await _wordService.queryWords(
        query: _searchQuery,
        jlptLevels: _selectedJlptLevels,
        favoriteOnly: _showOnlyFavorites,
        studyFilter: _selectedStudyFilter,
        limit: _pageSize,
        offset: _filteredWords.length,
      );

      if (mounted && generation == _queryGeneration) {
        setState(() {
          _filteredWords = [..._filteredWords, ...words];
          _hasMoreWords = _filteredWords.length < _totalWordCount;
        });
      }
    } catch (e) {
      debugPrint('Error loading more words: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _toggleJlptFilter(int level) {
    setState(() {
      if (_selectedJlptLevels.contains(level)) {
        _selectedJlptLevels.remove(level);
      } else {
        _selectedJlptLevels.add(level);
      }
    });
    _applyFilters();
  }

  void _toggleFavoriteFilter() {
    setState(() {
      _showOnlyFavorites = !_showOnlyFavorites;
    });
    _applyFilters();
  }

  void _toggleMeanings() {
    widget.onMeaningsToggle?.call(!widget.showMeanings);
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      _autofocusSearchField = _isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
    if (!_isSearchMode) {
      _applyFilters();
    }
  }

  Future<void> _openHandwritingSearch() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    if (!mounted) return;

    final availableWords = await _wordService.getAllWordTexts();
    if (!mounted) return;

    final selectedWord = await showWordHandwritingSheet(
      context,
      availableWords: availableWords.toSet(),
    );

    if (!mounted) return;

    if (selectedWord == null) {
      return;
    }

    if (!_isSearchMode) {
      setState(() {
        _isSearchMode = true;
        _autofocusSearchField = false;
      });
    }

    _searchController
      ..text = selectedWord
      ..selection = TextSelection.collapsed(offset: selectedWord.length);

    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    if (!mounted) return;

    showAppToast(
      context,
      message: context.l10n.searchResultShown(selectedWord),
      type: AppToastType.info,
    );
  }

  Future<void> _startFlashcardSession() async {
    await StudySessionLauncher.launch<Word>(
      context: context,
      itemType: 'word',
      filteredItems: _filteredWords,
      flashcardService: _flashcardService,
      emptyMessage: context.l10n.noWordsToStudy,
      totalItemCount: _totalWordCount,
      loadSelectedItems: (count) => _wordService.getWordsForFlashcardSession(
        query: _searchQuery,
        jlptLevels: _selectedJlptLevels,
        favoriteOnly: _showOnlyFavorites,
        studyFilter: _selectedStudyFilter,
        limit: count,
      ),
      loadResumeItems: (session) => _wordService.getWordsByIds(session.itemIds),
      toFlashcardItems: (items) => items
          .map(
            (word) => WordFlashcardAdapter(
              word,
              meaningLanguage: _languageSettings.wordMeaningLanguage,
            ),
          )
          .toList(),
      onComplete: () async {
        await _loadStudyStatusCache();
        if (mounted) {
          _applyFilters();
        }
      },
    );
  }

  Future<void> _toggleWordFavorite(Word word) async {
    try {
      await _wordService.toggleFavorite(word.id);
      if (!mounted) return;
      if (_showOnlyFavorites) {
        _applyFilters();
      } else {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: context.l10n.favoriteSaveFailed(e.toString()),
        type: AppToastType.error,
      );
    }
  }

  void _showFilterBottomSheet() {
    final l10n = context.l10n;
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
                            l10n.filter,
                            style: theme.typography.lg.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // Study Status Filter Section
                          Text(
                            l10n.studyStatus,
                            style: theme.typography.sm.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Study status options - 2 columns
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children:
                                [
                                  (null, l10n.all),
                                  ('not_studied', l10n.notStudied),
                                  ('completed', l10n.completed),
                                  ('forgot', l10n.forgotWord),
                                ].map((option) {
                                  final value = option.$1;
                                  final label = option.$2;
                                  final isSelected =
                                      _selectedStudyFilter == value;

                                  return GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        _selectedStudyFilter = value;
                                      });
                                      _applyFilters();
                                    },
                                    child: Container(
                                      width:
                                          (MediaQuery.of(context).size.width -
                                              80) /
                                          2,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
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
                                                        color: theme
                                                            .colors
                                                            .primary,
                                                      ),
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              label,
                                              style: theme.typography.md
                                                  .copyWith(
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // JLPT Level Section
                          Text(
                            'JLPT',
                            style: theme.typography.sm.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // JLPT Level checkboxes - 2 columns
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children:
                                [
                                  (5, 'N5'),
                                  (4, 'N4'),
                                  (3, 'N3'),
                                  (2, 'N2'),
                                  (1, 'N1'),
                                ].map((option) {
                                  final level = option.$1;
                                  final label = option.$2;
                                  final isSelected = _selectedJlptLevels
                                      .contains(level);

                                  return GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        _toggleJlptFilter(level);
                                      });
                                      setState(() {}); // Update main screen
                                    },
                                    child: Container(
                                      width:
                                          (MediaQuery.of(context).size.width -
                                              80) /
                                          2,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: isSelected
                                                    ? theme.colors.primary
                                                    : theme.colors.border,
                                                width: 2,
                                              ),
                                              color: isSelected
                                                  ? theme.colors.primary
                                                  : Colors.transparent,
                                            ),
                                            child: isSelected
                                                ? Icon(
                                                    Icons.check,
                                                    size: 14,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              label,
                                              style: theme.typography.md
                                                  .copyWith(
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
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
                          child: Text(l10n.done),
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
    final l10n = context.l10n;

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
                      control: FTextFieldControl.managed(
                        controller: _searchController,
                      ),
                      hint: l10n.searchWordsHint,
                      autofocus: _autofocusSearchField,
                    ),
                  ),
                  rightActions: [
                    HeaderActionButton(
                      icon: Icon(
                        PhosphorIconsRegular.pencilSimpleLine,
                        size: 20,
                      ),
                      onPressed: _openHandwritingSearch,
                    ),
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
                    HeaderActionButton(
                      icon: Icon(
                        PhosphorIconsRegular.pencilSimpleLine,
                        size: 20,
                      ),
                      onPressed: _openHandwritingSearch,
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
                        await _reloadWords(showLoader: false);
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
                                      ? l10n.noFavoriteWords
                                      : l10n.noSearchResults,
                                  style: theme.typography.md.copyWith(
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            padding: EdgeInsets.all(AppSpacing.md),
                            itemCount:
                                _filteredWords.length +
                                (_isLoadingMore ? 1 : 0),
                            key: ValueKey('words-$_queryGeneration'),
                            separatorBuilder: (context, index) {
                              return const SizedBox(
                                height: 12,
                              ); // 원하는 간격(px) 만큼 높이 지정
                            },
                            itemBuilder: (context, index) {
                              // Safety check to prevent RangeError
                              if (index >= _filteredWords.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: FCircularProgress()),
                                );
                              }
                              final word = _filteredWords[index];
                              return WordListItem(
                                key: ValueKey(word.id),
                                word: word,
                                isFavorite: _wordService.isFavorite(word.id),
                                showMeaning: widget.showMeanings,
                                meaningLanguage:
                                    _languageSettings.wordMeaningLanguage,
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
                                onFavoriteToggle: () =>
                                    _toggleWordFavorite(word),
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
