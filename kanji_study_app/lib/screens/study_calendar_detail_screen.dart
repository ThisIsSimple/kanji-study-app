import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../models/daily_study_stats.dart';

class StudyCalendarDetailScreen extends StatefulWidget {
  final DateTime date;
  
  const StudyCalendarDetailScreen({
    super.key,
    required this.date,
  });

  @override
  State<StudyCalendarDetailScreen> createState() => _StudyCalendarDetailScreenState();
}

class _StudyCalendarDetailScreenState extends State<StudyCalendarDetailScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  List<Map<String, dynamic>> _studyDetails = [];
  DailyStudyStats? _dailyStats;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadStudyDetails();
  }
  
  Future<void> _loadStudyDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load detailed study items
      final details = await _supabaseService.getDateStudyDetails(widget.date);
      
      // Load daily statistics
      final stats = await _supabaseService.getDailyStudyStats(
        startDate: widget.date,
        endDate: widget.date.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
      );
      
      setState(() {
        _studyDetails = details;
        _dailyStats = stats.isNotEmpty ? stats.first : null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading study details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    
    return FScaffold(
      header: FHeader.nested(
        title: Text(
          DateFormat('yyyy년 MM월 dd일').format(widget.date),
          style: const TextStyle(fontFamily: 'SUITE'),
        ),
        prefixes: [
          FHeaderAction.back(
            onPress: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _studyDetails.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIconsRegular.calendarBlank,
                        size: 64,
                        color: theme.colors.mutedForeground,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '이 날짜에 학습 기록이 없습니다',
                        style: theme.typography.base.copyWith(
                          color: theme.colors.mutedForeground,
                          fontFamily: 'SUITE',
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Summary Card
                      if (_dailyStats != null) ...[
                        FCard(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: _buildSummaryCard(theme),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Study Items Header
                      Text(
                        '학습 항목',
                        style: theme.typography.lg.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SUITE',
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Study Items List
                      ..._studyDetails.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildStudyItemCard(item, theme),
                      )),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildSummaryCard(FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '일일 요약',
          style: theme.typography.lg.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'SUITE',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: PhosphorIconsRegular.translate,
                label: '한자',
                value: '${_dailyStats!.kanjiStudied}개',
                color: theme.colors.primary,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                icon: PhosphorIconsRegular.bookOpen,
                label: '단어',
                value: '${_dailyStats!.wordsStudied}개',
                color: theme.colors.secondary,
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: PhosphorIconsRegular.checkCircle,
                label: '학습 완료',
                value: '${_dailyStats!.totalCompleted}회',
                color: Colors.green,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                icon: PhosphorIconsRegular.warningCircle,
                label: '까먹음',
                value: '${_dailyStats!.totalForgot}회',
                color: Colors.orange,
                theme: theme,
              ),
            ),
          ],
        ),
        if (_dailyStats!.successRate > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIconsRegular.chartLine,
                  size: 20,
                  color: theme.colors.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '성공률: ${(_dailyStats!.successRate * 100).toStringAsFixed(1)}%',
                  style: theme.typography.base.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colors.secondary,
                    fontFamily: 'SUITE',
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required FThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.typography.xs.copyWith(
              color: theme.colors.mutedForeground,
              fontFamily: 'SUITE',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.typography.base.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'SUITE',
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStudyItemCard(Map<String, dynamic> item, FThemeData theme) {
    final isKanji = item['type'] == 'kanji';
    final status = item['status'] as String;
    final studiedAt = DateTime.parse(item['studiedAt']);
    
    Color getStatusColor() {
      switch (status) {
        case 'completed':
          return Colors.green;
        case 'forgot':
          return Colors.orange;
        case 'reviewing':
          return Colors.blue;
        case 'mastered':
          return Colors.purple;
        default:
          return theme.colors.mutedForeground;
      }
    }
    
    String getStatusText() {
      switch (status) {
        case 'completed':
          return '학습 완료';
        case 'forgot':
          return '까먹음';
        case 'reviewing':
          return '복습 중';
        case 'mastered':
          return '마스터';
        default:
          return status;
      }
    }
    
    IconData getStatusIcon() {
      switch (status) {
        case 'completed':
          return PhosphorIconsRegular.checkCircle;
        case 'forgot':
          return PhosphorIconsRegular.warningCircle;
        case 'reviewing':
          return PhosphorIconsRegular.arrowsClockwise;
        case 'mastered':
          return PhosphorIconsRegular.trophy;
        default:
          return PhosphorIconsRegular.circle;
      }
    }
    
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Type Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isKanji 
                    ? theme.colors.primary.withValues(alpha: 0.1)
                    : theme.colors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  isKanji ? PhosphorIconsRegular.translate : PhosphorIconsRegular.bookOpen,
                  size: 20,
                  color: isKanji ? theme.colors.primary : theme.colors.secondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isKanji) ...[
                    Text(
                      item['character'],
                      style: GoogleFonts.notoSerifJp(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colors.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['meanings'],
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                        fontFamily: 'SUITE',
                      ),
                    ),
                  ] else ...[
                    Text(
                      item['word'],
                      style: GoogleFonts.notoSerifJp(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colors.foreground,
                      ),
                    ),
                    if (item['reading'] != null && item['reading'].isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item['reading'],
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            
            // Status and Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        getStatusIcon(),
                        size: 14,
                        color: getStatusColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        getStatusText(),
                        style: theme.typography.xs.copyWith(
                          color: getStatusColor(),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SUITE',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(studiedAt),
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}