import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/word_model.dart';
import '../services/word_service.dart';
import '../widgets/word_list_item.dart';

class WordsScreen extends StatefulWidget {
  const WordsScreen({super.key});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  final WordService _wordService = WordService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<Word> _filteredWords = [];
  String _searchQuery = '';
  int? _selectedJlptLevel;
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
      if (_showOnlyFavorites) {
        _filteredWords = _wordService.getFavoriteWords();
        
        // Apply search and level filters on favorites
        if (_searchQuery.isNotEmpty) {
          _filteredWords = _filteredWords
              .where((word) => word.matchesQuery(_searchQuery))
              .toList();
        }
        
        if (_selectedJlptLevel != null) {
          _filteredWords = _filteredWords
              .where((word) => word.jlptLevel == _selectedJlptLevel)
              .toList();
        }
      } else {
        _filteredWords = _wordService.searchWords(
          _searchQuery,
          jlptLevel: _selectedJlptLevel,
        );
      }
    });
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _applyFilters();
  }

  void _toggleJlptFilter(int level) {
    setState(() {
      if (_selectedJlptLevel == level) {
        _selectedJlptLevel = null;
      } else {
        _selectedJlptLevel = level;
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
                // Search and filters section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Search bar
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: '일본어, 한글, 후리가나로 검색...',
                          prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(PhosphorIconsRegular.x),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
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
                      
                      const SizedBox(height: 12),
                      
                      // Filters row (Favorite + JLPT levels)
                      Row(
                        children: [
                          // Favorite filter button
                          FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _showOnlyFavorites 
                                      ? PhosphorIconsFill.star 
                                      : PhosphorIconsRegular.star,
                                  size: 16,
                                  color: _showOnlyFavorites 
                                      ? Colors.amber 
                                      : theme.colors.mutedForeground,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '즐겨찾기',
                                  style: TextStyle(
                                    fontFamily: 'SUITE',
                                    fontWeight: _showOnlyFavorites 
                                        ? FontWeight.w600 
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            selected: _showOnlyFavorites,
                            onSelected: (_) => _toggleFavoriteFilter(),
                            backgroundColor: theme.colors.background,
                            selectedColor: Colors.amber.withValues(alpha: 0.1),
                            checkmarkColor: Colors.transparent,
                            side: BorderSide(
                              color: _showOnlyFavorites 
                                  ? Colors.amber 
                                  : theme.colors.border,
                              width: _showOnlyFavorites ? 2 : 1,
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // JLPT level filter tags
                          Expanded(
                            child: SizedBox(
                              height: 32,
                              child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 5,
                          separatorBuilder: (context, index) => 
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final level = 5 - index; // N5 to N1
                            final isSelected = _selectedJlptLevel == level;
                            
                            return FilterChip(
                              label: Text(
                                'N$level',
                                style: TextStyle(
                                  fontFamily: 'SUITE',
                                  fontWeight: isSelected 
                                      ? FontWeight.w600 
                                      : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) => _toggleJlptFilter(level),
                              backgroundColor: theme.colors.background,
                              selectedColor: theme.colors.primary.withValues(alpha: 0.1),
                              checkmarkColor: theme.colors.primary,
                              side: BorderSide(
                                color: isSelected 
                                    ? theme.colors.primary 
                                    : theme.colors.border,
                                width: isSelected ? 2 : 1,
                              ),
                            );
                          },
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Results count
                      Text(
                        _showOnlyFavorites
                            ? '즐겨찾기 ${_filteredWords.length}개'
                            : '검색 결과 ${_filteredWords.length}개',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                          fontFamily: 'SUITE',
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Words list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _wordService.reloadData();
                      _applyFilters();
                    },
                    child: _filteredWords.isEmpty
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
                                      ? '즐겨찾기한 단어가 없습니다'
                                      : '검색 결과가 없습니다',
                                  style: theme.typography.base.copyWith(
                                    color: theme.colors.mutedForeground,
                                    fontFamily: 'SUITE',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredWords.length,
                            itemBuilder: (context, index) {
                              final word = _filteredWords[index];
                              return WordListItem(
                                word: word,
                                isFavorite: _wordService.isFavorite(word.id),
                                onTap: () {
                                  // TODO: Navigate to word detail screen
                                  // For now, just show a snackbar
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${word.word} (${word.reading})'),
                                      duration: const Duration(seconds: 1),
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