import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../constants/app_spacing.dart';
import '../l10n/localization_extensions.dart';
import '../models/daily_study_stats.dart';
import '../services/language_settings_service.dart';
import '../models/learning_goal.dart';
import '../models/today_word_recommendation.dart';
import '../models/user_stats_model.dart';
import '../models/word_flashcard_adapter.dart';
import '../models/word_model.dart';
import '../services/analytics_service.dart';
import '../services/connectivity_service.dart';
import '../services/flashcard_service.dart';
import '../services/learning_goal_service.dart';
import '../services/notification_service.dart';
import '../services/today_word_recommendation_service.dart';
import '../services/word_service.dart';
import '../utils/study_session_launcher.dart';
import '../widgets/app_toast.dart';
import '../widgets/custom_header.dart';
import '../widgets/jlpt_badge.dart';
import 'study_calendar_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WordService _wordService = WordService.instance;
  final LearningGoalService _learningGoalService = LearningGoalService.instance;
  final TodayWordRecommendationService _recommendationService =
      TodayWordRecommendationService.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final FlashcardService _flashcardService = FlashcardService.instance;

  LearningGoal? _goal;
  UserStats? _stats;
  List<DailyStudyStats> _weeklyData = [];
  List<TodayWordRecommendation> _todayWords = [];
  bool _isLoading = true;
  bool _isSavingGoal = false;
  int _draftDailyGoal = 10;
  int _draftJlptLevel = 5;

  @override
  void initState() {
    super.initState();
    _learningGoalService.addListener(_handleLearningGoalChanged);
    _initializeServices();
  }

  @override
  void dispose() {
    _learningGoalService.removeListener(_handleLearningGoalChanged);
    super.dispose();
  }

  void _handleLearningGoalChanged() {
    if (_isSavingGoal) return;
    _reloadAfterLearningGoalChanged();
  }

  Future<void> _reloadAfterLearningGoalChanged() async {
    await _analyticsService.clearCache();
    await _loadData();
  }

  Future<void> _initializeServices() async {
    try {
      await _wordService.init();

      final isEnabled = await NotificationService.instance
          .areNotificationsEnabled();
      if (!isEnabled) {
        await NotificationService.instance.scheduleDailyNotification(
          hour: 9,
          minute: 0,
        );
      }

      await _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!_connectivityService.isOnline) {
        showAppToast(
          context,
          message: context.l10n.initialDataRequiresInternet,
          type: AppToastType.error,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final goal = await _learningGoalService.getGoal();
      final weeklyStats = await _analyticsService.getWeeklyStats();

      if (goal == null) {
        if (!mounted) return;
        setState(() {
          _goal = null;
          _stats = null;
          _weeklyData = weeklyStats;
          _todayWords = [];
          _isLoading = false;
        });
        return;
      }

      final stats = await _analyticsService.getUserStats(
        dailyGoal: goal.dailyGoal,
      );
      final recommendations = await _recommendationService.getTodayWords(
        goal: goal,
        alreadyStudiedToday: stats.todayProgress,
      );

      if (!mounted) return;
      setState(() {
        _goal = goal;
        _draftDailyGoal = goal.dailyGoal;
        _draftJlptLevel = goal.targetJlptLevel;
        _stats = stats;
        _weeklyData = weeklyStats;
        _todayWords = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading home data: $e');
      if (!mounted) return;

      setState(() {
        _stats = UserStats.empty();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveGoal() async {
    setState(() => _isSavingGoal = true);
    try {
      final result = await _learningGoalService.saveGoal(
        dailyGoal: _draftDailyGoal,
        targetJlptLevel: _draftJlptLevel,
      );
      await _analyticsService.clearCache();
      if (!mounted) return;
      showAppToast(
        context,
        message: result.syncedRemotely
            ? context.l10n.learningGoalSaved
            : context.l10n.learningGoalSavedLocalOnly,
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: context.l10n.learningGoalSaveFailed,
        type: AppToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingGoal = false);
      }
    }
  }

  Future<void> _startTodayStudy() async {
    final words = _todayWords.map((item) => item.word).toList();
    await StudySessionLauncher.launchFixed<Word>(
      context: context,
      itemType: 'word',
      items: words,
      flashcardService: _flashcardService,
      emptyMessage: context.l10n.noTodayWords,
      toFlashcardItems: (items) => items
          .map(
            (word) => WordFlashcardAdapter(
              word,
              meaningLanguage:
                  LanguageSettingsService.instance.wordMeaningLanguage,
            ),
          )
          .toList(),
      resumeItems: _wordService.allWords,
      onComplete: () async {
        await _analyticsService.clearCache();
        await _loadData();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Column(
        children: [
          CustomHeader(title: const Text('こんな漢字')),
          Expanded(
            child: _isLoading
                ? const Center(child: FCircularProgress())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: AppSpacing.screenPadding,
                      child: _goal == null || _stats == null
                          ? _buildGoalSetup(theme)
                          : _buildTodayDashboard(theme),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSetup(FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FCard(
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.trophy,
                      color: theme.colors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.todayGoalSetup,
                        style: theme.typography.lg.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.todayGoalSetupBody,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDailyGoalStepper(theme),
                const SizedBox(height: 20),
                _buildJlptSelector(theme),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FButton(
                    onPress: _isSavingGoal ? null : _saveGoal,
                    child: _isSavingGoal
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: FCircularProgress(),
                          )
                        : Text(context.l10n.saveGoal),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayDashboard(FThemeData theme) {
    final stats = _stats!;
    final goal = _goal!;
    final progress = stats.dailyProgressPercentage.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildWeeklyCalendar(theme),
        const SizedBox(height: 16),
        _buildProgressHeader(theme, goal, stats, progress),
        const SizedBox(height: 16),
        _buildTodayWordsCard(theme, stats),
      ],
    );
  }

  Widget _buildProgressHeader(
    FThemeData theme,
    LearningGoal goal,
    UserStats stats,
    double progress,
  ) {
    return FCard(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.todayWordStudy,
                        style: theme.typography.lg.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.dailyGoalSummary(
                          goal.targetJlptLevel,
                          goal.dailyGoal,
                        ),
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                JlptBadge(level: goal.targetJlptLevel, showPrefix: true),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.progress,
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  stats.dailyGoalProgressText,
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: progress,
                backgroundColor: theme.colors.secondary.withValues(alpha: 0.35),
                valueColor: AlwaysStoppedAnimation<Color>(theme.colors.primary),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              stats.isDailyGoalAchieved
                  ? context.l10n.dailyGoalCompleted
                  : context.l10n.remainingWords(stats.remainingForDailyGoal),
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyCalendar(FThemeData theme) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.thisWeek,
            style: theme.typography.md.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < 7; i++)
                _buildCalendarDay(startOfWeek.add(Duration(days: i)), theme),
            ],
          ),
        ],
      ),
    );
  }

  void _openCalendarDetail(DateTime date) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StudyCalendarDetailScreen(date: date),
      ),
    );
  }

  Widget _buildCalendarDay(DateTime date, FThemeData theme) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final isToday = DateUtils.isSameDay(normalizedDate, DateTime.now());
    final stats = _weeklyData.firstWhere(
      (item) => DateUtils.isSameDay(item.date, normalizedDate),
      orElse: () => DailyStudyStats(
        date: normalizedDate,
        kanjiStudied: 0,
        wordsStudied: 0,
        totalCompleted: 0,
        totalForgot: 0,
        studyItems: [],
      ),
    );
    final completed = stats.wordsStudied > 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openCalendarDetail(normalizedDate),
      child: SizedBox(
        width: 42,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('E', 'ko_KR').format(normalizedDate)[0],
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isToday
                    ? theme.colors.primary
                    : completed
                    ? const Color(0xFFE5F9C8)
                    : theme.colors.secondary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(18),
                border: completed && !isToday
                    ? Border.all(color: const Color(0xFFA3E635), width: 2)
                    : null,
              ),
              child: Text(
                '${normalizedDate.day}',
                style: theme.typography.sm.copyWith(
                  color: isToday
                      ? theme.colors.primaryForeground
                      : theme.colors.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayWordsCard(FThemeData theme, UserStats stats) {
    final isCompleted = stats.isDailyGoalAchieved;

    return FCard(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isCompleted
                        ? context.l10n.todayStudyCompleted
                        : context.l10n.todayWords,
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  context.l10n.countItems(_todayWords.length),
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isCompleted)
              _buildCompletedState(theme)
            else if (_todayWords.isEmpty)
              _buildEmptyRecommendations(theme)
            else ...[
              for (final item in _todayWords.take(6)) ...[
                _buildWordRow(theme, item),
                const SizedBox(height: 10),
              ],
              if (_todayWords.length > 6)
                Text(
                  context.l10n.otherWordsCount(_todayWords.length - 6),
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FButton(
                  onPress: _startTodayStudy,
                  child: Text(context.l10n.startTodayStudy),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWordRow(FThemeData theme, TodayWordRecommendation item) {
    final word = item.word;
    final wordMeaningLanguage =
        LanguageSettingsService.instance.wordMeaningLanguage;
    final meaningsText = word.displayMeaningsText(wordMeaningLanguage);
    final meaning = meaningsText.isEmpty
        ? context.l10n.noMeaning
        : meaningsText;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colors.secondary.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        word.word,
                        style: theme.typography.md.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    JlptBadge(level: word.jlptLevel, showPrefix: true),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  word.reading,
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  meaning,
                  style: theme.typography.sm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: item.isReview
                  ? const Color(0xFFFFF7ED)
                  : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: item.isReview
                    ? const Color(0xFFFED7AA)
                    : const Color(0xFFA7F3D0),
              ),
            ),
            child: Text(
              item.isReview ? context.l10n.review : context.l10n.newWord,
              style: theme.typography.xs.copyWith(
                fontWeight: FontWeight.w700,
                color: item.isReview
                    ? const Color(0xFFC2410C)
                    : const Color(0xFF047857),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedState(FThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        children: [
          Icon(
            PhosphorIconsFill.checkCircle,
            color: const Color(0xFF059669),
            size: 34,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.enoughStudyToday,
            style: theme.typography.md.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.tomorrowRecommendations,
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecommendations(FThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colors.secondary.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colors.border),
      ),
      child: Text(
        context.l10n.noRecommendations,
        style: theme.typography.sm.copyWith(
          color: theme.colors.mutedForeground,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDailyGoalStepper(FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.dailyWordCount,
          style: theme.typography.sm.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildStepButton(
              theme,
              icon: Icons.remove,
              onTap: _draftDailyGoal <= 1
                  ? null
                  : () => setState(() => _draftDailyGoal--),
            ),
            Expanded(
              child: Center(
                child: Text(
                  context.l10n.countItems(_draftDailyGoal),
                  style: theme.typography.xl.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            _buildStepButton(
              theme,
              icon: Icons.add,
              onTap: _draftDailyGoal >= 100
                  ? null
                  : () => setState(() => _draftDailyGoal++),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepButton(
    FThemeData theme, {
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null
              ? theme.colors.secondary.withValues(alpha: 0.2)
              : theme.colors.secondary.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colors.border),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null
              ? theme.colors.mutedForeground
              : theme.colors.foreground,
        ),
      ),
    );
  }

  Widget _buildJlptSelector(FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.targetJlpt,
          style: theme.typography.sm.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final level in const [5, 4, 3, 2, 1])
              _buildJlptOption(theme, level),
          ],
        ),
      ],
    );
  }

  Widget _buildJlptOption(FThemeData theme, int level) {
    final selected = _draftJlptLevel == level;
    return GestureDetector(
      onTap: () => setState(() => _draftJlptLevel = level),
      child: Container(
        width: 58,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? theme.colors.primary : theme.colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? theme.colors.primary : theme.colors.border,
          ),
        ),
        child: Text(
          'N$level',
          style: theme.typography.sm.copyWith(
            color: selected
                ? theme.colors.primaryForeground
                : theme.colors.foreground,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
