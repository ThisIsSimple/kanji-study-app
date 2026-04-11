import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/kanji_model.dart';
import '../models/kanji_flashcard_adapter.dart';
import '../models/study_record_model.dart';
import '../services/kanji_service.dart';
import '../services/flashcard_service.dart';
import '../services/study_record_service.dart';
import '../widgets/app_toast.dart';
import '../widgets/kanji_grid_card.dart';
import '../widgets/kanji_handwriting_sheet.dart';
import '../widgets/custom_header.dart';
import 'kanji_detail_screen.dart';
import '../constants/app_spacing.dart';
import '../utils/study_session_launcher.dart';

class KanjiScreen extends StatefulWidget {
  final bool showMeanings;
  final ValueChanged<bool>? onMeaningsToggle;

  const KanjiScreen({
    super.key,
    this.showMeanings = true,
    this.onMeaningsToggle,
  });

  @override
  State<KanjiScreen> createState() => _KanjiScreenState();
}

class _KanjiScreenState extends State<KanjiScreen> {
  final KanjiService _kanjiService = KanjiService.instance;
  final FlashcardService _flashcardService = FlashcardService.instance;
  final StudyRecordService _studyRecordService = StudyRecordService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Kanji> _allKanji = [];
  List<Kanji> _filteredKanji = [];
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSearchMode = false;

  bool _showOnlyFavorites = false;

  // Study status filter: null=전체, 'not_studied', 'completed', 'forgot'
  String? _selectedStudyFilter;

  // Grade filter: 복수 선택 가능
  final Set<int> _selectedGradeFilters = {};

  // JLPT filter: 복수 선택 가능
  final Set<int> _selectedJlptFilters = {};

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
      if (!_studyRecordService.isInitialized) {
        await _studyRecordService.initialize();
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

      // Apply study status filter
      if (_selectedStudyFilter != null) {
        final status = _studyRecordService.getStatus(StudyType.kanji, kanji.id);
        switch (_selectedStudyFilter) {
          case 'not_studied':
            if (status != null) return false;
          case 'completed':
            if (status != StudyStatus.completed &&
                status != StudyStatus.mastered) {
              return false;
            }
          case 'forgot':
            if (status != StudyStatus.forgot) return false;
        }
      }

      // Apply grade filter
      if (_selectedGradeFilters.isNotEmpty &&
          !_selectedGradeFilters.contains(kanji.grade)) {
        return false;
      }

      // Apply JLPT filter
      if (_selectedJlptFilters.isNotEmpty &&
          !_selectedJlptFilters.contains(kanji.jlpt)) {
        return false;
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

  Future<void> _openHandwritingSearch() async {
    final wasSearchMode = _isSearchMode;

    if (!wasSearchMode) {
      setState(() {
        _isSearchMode = true;
      });
      await Future<void>.delayed(Duration.zero);
    }

    if (!mounted) return;

    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    if (!mounted) return;

    final selectedKanji = await showKanjiHandwritingSheet(
      context,
      availableKanjiCharacters: _allKanji.map((kanji) => kanji.character).toSet(),
    );

    if (!mounted) return;

    if (selectedKanji == null) {
      if (!wasSearchMode && _searchController.text.isEmpty) {
        setState(() {
          _isSearchMode = false;
        });
      }
      return;
    }

    _searchController
      ..text = selectedKanji
      ..selection = TextSelection.collapsed(offset: selectedKanji.length);

    showAppToast(
      context,
      message: '$selectedKanji 검색 결과를 표시합니다',
      type: AppToastType.info,
    );
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
            final maxHeight = MediaQuery.of(context).size.height * 0.85;
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Container(
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
                    children: [
                      // Fixed header section
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
                          ],
                        ),
                      ),
                      // Scrollable content section
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 24),
                              // Study Status Filter Section
                              Text(
                                '학습 상태',
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
                                      (null, '전체'),
                                      ('not_studied', '미학습'),
                                      ('completed', '학습 완료'),
                                      ('forgot', '까먹은 한자'),
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
                                          setState(() {
                                            _applyFilters();
                                          });
                                        },
                                        child: Container(
                                          width:
                                              (MediaQuery.of(
                                                    context,
                                                  ).size.width -
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
                                                          decoration:
                                                              BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
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
                                                  style: theme.typography.base
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

                              // Grade Filter Section
                              Text(
                                '학년',
                                style: theme.typography.sm.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Grade options - 2 columns with checkboxes
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children:
                                    [
                                      (1, '1학년'),
                                      (2, '2학년'),
                                      (3, '3학년'),
                                      (4, '4학년'),
                                      (5, '5학년'),
                                      (6, '6학년'),
                                      (7, '중학교+'),
                                    ].map((option) {
                                      final value = option.$1;
                                      final label = option.$2;
                                      final isSelected = _selectedGradeFilters
                                          .contains(value);

                                      return GestureDetector(
                                        onTap: () {
                                          setModalState(() {
                                            if (isSelected) {
                                              _selectedGradeFilters.remove(
                                                value,
                                              );
                                            } else {
                                              _selectedGradeFilters.add(value);
                                            }
                                          });
                                          setState(() {
                                            _applyFilters();
                                          });
                                        },
                                        child: Container(
                                          width:
                                              (MediaQuery.of(
                                                    context,
                                                  ).size.width -
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
                                                  style: theme.typography.base
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

                              // JLPT Filter Section
                              Text(
                                'JLPT',
                                style: theme.typography.sm.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // JLPT options - 2 columns with checkboxes
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
                                      final value = option.$1;
                                      final label = option.$2;
                                      final isSelected = _selectedJlptFilters
                                          .contains(value);

                                      return GestureDetector(
                                        onTap: () {
                                          setModalState(() {
                                            if (isSelected) {
                                              _selectedJlptFilters.remove(
                                                value,
                                              );
                                            } else {
                                              _selectedJlptFilters.add(value);
                                            }
                                          });
                                          setState(() {
                                            _applyFilters();
                                          });
                                        },
                                        child: Container(
                                          width:
                                              (MediaQuery.of(
                                                    context,
                                                  ).size.width -
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
                                                  style: theme.typography.base
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
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToStudy(Kanji kanji) {
    final index = _filteredKanji.indexOf(kanji);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KanjiDetailScreen(
          kanji: kanji,
          kanjiList: _filteredKanji,
          currentIndex: index >= 0 ? index : 0,
        ),
      ),
    ).then((_) {
      // Refresh the UI when returning from detail screen
      if (mounted) {
        setState(() {
          _applyFilters();
        });
      }
    });
  }

  Future<void> _startFlashcardSession() async {
    await StudySessionLauncher.launch<Kanji>(
      context: context,
      itemType: 'kanji',
      filteredItems: _filteredKanji,
      flashcardService: _flashcardService,
      emptyMessage: '학습할 한자가 없습니다',
      toFlashcardItems: (items) =>
          items.map((kanji) => KanjiFlashcardAdapter(kanji)).toList(),
      onComplete: () async {
        if (!mounted) return;
        setState(_applyFilters);
      },
    );
  }

  Future<void> _toggleKanjiFavorite(Kanji kanji) async {
    try {
      await _kanjiService.toggleFavorite(kanji.character);
      if (!mounted) return;
      setState(() {
        if (_showOnlyFavorites) {
          _applyFilters();
        }
      });
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: '즐겨찾기 저장 실패: $e',
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      floatingActionButton: _filteredKanji.isNotEmpty
          ? FloatingActionButton(
              heroTag: 'kanji_flashcard_fab',
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
                      hint: '한자, 의미, 읽기로 검색...',
                      autofocus: true,
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
                          if (_selectedStudyFilter != null ||
                              _selectedGradeFilters.isNotEmpty ||
                              _selectedJlptFilters.isNotEmpty)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: FTheme.of(context).colors.primary,
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
                    onRefresh: () => _loadKanji(forceReload: true),
                    child: _filteredKanji.isEmpty
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
                                      ? '즐겨찾기한 한자가 없습니다'
                                      : '검색 결과가 없습니다',
                                  style: theme.typography.base.copyWith(
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                              ],
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
                                showMeaning: widget.showMeanings,
                                onTap: () => _navigateToStudy(kanji),
                                onFavoriteToggle: () =>
                                    _toggleKanjiFavorite(kanji),
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
