import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../models/kanji_model.dart';
import '../models/kanji_example.dart';
import '../models/study_record_model.dart';
import '../services/gemini_service.dart';
import '../services/supabase_service.dart';
import '../widgets/furigana_text.dart';
import '../utils/korean_formatter.dart';

class StudyScreen extends StatefulWidget {
  final Kanji kanji;
  final List<Kanji>? kanjiList;
  final int? currentIndex;

  const StudyScreen({
    super.key,
    required this.kanji,
    this.kanjiList,
    this.currentIndex,
  });

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final GeminiService _geminiService = GeminiService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;

  PageController? _pageController;
  int _currentIndex = 0;
  List<Kanji>? _kanjiList;
  Kanji? _currentKanji;

  bool _isGeneratingExamples = false;
  List<KanjiExample>? _generatedExamples;
  List<KanjiExample> _databaseExamples = [];
  bool _isLoadingExamples = true;

  StudyStats? _studyStats;
  bool _isLoadingStats = true;
  bool _isRecordingStudy = false;
  bool _showStrokeOrder = false;

  @override
  void initState() {
    super.initState();
    _kanjiList = widget.kanjiList ?? [widget.kanji];
    _currentIndex = widget.currentIndex ?? 0;
    _currentKanji = _kanjiList![_currentIndex];
    _pageController = PageController(initialPage: _currentIndex);
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
      await _supabaseService.recordStudy(
        type: StudyType.kanji,
        targetId: _currentKanji!.id,
        status: status,
      );

      // Reload stats after recording
      await _loadStudyStats();

      if (!mounted) return;
      // Use showDialog instead of SnackBar for better visibility
      showDialog(
        context: context,
          barrierDismissible: true,
          barrierColor: Colors.transparent,
          builder: (BuildContext dialogContext) {
            Future.delayed(const Duration(seconds: 2), () {
              if (Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext);
              }
            });

            return Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: status == StudyStatus.completed
                          ? FTheme.of(dialogContext).colors.primary
                          : FTheme.of(dialogContext).colors.destructive,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          status == StudyStatus.completed
                              ? PhosphorIconsRegular.checkCircle
                              : PhosphorIconsRegular.warningCircle,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status == StudyStatus.completed
                              ? '학습 완료를 기록했습니다!'
                              : '까먹음을 기록했습니다.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'SUITE',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
          barrierDismissible: true,
          barrierColor: Colors.transparent,
          builder: (BuildContext dialogContext) {
            Future.delayed(const Duration(seconds: 2), () {
              if (Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext);
              }
            });

            return Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: FTheme.of(dialogContext).colors.destructive,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          PhosphorIconsRegular.warning,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '기록 저장 실패: $e',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'SUITE',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
      );
    } finally {
      setState(() {
        _isRecordingStudy = false;
      });
    }
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

  Widget _buildExampleCard(
    KanjiExample example,
    FThemeData theme, {
    required String sourceLabel,
    required bool isPrimary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPrimary
              ? theme.colors.primary.withValues(alpha: 0.05)
              : theme.colors.secondary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary
                ? theme.colors.primary.withValues(alpha: 0.2)
                : theme.colors.border,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source label
            if (sourceLabel.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  sourceLabel,
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.primary,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SUITE',
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Japanese text with furigana
            FuriganaText(
              text: example.furigana.contains('[')
                  ? example.furigana
                  : example.japanese,
              style: GoogleFonts.notoSerifJp(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: theme.colors.foreground,
                height: 1.5, // 행간 조절
              ),
              rubyStyle: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
                fontSize: 10,
              ),
              spacing: -1.0, // 한자와 후리가나 사이 간격을 더 좁게
            ),
            const SizedBox(height: 8),
            // Korean translation
            Text(
              example.korean,
              style: theme.typography.base.copyWith(
                fontWeight: FontWeight.w500,
                fontFamily: 'SUITE',
              ),
            ),
            // Explanation if exists
            if (example.explanation != null &&
                example.explanation!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colors.mutedForeground.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  example.explanation!,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                    fontFamily: 'SUITE',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudyButton(FThemeData theme) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colors.background,
          border: Border(top: BorderSide(color: theme.colors.border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: _isLoadingStats
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _studyStats == null || _studyStats!.totalRecords == 0
              ? FButton(
                  onPress: _isRecordingStudy
                      ? null
                      : () => _recordStudy(StudyStatus.completed),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIconsRegular.checkCircle, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isRecordingStudy ? '기록 중...' : '학습 완료',
                        style: TextStyle(fontFamily: 'SUITE'),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _studyStats!.lastStudied != null
                                ? '${DateFormat('yyyy년 MM월 dd일').format(_studyStats!.lastStudied!)} 학습'
                                : '학습 기록',
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                              fontFamily: 'SUITE',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _studyStats!.summaryText,
                            style: theme.typography.base.copyWith(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SUITE',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FButton(
                      onPress: _isRecordingStudy
                          ? null
                          : () => _recordStudy(StudyStatus.forgot),
                      style: FButtonStyle.outline(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsRegular.warningCircle, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _isRecordingStudy ? '기록 중...' : '까먹음',
                            style: TextStyle(fontFamily: 'SUITE'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
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
                  padding: const EdgeInsets.all(24.0),
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
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colors.secondary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '의미',
                                style: theme.typography.sm.copyWith(
                                  color: theme.colors.mutedForeground,
                                  fontFamily: 'SUITE',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                kanji.meanings.join(', '),
                                style: theme.typography.lg.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'SUITE',
                                ),
                              ),
                            ],
                          ),
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
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '읽기',
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SUITE',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Korean reading
                      if (hasKoreanReadings(
                        kanji.koreanKunReadings,
                        kanji.koreanOnReadings,
                      )) ...[
                        Text(
                          '한국어',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                            fontFamily: 'SUITE',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            formatKoreanReadings(
                              kanji.koreanKunReadings,
                              kanji.koreanOnReadings,
                            ),
                            style: theme.typography.base.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colors.primary,
                              fontFamily: 'SUITE',
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Japanese readings
                      if (kanji.readings.on.isNotEmpty) ...[
                        Text(
                          '일본어 음독 (音読み)',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                            fontFamily: 'SUITE',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: kanji.readings.on.map((reading) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                reading,
                                style: theme.typography.base,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      if (kanji.readings.on.isNotEmpty &&
                          kanji.readings.kun.isNotEmpty)
                        const SizedBox(height: 16),
                      if (kanji.readings.kun.isNotEmpty) ...[
                        Text(
                          '일본어 훈독 (訓読み)',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                            fontFamily: 'SUITE',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: kanji.readings.kun.map((reading) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colors.secondary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                reading,
                                style: theme.typography.base,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
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
                  fontFamily: 'SUITE',
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('AI 예문 생성', style: TextStyle(fontFamily: 'SUITE')),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Display examples based on priority: DB examples > AI generated > default
          if (_isLoadingExamples) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ] else if (_databaseExamples.isNotEmpty ||
              _generatedExamples != null) ...[
            // Display database examples first
            if (_databaseExamples.isNotEmpty) ...[
              ..._databaseExamples.map(
                (example) => _buildExampleCard(
                  example,
                  theme,
                  sourceLabel: _getSourceLabel(example.source),
                  isPrimary: true,
                ),
              ),
            ],
            // Then display AI generated examples
            if (_generatedExamples != null) ...[
              ..._generatedExamples!.map(
                (example) => _buildExampleCard(
                  example,
                  theme,
                  sourceLabel: 'AI 생성',
                  isPrimary: false,
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
                    fontFamily: 'SUITE',
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
          title: Text('한자 학습', style: TextStyle(fontFamily: 'SUITE')),
          prefixes: [
            FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
          ],
        ),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // If no kanjiList provided, show single kanji without swipe
    if (_kanjiList!.length == 1) {
      return FScaffold(
        header: FHeader.nested(
          title: Text('한자 학습', style: TextStyle(fontFamily: 'SUITE')),
          prefixes: [
            FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: _buildKanjiPage(_currentKanji!, theme),
            ),
            _buildStudyButton(theme),
          ],
        ),
      );
    }

    // Show with PageView for swipe navigation
    return FScaffold(
      header: FHeader.nested(
        title: Text(
          '한자 학습 (${_currentIndex + 1}/${_kanjiList!.length})',
          style: TextStyle(fontFamily: 'SUITE'),
        ),
        prefixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: Stack(
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
          _buildStudyButton(theme),
        ],
      ),
    );
  }
}
