import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/kanji_model.dart';
import '../models/user_stats_model.dart';
import '../models/daily_study_stats.dart';
import '../services/kanji_service.dart';
import '../services/notification_service.dart';
import '../services/connectivity_service.dart';
import '../services/analytics_service.dart';
import 'kanji_detail_screen.dart';
import '../widgets/streak_stats_row.dart';
import '../widgets/enhanced_progress_card.dart';
import '../widgets/weekly_heatmap.dart';
import '../widgets/quick_study_cards.dart';
import '../widgets/today_kanji_card.dart';
import '../widgets/custom_header.dart';
import '../constants/app_spacing.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final KanjiService _kanjiService = KanjiService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;

  Kanji? todayKanji;
  UserStats? _stats;
  List<DailyStudyStats> _weeklyData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _kanjiService.init();

      // Check if notifications are enabled and schedule default time if not set
      final isEnabled = await NotificationService.instance
          .areNotificationsEnabled();
      if (!isEnabled) {
        // Set default notification time to 9:00 AM
        await NotificationService.instance.scheduleDailyNotification(
          hour: 9,
          minute: 0,
        );
      }

      _loadData();
    } catch (e) {
      // Handle error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // 오프라인 상태에서 초기 다운로드 실패 시 안내
        if (!_connectivityService.isOnline) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('초기 데이터 다운로드를 위해 인터넷 연결이 필요합니다.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      final kanji = _kanjiService.getTodayKanji();

      // Load all data in parallel
      final results = await Future.wait([
        _analyticsService.getUserStats(),
        _analyticsService.getWeeklyStats(),
      ]);

      if (!mounted) return;

      setState(() {
        todayKanji = kanji;
        _stats = results[0] as UserStats;
        _weeklyData = results[1] as List<DailyStudyStats>;
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

  void _navigateToStudy() async {
    if (todayKanji == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => KanjiDetailScreen(kanji: todayKanji!)),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Column(
        children: [
          CustomHeader(
            title: const Text('こんな漢字'),
          ),
          // 메인 컨텐츠
          Expanded(
            child: _isLoading
                ? const Center(child: FCircularProgress())
                : _stats == null || todayKanji == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          PhosphorIconsRegular.warningCircle,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text('데이터를 불러올 수 없습니다', style: theme.typography.lg),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: AppSpacing.screenPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Streak/XP/Goal Row
                          StreakStatsRow(
                            streak: _stats!.streak,
                            xp: _stats!.totalXP,
                            todayProgress: _stats!.todayProgress,
                            dailyGoal: _stats!.dailyGoal,
                          ),
                          const SizedBox(height: 24),

                          // Enhanced Progress Card
                          EnhancedProgressCard(
                            studiedCount: _stats!.totalStudied,
                            masteredCount: _stats!.totalMastered,
                            weeklyCount: _stats!.weeklyCount,
                            weeklyAverage: _stats!.weeklyAverage,
                            nextMilestone: _stats!.nextMilestone,
                            remainingToMilestone: _stats!.remainingToMilestone,
                          ),
                          const SizedBox(height: 24),

                          // Weekly Heatmap
                          if (_weeklyData.isNotEmpty)
                            WeeklyHeatmap(data: _weeklyData),
                          if (_weeklyData.isNotEmpty)
                            const SizedBox(height: 24),

                          // Quick Study Cards
                          QuickStudyCards(
                            reviewQueueSize: _stats!.reviewQueueSize,
                            onTodayTap: _navigateToStudy,
                            onReviewTap: () {
                              // TODO: Navigate to review screen
                            },
                            onFavoritesTap: () {
                              // TODO: Navigate to favorites
                            },
                          ),
                          const SizedBox(height: 24),

                          // Today's Kanji Card
                          TodayKanjiCard(kanji: todayKanji!),
                          const SizedBox(height: 24),

                          // Study Button
                          FButton(
                            onPress: _navigateToStudy,
                            child: Text(
                              '📖 오늘의 한자 학습',
                              style: theme.typography.base.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
