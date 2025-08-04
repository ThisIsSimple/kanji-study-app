import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/kanji_model.dart';
import '../services/kanji_service.dart';
import 'study_screen.dart';

class WordsScreen extends StatefulWidget {
  const WordsScreen({super.key});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> with SingleTickerProviderStateMixin {
  final KanjiService _kanjiService = KanjiService.instance;
  late TabController _tabController;
  
  List<Kanji> _allKanji = [];
  List<Kanji> _filteredKanji = [];
  String _searchQuery = '';
  int _selectedGrade = 0; // 0 = 전체
  int _selectedJlpt = 0; // 0 = 전체
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadKanji();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadKanji() async {
    try {
      await _kanjiService.init();
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
        final matchesReading = kanji.readings.all.any(
          (reading) => reading.toLowerCase().contains(query),
        );
        
        if (!matchesCharacter && !matchesMeaning && !matchesReading) {
          return false;
        }
      }
      
      // 학년 필터
      if (_selectedGrade > 0 && kanji.grade != _selectedGrade) {
        return false;
      }
      
      // JLPT 필터
      if (_selectedJlpt > 0 && kanji.jlpt != _selectedJlpt) {
        return false;
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
                  child: TextField(
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
                ),
                
                // Filter Tabs
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colors.border,
                        width: 1,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: theme.colors.foreground,
                    unselectedLabelColor: theme.colors.mutedForeground,
                    indicatorColor: theme.colors.primary,
                    tabs: const [
                      Tab(text: '전체'),
                      Tab(text: '학년별'),
                      Tab(text: 'JLPT별'),
                    ],
                  ),
                ),
                
                // Filter Chips
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // 전체 탭
                      Center(
                        child: Text(
                          '전체 ${_filteredKanji.length}개',
                          style: theme.typography.sm,
                        ),
                      ),
                      
                      // 학년별 탭
                      ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip('전체', _selectedGrade == 0, () {
                            setState(() {
                              _selectedGrade = 0;
                              _applyFilters();
                            });
                          }),
                          ...List.generate(7, (index) {
                            final grade = index + 1;
                            return _buildFilterChip(
                              grade <= 6 ? '$grade학년' : '중학교+',
                              _selectedGrade == grade,
                              () {
                                setState(() {
                                  _selectedGrade = grade;
                                  _applyFilters();
                                });
                              },
                            );
                          }),
                        ],
                      ),
                      
                      // JLPT별 탭
                      ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip('전체', _selectedJlpt == 0, () {
                            setState(() {
                              _selectedJlpt = 0;
                              _applyFilters();
                            });
                          }),
                          ...List.generate(5, (index) {
                            final level = 5 - index;
                            return _buildFilterChip(
                              'N$level',
                              _selectedJlpt == level,
                              () {
                                setState(() {
                                  _selectedJlpt = level;
                                  _applyFilters();
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Kanji List
                Expanded(
                  child: _filteredKanji.isEmpty
                      ? Center(
                          child: Text(
                            '검색 결과가 없습니다',
                            style: theme.typography.base.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
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
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    final theme = FTheme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
              ? theme.colors.primary 
              : theme.colors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                ? theme.colors.primary 
                : theme.colors.border,
            ),
          ),
          child: Text(
            label,
            style: theme.typography.sm.copyWith(
              color: isSelected 
                ? theme.colors.background 
                : theme.colors.foreground,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
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
                      Text(
                        '${kanji.readings.kun.join(', ')} | ${kanji.readings.on.join(', ')}',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'N${kanji.jlpt}',
                              style: theme.typography.xs,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              kanji.grade <= 6 
                                ? '${kanji.grade}학년' 
                                : '중학교+',
                              style: theme.typography.xs,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '#${kanji.frequency}',
                            style: theme.typography.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
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