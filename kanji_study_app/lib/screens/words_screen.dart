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
        // Force reload from Supabase
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
      // 검색어 필터
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
                        ? ListView(
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.5,
                                child: Center(
                                  child: Text(
                                    '검색 결과가 없습니다',
                                    style: theme.typography.base.copyWith(
                                      color: theme.colors.mutedForeground,
                                      fontFamily: 'SUITE',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(12.0),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _filteredKanji.length,
                            itemBuilder: (context, index) {
                              final kanji = _filteredKanji[index];
                              return _buildKanjiCard(kanji);
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }


  Widget _buildKanjiCard(Kanji kanji) {
    final theme = FTheme.of(context);
    final progress = _kanjiService.getProgress(kanji.character);
    final isFavorite = _kanjiService.isFavorite(kanji.character);
    
    return GestureDetector(
      onTap: () => _navigateToStudy(kanji),
      child: FCard(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Main content - maximizing space usage
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 20.0, bottom: 4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Kanji Character - bigger
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Text(
                                kanji.character,
                                style: GoogleFonts.notoSerifJp(
                                  fontSize: 50,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colors.foreground,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Korean readings
                        if (hasKoreanReadings(kanji.koreanKunReadings, kanji.koreanOnReadings))
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  formatKoreanReadings(kanji.koreanKunReadings, kanji.koreanOnReadings),
                                  style: theme.typography.sm.copyWith(
                                    color: theme.colors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'SUITE',
                                    fontSize: 13,
                                    height: 1.1,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        
                        // Japanese readings
                        if (kanji.readings.kun.isNotEmpty || kanji.readings.on.isNotEmpty)
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  '${kanji.readings.kun.join(', ')}${kanji.readings.kun.isNotEmpty && kanji.readings.on.isNotEmpty ? ', ' : ''}${kanji.readings.on.join(', ')}',
                                  style: theme.typography.xs.copyWith(
                                    color: theme.colors.mutedForeground,
                                    fontFamily: 'SUITE',
                                    fontSize: 11,
                                    height: 1.1,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Top left - Check mark for mastered
                if (progress != null && progress.mastered)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: theme.colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: theme.colors.background,
                      ),
                    ),
                  ),
                
                // Top right - Favorite button
                Positioned(
                  top: 0,
                  right: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _kanjiService.toggleFavorite(kanji.character);
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          isFavorite ? Icons.star : Icons.star_border,
                          size: 18,
                          color: isFavorite ? Colors.amber : theme.colors.mutedForeground,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}