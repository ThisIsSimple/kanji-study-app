import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/kanji_model.dart';
import '../models/kanji_example.dart';
import '../models/study_record_model.dart';
import '../services/gemini_service.dart';
import '../services/supabase_service.dart';
import '../services/kanji_service.dart';
import '../services/study_record_service.dart';
import '../widgets/example_card.dart';
import '../widgets/jlpt_badge.dart';
import '../widgets/grade_badge.dart';
import '../widgets/app_toast.dart';
import '../widgets/study_button_bar.dart';
import '../utils/korean_formatter.dart';

class KanjiDetailScreen extends StatefulWidget {
  final Kanji kanji;
  final List<Kanji>? kanjiList;
  final int? currentIndex;

  const KanjiDetailScreen({
    super.key,
    required this.kanji,
    this.kanjiList,
    this.currentIndex,
  });

  @override
  State<KanjiDetailScreen> createState() => _KanjiDetailScreenState();
}

class _KanjiDetailScreenState extends State<KanjiDetailScreen> {
  final GeminiService _geminiService = GeminiService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;
  final KanjiService _kanjiService = KanjiService.instance;
  final StudyRecordService _studyRecordService = StudyRecordService.instance;

  PageController? _pageController;
  int _currentIndex = 0;
  List<Kanji>? _kanjiList;
  Kanji? _currentKanji;
  bool _isFavorite = false;

  bool _isGeneratingExamples = false;
  List<KanjiExample>? _generatedExamples;
  List<KanjiExample> _databaseExamples = [];
  bool _isLoadingExamples = true;

  StudyStats? _studyStats;
  bool _isLoadingStats = true;
  bool _isRecordingStudy = false;
  bool _showStrokeOrder = false;

  // GlobalKey to access FScaffold context for toasts
  final GlobalKey<State> _scaffoldKey = GlobalKey<State>();

  @override
  void initState() {
    super.initState();
    _kanjiList = widget.kanjiList ?? [widget.kanji];
    _currentIndex = widget.currentIndex ?? 0;
    _currentKanji = _kanjiList![_currentIndex];
    _pageController = PageController(initialPage: _currentIndex);
    _isFavorite = _kanjiService.isFavorite(_currentKanji!.character);
    _loadDatabaseExamples();
    _loadStudyStats();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_kanjiList != null) {
      setState(() {
        _currentIndex = index;
        _currentKanji = _kanjiList![index];
        _isFavorite = _kanjiService.isFavorite(_currentKanji!.character);
        _generatedExamples = null;
        _databaseExamples = [];
        _studyStats = null;
        _isLoadingStats = true;
        _showStrokeOrder = false;
      });
      _loadDatabaseExamples();
      _loadStudyStats();
    }
  }

  Future<void> _loadDatabaseExamples() async {
    setState(() {
      _isLoadingExamples = true;
    });

    try {
      // Load examples from database using kanji id
      if (_currentKanji == null) return;
      final examples = await _supabaseService.getKanjiExamples(
        _currentKanji!.id,
      );
      setState(() {
        _databaseExamples = examples;
        _isLoadingExamples = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingExamples = false;
      });
      debugPrint('Error loading database examples: $e');
    }
  }

  Future<void> _loadStudyStats() async {
    if (_currentKanji == null) return;

    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await _supabaseService.getStudyStats(
        type: StudyType.kanji,
        targetId: _currentKanji!.id,
      );
      setState(() {
        _studyStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
      debugPrint('Error loading study stats: $e');
    }
  }

  Future<void> _recordStudy(StudyStatus status) async {
    if (_currentKanji == null || _isRecordingStudy) return;

    setState(() {
      _isRecordingStudy = true;
    });

    try {
      await _studyRecordService.addRecord(
        type: 'kanji',
        targetId: _currentKanji!.id,
        status: status == StudyStatus.completed ? 'completed' : 'forgot',
      );

      // Reload stats after recording
      await _loadStudyStats();

      if (!mounted) return;
      final scaffoldContext = _scaffoldKey.currentContext;
      if (scaffoldContext == null) return;
      final isCompleted = status == StudyStatus.completed;
      showAppToast(
        scaffoldContext,
        message: isCompleted ? '학습 완료를 기록했습니다!' : '까먹음을 기록했습니다.',
        type: isCompleted ? AppToastType.info : AppToastType.error,
        icon: isCompleted
            ? PhosphorIconsRegular.checkCircle
            : PhosphorIconsRegular.warningCircle,
      );
    } catch (e) {
      if (!mounted) return;
      final scaffoldContext = _scaffoldKey.currentContext;
      if (scaffoldContext == null) return;
      showAppToast(
        scaffoldContext,
        message: '기록 저장 실패: $e',
        type: AppToastType.error,
        icon: PhosphorIconsRegular.warning,
      );
    } finally {
      setState(() {
        _isRecordingStudy = false;
      });
    }
  }

  void _toggleFavorite() {
    if (_currentKanji == null) return;
    setState(() {
      _kanjiService.toggleFavorite(_currentKanji!.character);
      _isFavorite = !_isFavorite;
    });
  }
  Future<void> _generateExamples() async {
    if (_isGeneratingExamples) return;

    setState(() {
      _isGeneratingExamples = true;
    });

    try {
      if (_currentKanji == null) return;
      final examples = await _geminiService.generateExamples(_currentKanji!);
      setState(() {
        _generatedExamples = examples;
        _isGeneratingExamples = false;
      });
    } catch (e) {
      setState(() {
        _isGeneratingExamples = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예문 생성 실패: $e'),
            backgroundColor: FTheme.of(context).colors.destructive,
          ),
        );
      }
    }
  }

  String _getSourceLabel(String? source) {
    switch (source) {
      case 'gemini':
        return 'AI 생성';
      case 'user':
        return '사용자 제공';
      case 'manual':
        return '수동 입력';
      default:
        return '';
    }
  }

  Widget _buildKanjiPage(Kanji kanji, FThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Kanji Card
          FCard(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          kanji.character,
                          style: _showStrokeOrder
                              ? TextStyle(
                                  fontFamily: 'KanjiStrokeOrders',
                                  fontSize: 100, // 100pt 이상 권장 (획순 숫자 표시를 위해)
                                  fontWeight: FontWeight.normal,
                                  color: theme.colors.foreground,
                                )
                              : GoogleFonts.notoSerifJp(
                                  fontSize: 72,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colors.foreground,
                                ),
                        ),
                        const SizedBox(height: 24),

                        // Meanings
                        Text(
                          formatKoreanReadings(
                            kanji.koreanKunReadings,
                            kanji.koreanOnReadings,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // JLPT and Grade badges - 가로 정렬
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            if (kanji.grade > 0) GradeBadge(grade: kanji.grade),
                            if (kanji.jlpt > 0)
                              JlptBadge(level: kanji.jlpt, showPrefix: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Stroke Order Toggle Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showStrokeOrder = !_showStrokeOrder;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _showStrokeOrder
                              ? theme.colors.primary
                              : theme.colors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _showStrokeOrder
                                ? theme.colors.primary
                                : theme.colors.border,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          PhosphorIconsRegular.path,
                          size: 20,
                          color: _showStrokeOrder
                              ? Colors.white
                              : theme.colors.mutedForeground,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details Section
          // Readings Card
          FCard(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 부수 (radical)
                  if (kanji.radical != null && kanji.radical!.isNotEmpty) ...[
                    Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '부수',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colors.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            kanji.radical!,
                            style: theme.typography.base,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  // 훈독 (kun readings) - 표시 순서 변경
                  if (kanji.readings.kun.isNotEmpty) ...[
                    Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '훈독',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ...kanji.readings.kun.map((reading) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colors.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(reading, style: theme.typography.base),
                          );
                        }),
                      ],
                    ),
                  ],
                  if (kanji.readings.kun.isNotEmpty &&
                      kanji.readings.on.isNotEmpty)
                    const SizedBox(height: 16),
                  // 음독 (on readings)
                  if (kanji.readings.on.isNotEmpty) ...[
                    Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '음독',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ...kanji.readings.on.map((reading) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colors.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(reading, style: theme.typography.base),
                          );
                        }),
                      ],
                    ),
                  ],
                  // 한자 해설 (commentary)
                  if (kanji.commentary != null &&
                      kanji.commentary!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '한자 해설',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        kanji.commentary!,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.foreground,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Examples Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '예시',
                style: theme.typography.lg.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_geminiService.isInitialized)
                FButton(
                  onPress: _isGeneratingExamples ? null : _generateExamples,
                  style: FButtonStyle.outline(),
                  child: _isGeneratingExamples
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: FCircularProgress(),
                        )
                      : Text('AI 예문 생성', style: TextStyle()),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Display examples based on priority: DB examples > AI generated > default
          if (_isLoadingExamples) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: FCircularProgress(),
              ),
            ),
          ] else if (_databaseExamples.isNotEmpty ||
              _generatedExamples != null) ...[
            // Display database examples first
            if (_databaseExamples.isNotEmpty) ...[
              ..._databaseExamples.map(
                (example) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ExampleCard(
                    japanese: example.japanese,
                    furigana: example.furigana,
                    korean: example.korean,
                    explanation: example.explanation,
                    sourceLabel: _getSourceLabel(example.source),
                  ),
                ),
              ),
            ],
            // Then display AI generated examples
            if (_generatedExamples != null) ...[
              ..._generatedExamples!.map(
                (example) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ExampleCard(
                    japanese: example.japanese,
                    furigana: example.furigana,
                    korean: example.korean,
                    explanation: example.explanation,
                    sourceLabel: 'AI 생성',
                  ),
                ),
              ),
            ],
          ] else if (kanji.examples.isNotEmpty) ...[
            // Fallback to legacy examples
            ...kanji.examples.map((example) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colors.secondary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colors.border, width: 1),
                  ),
                  child: Text(example.toString(), style: theme.typography.base),
                ),
              );
            }),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  '예문이 없습니다.',
                  style: theme.typography.base.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    // Wait for initialization
    if (_kanjiList == null || _currentKanji == null) {
      return FScaffold(
        header: FHeader.nested(
          title: Text(
            '한자 학습',
            style: theme.typography.xl.copyWith(fontWeight: FontWeight.bold),
          ),
          prefixes: [
            FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
          ],
        ),
        child: Center(child: FCircularProgress()),
      );
    }

    // If no kanjiList provided, show single kanji without swipe
    if (_kanjiList!.length == 1) {
      return FScaffold(
        header: FHeader.nested(
          title: Text(
            '한자 학습',
            style: theme.typography.xl.copyWith(fontWeight: FontWeight.bold),
          ),
          prefixes: [
            FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
          ],
          suffixes: [
            IconButton(
              icon: Icon(
                _isFavorite
                    ? PhosphorIconsFill.star
                    : PhosphorIconsRegular.star,
                color: _isFavorite ? Colors.amber : null,
              ),
              onPressed: _toggleFavorite,
            ),
          ],
        ),
        child: Builder(
          key: _scaffoldKey,
          builder: (context) => Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: _buildKanjiPage(_currentKanji!, theme),
              ),
              StudyButtonBar(
                isLoading: _isLoadingStats,
                isRecording: _isRecordingStudy,
                studyStats: _studyStats,
                onStudyComplete: () => _recordStudy(StudyStatus.completed),
                onForgot: () => _recordStudy(StudyStatus.forgot),
                onShowTimeline: () => StudyButtonBar.showTimelineSheet(
                  context: context,
                  studyStats: _studyStats,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show with PageView for swipe navigation
    return FScaffold(
      header: FHeader.nested(
        title: Text(
          '한자 학습 (${_currentIndex + 1}/${_kanjiList!.length})',
          style: theme.typography.xl.copyWith(fontWeight: FontWeight.bold),
        ),
        prefixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
        suffixes: [
          IconButton(
            icon: Icon(
              _isFavorite ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
              color: _isFavorite ? Colors.amber : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      child: Builder(
        key: _scaffoldKey,
        builder: (context) => Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: PageView.builder(
                controller: _pageController!,
                onPageChanged: _onPageChanged,
                itemCount: _kanjiList!.length,
                itemBuilder: (context, index) {
                  return _buildKanjiPage(_kanjiList![index], theme);
                },
              ),
            ),
            StudyButtonBar(
              isLoading: _isLoadingStats,
              isRecording: _isRecordingStudy,
              studyStats: _studyStats,
              onStudyComplete: () => _recordStudy(StudyStatus.completed),
              onForgot: () => _recordStudy(StudyStatus.forgot),
              onShowTimeline: () => StudyButtonBar.showTimelineSheet(
                context: context,
                studyStats: _studyStats,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
