import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/kanji_model.dart';
import '../services/kanji_service.dart';
import '../utils/korean_formatter.dart';
import 'study_screen.dart';

class WordsScreen extends StatefulWidget {
  const WordsScreen({super.key});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  final KanjiService _kanjiService = KanjiService.instance;
  
  List<Kanji> _allKanji = [];
  List<Kanji> _filteredKanji = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKanji();
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

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applyFilters();
    });
  }

  void _navigateToStudy(Kanji kanji) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudyScreen(kanji: kanji),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    
    return FScaffold(
      header: FHeader(
        title: Text(
          '단어 목록',
          style: TextStyle(fontFamily: 'SUITE'),
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: '한자, 의미, 읽기로 검색...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: theme.colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: theme.colors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: theme.colors.primary),
                          ),
                          filled: true,
                          fillColor: theme.colors.background,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '전체 ${_filteredKanji.length}개',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                          fontFamily: 'SUITE',
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Kanji Grid
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadKanji(forceReload: true),
                    child: _filteredKanji.isEmpty
                        ? Center(
                            child: Text(
                              '검색 결과가 없습니다',
                              style: theme.typography.base.copyWith(
                                color: theme.colors.mutedForeground,
                                fontFamily: 'SUITE',
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                        Icons.check,
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
                      isFavorite ? Icons.star : Icons.star_border,
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
                          fontSize: 11,
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