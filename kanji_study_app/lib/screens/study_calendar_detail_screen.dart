import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../models/daily_study_stats.dart';
import '../constants/app_spacing.dart';
import '../widgets/daily_summary_card.dart';

class StudyCalendarDetailScreen extends StatefulWidget {
  final DateTime date;

  const StudyCalendarDetailScreen({super.key, required this.date});

  @override
  State<StudyCalendarDetailScreen> createState() =>
      _StudyCalendarDetailScreenState();
}

class _StudyCalendarDetailScreenState extends State<StudyCalendarDetailScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;

  late PageController _pageController;
  late FCalendarController<DateTime?> _lineCalendarController;
  late DateTime _currentDate;
  final int _totalDays = 365 * 3; // 3 years of days
  late int _initialPage;
  bool _isSyncingFromLineCalendar = false;
  bool _isSyncingFromPageView = false;

  final Map<DateTime, List<Map<String, dynamic>>> _studyDetailsCache = {};
  final Map<DateTime, DailyStudyStats?> _dailyStatsCache = {};
  final Set<DateTime> _loadingDates = {};

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );
    _initialPage = _totalDays ~/ 2;
    _pageController = PageController(initialPage: _initialPage);
    _lineCalendarController = FCalendarController.date(
      initialSelection: _currentDate,
    );
    _loadStudyDetailsForDate(_currentDate);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _lineCalendarController.dispose();
    super.dispose();
  }

  DateTime _getDateFromPageIndex(int pageIndex) {
    final daysDifference = pageIndex - _initialPage;
    final normalizedInitialDate = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );
    return normalizedInitialDate.add(Duration(days: daysDifference));
  }

  int _getPageIndexFromDate(DateTime date) {
    final normalizedInitialDate = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final daysDifference = normalizedDate.difference(normalizedInitialDate).inDays;
    return _initialPage + daysDifference;
  }

  Future<void> _loadStudyDetailsForDate(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Update header title immediately
    if (!mounted) return;
    setState(() {
      _currentDate = normalizedDate;
    });

    // Check cache first - no loading needed
    if (_studyDetailsCache.containsKey(normalizedDate) &&
        _dailyStatsCache.containsKey(normalizedDate)) {
      return;
    }

    // Start loading for this specific date
    if (!mounted) return;
    setState(() {
      _loadingDates.add(normalizedDate);
    });

    try {
      // Load detailed study items
      final details = await _supabaseService.getDateStudyDetails(
        normalizedDate,
      );

      // Load daily statistics
      final stats = await _supabaseService.getDailyStudyStats(
        startDate: normalizedDate,
        endDate: normalizedDate.add(
          const Duration(hours: 23, minutes: 59, seconds: 59),
        ),
      );

      if (!mounted) return;
      setState(() {
        _studyDetailsCache[normalizedDate] = details;
        _dailyStatsCache[normalizedDate] = stats.isNotEmpty
            ? stats.first
            : null;
        _loadingDates.remove(normalizedDate);
      });
    } catch (e) {
      debugPrint('Error loading study details: $e');
      if (!mounted) return;
      setState(() {
        _studyDetailsCache[normalizedDate] = [];
        _dailyStatsCache[normalizedDate] = null;
        _loadingDates.remove(normalizedDate);
      });
    }
  }

  void _onPageChanged(int pageIndex) {
    if (_isSyncingFromLineCalendar) return;

    final newDate = _getDateFromPageIndex(pageIndex);
    _loadStudyDetailsForDate(newDate);

    // Sync FLineCalendar selection
    _isSyncingFromPageView = true;
    _lineCalendarController.value = newDate;
    _isSyncingFromPageView = false;
  }

  void _onLineCalendarChanged(DateTime? date) {
    if (date == null || _isSyncingFromPageView) return;

    _isSyncingFromLineCalendar = true;
    final pageIndex = _getPageIndexFromDate(date);

    // Load data for the selected date immediately
    _loadStudyDetailsForDate(date);

    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ).then((_) {
      _isSyncingFromLineCalendar = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return FScaffold(
      header: FHeader.nested(
        title: Text(
          DateFormat('yyyy년 MM월 dd일').format(_currentDate),
        ),
        prefixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: Column(
        children: [
          // FLineCalendar at the top
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: FLineCalendar(
              controller: _lineCalendarController,
              start: DateTime(2024, 1, 1),
              end: DateTime.now().add(const Duration(days: 365)),
              today: DateTime.now(),
              initialScroll: _currentDate,
              onChange: _onLineCalendarChanged,
            ),
          ),

          // PageView for swipe navigation
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _totalDays,
              itemBuilder: (context, index) {
                final pageDate = _getDateFromPageIndex(index);
                final normalizedPageDate = DateTime(
                  pageDate.year,
                  pageDate.month,
                  pageDate.day,
                );
                final studyDetails = _studyDetailsCache[normalizedPageDate] ?? [];
                final dailyStats = _dailyStatsCache[normalizedPageDate];

                if (_loadingDates.contains(normalizedPageDate)) {
                  return const Center(child: FCircularProgress());
                }

                if (studyDetails.isEmpty) {
                  return Center(
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
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Summary Card
                      if (dailyStats != null) ...[
                        FCard(
                          child: DailySummaryCard(
                            date: normalizedPageDate,
                            stats: dailyStats,
                            showDetailButton: false,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Study Items Header
                      Text(
                        '학습 항목',
                        style: theme.typography.lg.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Study Items List
                      ...studyDetails.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildStudyItemCard(item, theme),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
                  isKanji
                      ? PhosphorIconsRegular.translate
                      : PhosphorIconsRegular.bookOpen,
                  size: 20,
                  color: isKanji
                      ? theme.colors.primary
                      : theme.colors.secondary,
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
                    if (item['reading'] != null &&
                        item['reading'].isNotEmpty) ...[
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(getStatusIcon(), size: 14, color: getStatusColor()),
                      const SizedBox(width: 4),
                      Text(
                        getStatusText(),
                        style: theme.typography.xs.copyWith(
                          color: getStatusColor(),
                          fontWeight: FontWeight.w600,
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
    );
  }
}
