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
        title: const Text('단어 목록'),
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
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Kanji List
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
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _filteredKanji.length,
                            itemBuilder: (context, index) {
                              final kanji = _filteredKanji[index];
                              return _buildKanjiTile(kanji);
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }


  Widget _buildKanjiTile(Kanji kanji) {
    final theme = FTheme.of(context);
    final progress = _kanjiService.getProgress(kanji.character);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () => _navigateToStudy(kanji),
        child: FCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Kanji Character
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    kanji.character,
                    style: GoogleFonts.notoSerifJp(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.colors.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Kanji Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              kanji.meanings.join(', '),
                              style: theme.typography.base.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (progress != null && progress.mastered)
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: theme.colors.primary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Korean readings
                      if (hasKoreanReadings(kanji.koreanKunReadings, kanji.koreanOnReadings)) ...[
                        Text(
                          '한국어: ${formatKoreanReadings(kanji.koreanKunReadings, kanji.koreanOnReadings)}',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.primary,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'SUITE',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                      ],
                      // Japanese readings
                      if (kanji.readings.kun.isNotEmpty || kanji.readings.on.isNotEmpty)
                        Text(
                          '일본어: ${kanji.readings.kun.join(', ')}${kanji.readings.kun.isNotEmpty && kanji.readings.on.isNotEmpty ? ', ' : ''}${kanji.readings.on.join(', ')}',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                
                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: theme.colors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}