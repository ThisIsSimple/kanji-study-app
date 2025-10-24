import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/kanji_model.dart';
import '../models/kanji_flashcard_adapter.dart';
import '../services/kanji_service.dart';
import '../services/flashcard_service.dart';
import '../utils/korean_formatter.dart';
import 'study_screen.dart';
import 'flashcard_screen.dart';

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
  bool _showSearchBar = false;
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
        
        if (!matchesCharacter && !matchesMeaning && !matchesJapaneseReading && !matchesKoreanReading) {
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

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _searchQuery = '';
        _applyFilters();
      }
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
    );
  }

  Future<void> _startFlashcardSession() async {
    if (_filteredKanji.isEmpty) {
      final theme = FTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '학습할 한자가 없습니다',
            style: TextStyle(fontFamily: 'SUITE'),
          ),
          backgroundColor: theme.colors.destructive,
        ),
      );
      return;
    }

    // Check if there's an active session
    final existingSession = await _flashcardService.loadSession();

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
                fontFamily: 'SUITE',
              ),
            ),
            content: Text(
              '이전에 진행 중이던 플래시카드 학습이 있습니다.\n계속하시겠습니까?',
              style: theme.typography.base.copyWith(fontFamily: 'SUITE'),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await _flashcardService.clearSession();
                  if (mounted) {
                    Navigator.of(context).pop();
                    _navigateToFlashcard(null);
                  }
                },
                child: Text(
                  '새로 시작',
                  style: TextStyle(fontFamily: 'SUITE'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _navigateToFlashcard(existingSession);
                },
                child: Text(
                  '이어하기',
                  style: TextStyle(
                    fontFamily: 'SUITE',
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
      _navigateToFlashcard(null);
    }
  }

  void _navigateToFlashcard(dynamic session) {
    // Convert kanji to FlashcardItem using adapter
    final flashcardItems = _filteredKanji.map((kanji) => KanjiFlashcardAdapter(kanji)).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardScreen(
          items: flashcardItems,
          initialSession: session,
        ),
      ),
    ).then((_) {
      // Refresh when coming back
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    
    return FScaffold(
      header: Stack(
        children: [
          FHeader(
            title: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _showOnlyFavorites
                    ? '즐겨찾기 ${_filteredKanji.length}개'
                    : '전체 ${_filteredKanji.length}개',
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                  fontFamily: 'SUITE',
                ),
              ),
            ),
            suffixes: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        _showOnlyFavorites ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                        color: _showOnlyFavorites ? Colors.amber : null,
                        size: 20,
                      ),
                      onPressed: _toggleFavoriteFilter,
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        PhosphorIconsRegular.magnifyingGlass,
                        size: 20,
                      ),
                      onPressed: _toggleSearch,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_showSearchBar)
            Positioned.fill(
              child: Container(
                color: theme.colors.background,
                child: SafeArea(
                  child: Container(
                    height: 56,
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: '한자, 의미, 읽기로 검색...',
                              hintStyle: TextStyle(fontFamily: 'SUITE'),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: theme.typography.lg.copyWith(
                              fontFamily: 'SUITE',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              PhosphorIconsRegular.x,
                              size: 20,
                            ),
                            onPressed: _toggleSearch,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Flashcard start button
                if (_filteredKanji.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: FButton(
                      onPress: _startFlashcardSession,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
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
                              '플래시카드 학습 시작 (${_filteredKanji.length}개)',
                              style: theme.typography.base.copyWith(
                                fontFamily: 'SUITE',
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Kanji grid
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadKanji(forceReload: true),
                    child: _filteredKanji.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  PhosphorIconsRegular.magnifyingGlass,
                                  size: 48,
                                  color: theme.colors.mutedForeground,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _showOnlyFavorites
                                      ? '즐겨찾기한 한자가 없습니다'
                                      : '검색 결과가 없습니다',
                                  style: theme.typography.base.copyWith(
                                    color: theme.colors.mutedForeground,
                                    fontFamily: 'SUITE',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16.0),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
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
                ),
              ],
            ),
    );
  }
}

// Separate widget for the grid card
class KanjiGridCard extends StatelessWidget {
  final Kanji kanji;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const KanjiGridCard({
    super.key,
    required this.kanji,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final kanjiService = KanjiService.instance;
    final progress = kanjiService.getProgress(kanji.character);
    final isFavorite = kanjiService.isFavorite(kanji.character);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colors.border,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Top bar with check and favorite
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Check mark
                  if (progress != null && progress.mastered)
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        PhosphorIconsFill.check,
                        size: 14,
                        color: theme.colors.background,
                      ),
                    )
                  else
                    const SizedBox(width: 20),
                  
                  // Favorite button
                  GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Icon(
                      isFavorite ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                      size: 20,
                      color: isFavorite ? Colors.amber : theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    // Kanji Character
                    Text(
                      kanji.character,
                      style: GoogleFonts.notoSerifJp(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: theme.colors.foreground,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Korean readings
                    if (hasKoreanReadings(kanji.koreanKunReadings, kanji.koreanOnReadings))
                      Text(
                        formatKoreanReadings(kanji.koreanKunReadings, kanji.koreanOnReadings),
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.primary,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SUITE',
                          fontSize: 13,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}