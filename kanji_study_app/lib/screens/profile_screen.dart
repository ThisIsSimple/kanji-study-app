import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../services/kanji_service.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final KanjiService _kanjiService = KanjiService.instance;
  
  int _totalKanji = 0;
  int _studiedCount = 0;
  int _masteredCount = 0;
  double _progress = 0.0;
  final Map<int, int> _gradeProgress = {};
  final Map<int, int> _jlptProgress = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      await _kanjiService.init();
      
      setState(() {
        _totalKanji = _kanjiService.getAllKanji().length;
        _studiedCount = _kanjiService.getStudiedCount();
        _masteredCount = _kanjiService.getMasteredCount();
        _progress = _kanjiService.getOverallProgress();
        
        // Calculate progress by grade
        for (int grade = 1; grade <= 7; grade++) {
          final kanjiList = _kanjiService.getKanjiByGrade(grade);
          int studied = 0;
          for (final kanji in kanjiList) {
            final progress = _kanjiService.getProgress(kanji.character);
            if (progress != null) {
              studied++;
            }
          }
          _gradeProgress[grade] = studied;
        }
        
        // Calculate progress by JLPT
        for (int level = 1; level <= 5; level++) {
          final kanjiList = _kanjiService.getKanjiByJlpt(level);
          int studied = 0;
          for (final kanji in kanjiList) {
            final progress = _kanjiService.getProgress(kanji.character);
            if (progress != null) {
              studied++;
            }
          }
          _jlptProgress[level] = studied;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
    
    if (result == true) {
      _loadStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    
    return FScaffold(
      header: FHeader(
        title: const Text('프로필'),
        suffixes: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Info Card
                  FCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: theme.colors.secondary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: theme.colors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '한자 학습자',
                            style: theme.typography.lg.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '매일 꾸준히 학습 중',
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Overall Progress Card
                  FCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '전체 진도',
                            style: theme.typography.lg.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem(
                                '전체',
                                '$_totalKanji',
                                theme.colors.primary,
                              ),
                              _buildStatItem(
                                '학습',
                                '$_studiedCount',
                                theme.colors.primary.withValues(alpha: 0.7),
                              ),
                              _buildStatItem(
                                '마스터',
                                '$_masteredCount',
                                theme.colors.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: theme.colors.secondary.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_progress * 100).toStringAsFixed(1)}% 완료',
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress by Grade
                  FCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '학년별 진도',
                            style: theme.typography.lg.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(7, (index) {
                            final grade = index + 1;
                            final total = _kanjiService.getKanjiByGrade(grade).length;
                            final studied = _gradeProgress[grade] ?? 0;
                            final progress = total > 0 ? studied / total : 0.0;
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildProgressRow(
                                grade <= 6 ? '$grade학년' : '중학교+',
                                studied,
                                total,
                                progress,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress by JLPT
                  FCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'JLPT별 진도',
                            style: theme.typography.lg.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(5, (index) {
                            final level = index + 1;
                            final total = _kanjiService.getKanjiByJlpt(level).length;
                            final studied = _jlptProgress[level] ?? 0;
                            final progress = total > 0 ? studied / total : 0.0;
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildProgressRow(
                                'N$level',
                                studied,
                                total,
                                progress,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    final theme = FTheme.of(context);
    
    return Column(
      children: [
        Text(
          value,
          style: theme.typography.xl.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressRow(String label, int studied, int total, double progress) {
    final theme = FTheme.of(context);
    
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.typography.sm.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colors.secondary.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colors.primary.withValues(alpha: 0.8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$studied/$total',
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}