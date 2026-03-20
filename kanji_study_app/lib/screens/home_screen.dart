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
import '../widgets/monthly_word_heatmap.dart';
import '../widgets/today_learning_goal_card.dart';
import '../widgets/news_placeholder_card.dart';
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
  List<DailyStudyStats> _monthlyData = [];
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
        _analyticsService.getMonthlyStats(),
      ]);

      if (!mounted) return;

      setState(() {
        todayKanji = kanji;
        _stats = results[0] as UserStats;
        _monthlyData = results[1] as List<DailyStudyStats>;
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
      MaterialPageRoute(
        builder: (context) => KanjiDetailScreen(kanji: todayKanji!),
      ),
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
          CustomHeader(title: const Text('こんな漢字')),
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
                          // 1) Heatmap
                          MonthlyWordHeatmap(data: _monthlyData),
                          const SizedBox(height: 24),

                          // 2) Today's learning goal
                          TodayLearningGoalCard(
                            stats: _stats!,
                            todayKanji: todayKanji!,
                            onStartStudy: _navigateToStudy,
                            onReviewTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('복습 기능은 곧 추가될 예정입니다.'),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // 3) News / updates placeholder
                          const NewsPlaceholderCard(),
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
