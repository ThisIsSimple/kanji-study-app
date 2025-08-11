import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/word_model.dart';
import '../services/word_service.dart';
import '../widgets/word_list_item.dart';
import 'word_detail_screen.dart';

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
  final Set<int> _selectedJlptLevels = {};
  bool _isLoading = true;
  bool _showOnlyFavorites = false;
  bool _showSearchBar = false;

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
        words = words.where((word) => _selectedJlptLevels.contains(word.jlptLevel)).toList();
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
                            fontFamily: 'SUITE',
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            '완료',
                            style: TextStyle(
                              fontFamily: 'SUITE',
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
                          fontFamily: 'SUITE',
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
    
    return FScaffold(
      header: Stack(
        children: [
          FHeader(
            title: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _showOnlyFavorites
                    ? '즐겨찾기 ${_filteredWords.length}개'
                    : _selectedJlptLevels.isEmpty
                        ? '전체 ${_filteredWords.length}개'
                        : 'JLPT ${_selectedJlptLevels.map((l) => "N$l").join(", ")} - ${_filteredWords.length}개',
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
                      icon: Stack(
                        children: [
                          Icon(
                            PhosphorIconsRegular.funnel,
                            size: 20,
                          ),
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
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: '일본어, 한글, 후리가나로 검색...',
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
          : RefreshIndicator(
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
                            padding: const EdgeInsets.only(top: 8, bottom: 16),
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
                                      builder: (context) => WordDetailScreen(word: word),
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
    );
  }
}