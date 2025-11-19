import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/kanji_model.dart';
import '../services/kanji_service.dart';
import '../services/notification_service.dart';
import '../services/connectivity_service.dart';
import 'study_screen.dart';
import '../widgets/progress_card.dart';
import '../widgets/today_kanji_card.dart';
import '../widgets/app_scaffold.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final KanjiService _kanjiService = KanjiService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  Kanji? todayKanji;
  int studiedCount = 0;
  int masteredCount = 0;
  double progress = 0.0;
  bool _isLoading = true;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();

    // 연결 상태 변경 감지
    _connectivityService.onConnectivityChanged.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });

    // 초기 연결 상태
    _isOnline = _connectivityService.isOnline;
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

  void _loadData() {
    if (!mounted) return;

    try {
      final kanji = _kanjiService.getTodayKanji();
      setState(() {
        todayKanji = kanji;
        studiedCount = _kanjiService.getStudiedCount();
        masteredCount = _kanjiService.getMasteredCount();
        progress = _kanjiService.getOverallProgress();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToStudy() async {
    if (todayKanji == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StudyScreen(kanji: todayKanji!)),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return AppScaffold(
      title: Text(
        '한자 학습',
        style: theme.typography.xl.copyWith(fontWeight: FontWeight.bold),
      ),
      body: Column(
        children: [
          // 오프라인 배너
          if (!_isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: theme.colors.muted,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIconsRegular.wifiSlash,
                    size: 16,
                    color: theme.colors.mutedForeground,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '오프라인 모드',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          // 메인 컨텐츠
          Expanded(
            child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : todayKanji == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIconsRegular.warningCircle, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    '한자 데이터를 불러올 수 없습니다',
                    style: theme.typography.lg,
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Card
                  ProgressCard(
                    progress: progress,
                    studiedCount: studiedCount,
                    masteredCount: masteredCount,
                  ),
                  const SizedBox(height: 24),

                  // Today's Kanji Card
                  TodayKanjiCard(kanji: todayKanji!),
                  const SizedBox(height: 32),

                  // Study Button
                  FButton(
                    onPress: _navigateToStudy,
                    child: Text('학습 시작'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
