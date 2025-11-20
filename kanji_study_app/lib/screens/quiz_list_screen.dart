import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/quiz_set.dart';
import '../services/supabase_service.dart';
import 'quiz_detail_screen.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final TextEditingController _searchController = TextEditingController();
  List<QuizSet> _quizSets = [];
  bool _isLoading = true;
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadQuizSets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizSets() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final quizSets = await _supabaseService.getQuizSets(
        category: _selectedCategory,
      );

      setState(() {
        _quizSets = quizSets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('퀴즈 목록을 불러오는데 실패했습니다: $e')));
      }
    }
  }

  List<QuizSet> get _filteredQuizSets {
    if (_searchQuery.isEmpty) {
      return _quizSets;
    }

    return _quizSets.where((quiz) {
      return quiz.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (quiz.description?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);
    }).toList();
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadQuizSets();
  }

  void _navigateToQuizDetail(QuizSet quizSet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizDetailScreen(quizSet: quizSet),
      ),
    );
  }

  Color _getDifficultyColor(FThemeData theme, int? difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return theme.colors.mutedForeground;
    }
  }

  String _getDifficultyText(int? difficulty) {
    switch (difficulty) {
      case 1:
        return '초급';
      case 2:
        return '초중급';
      case 3:
        return '중급';
      case 4:
        return '중고급';
      case 5:
        return '고급';
      default:
        return '미설정';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colors.background,
              border: Border(
                bottom: BorderSide(color: theme.colors.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '퀴즈 검색...',
                    prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(PhosphorIconsRegular.x),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
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
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Category Filter
                Row(
                  children: [
                    Text(
                      '카테고리:',
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _CategoryChip(
                              label: '전체',
                              isSelected: _selectedCategory == null,
                              onTap: () => _onCategoryChanged(null),
                            ),
                            const SizedBox(width: 8),
                            _CategoryChip(
                              label: 'JLPT',
                              isSelected: _selectedCategory == 'jlpt',
                              onTap: () => _onCategoryChanged('jlpt'),
                            ),
                            const SizedBox(width: 8),
                            _CategoryChip(
                              label: '초등학교',
                              isSelected: _selectedCategory == 'elementary',
                              onTap: () => _onCategoryChanged('elementary'),
                            ),
                            const SizedBox(width: 8),
                            _CategoryChip(
                              label: '중학교',
                              isSelected: _selectedCategory == 'middle',
                              onTap: () => _onCategoryChanged('middle'),
                            ),
                            const SizedBox(width: 8),
                            _CategoryChip(
                              label: '일반',
                              isSelected: _selectedCategory == 'general',
                              onTap: () => _onCategoryChanged('general'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quiz List
          Expanded(
            child: _isLoading
                ? const Center(child: FCircularProgress())
                : _filteredQuizSets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIconsRegular.question,
                          size: 64,
                          color: theme.colors.mutedForeground,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? '검색 결과가 없습니다'
                              : '사용 가능한 퀴즈가 없습니다',
                          style: theme.typography.lg.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _filteredQuizSets.length,
                    itemBuilder: (context, index) {
                      final quizSet = _filteredQuizSets[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: FCard(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                            onTap: () => _navigateToQuizDetail(quizSet),
                            title: Text(
                              quizSet.title,
                              style: theme.typography.base.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (quizSet.description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    quizSet.description!,
                                    style: theme.typography.sm.copyWith(
                                      color: theme.colors.mutedForeground,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getDifficultyColor(
                                          theme,
                                          quizSet.difficultyLevel,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getDifficultyColor(
                                            theme,
                                            quizSet.difficultyLevel,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        _getDifficultyText(
                                          quizSet.difficultyLevel,
                                        ),
                                        style: theme.typography.xs.copyWith(
                                          color: _getDifficultyColor(
                                            theme,
                                            quizSet.difficultyLevel,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${quizSet.kanjiIds.length}문제',
                                      style: theme.typography.xs.copyWith(
                                        color: theme.colors.mutedForeground,
                                      ),
                                    ),
                                    if (quizSet.category != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '• ${quizSet.category}',
                                        style: theme.typography.xs.copyWith(
                                          color: theme.colors.mutedForeground,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: Icon(
                              PhosphorIconsRegular.caretRight,
                              size: 16,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colors.primary : theme.colors.secondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colors.primary : theme.colors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.typography.xs.copyWith(
            color: isSelected
                ? theme.colors.primaryForeground
                : theme.colors.foreground,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
