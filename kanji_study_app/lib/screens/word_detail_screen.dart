import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import '../models/word_model.dart';
import '../models/word_example_model.dart';
import '../models/study_record_model.dart';
import '../services/word_service.dart';
import '../services/gemini_service.dart';
import '../services/supabase_service.dart';
import '../services/study_record_service.dart';
import '../widgets/example_card.dart';
import '../widgets/jlpt_badge.dart';
import '../widgets/app_toast.dart';
import '../widgets/study_button_bar.dart';

class WordDetailScreen extends StatefulWidget {
  final Word word;
  final List<Word>? wordList;
  final int? currentIndex;

  const WordDetailScreen({
    super.key,
    required this.word,
    this.wordList,
    this.currentIndex,
  });

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  final WordService _wordService = WordService.instance;
  final GeminiService _geminiService = GeminiService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;
  final StudyRecordService _studyRecordService = StudyRecordService.instance;

  late PageController _pageController;
  late int _currentIndex;
  late List<Word> _wordList;
  late Word _currentWord;

  late bool _isFavorite;
  bool _isGeneratingExamples = false;
  List<WordExample>? _generatedExamples;
  List<WordExample> _databaseExamples = [];
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
    _wordList = widget.wordList ?? [widget.word];
    _currentIndex = widget.currentIndex ?? 0;
    _currentWord = _wordList[_currentIndex];
    _pageController = PageController(initialPage: _currentIndex);
    _isFavorite = _wordService.isFavorite(_currentWord.id);
    _loadDatabaseExamples();
    _loadStudyStats();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _currentWord = _wordList[index];
      _isFavorite = _wordService.isFavorite(_currentWord.id);
      _generatedExamples = null;
      _databaseExamples = [];
      _studyStats = null;
      _isLoadingStats = true;
      _showStrokeOrder = false;
    });
    _loadDatabaseExamples();
    _loadStudyStats();
  }

  Future<void> _loadDatabaseExamples() async {
    setState(() {
      _isLoadingExamples = true;
    });

    try {
      // Load examples from database using word id
      final examples = await _supabaseService.getWordExamples(_currentWord.id);
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
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await _supabaseService.getStudyStats(
        type: StudyType.word,
        targetId: _currentWord.id,
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
    if (_isRecordingStudy) return;

    setState(() {
      _isRecordingStudy = true;
    });

    try {
      await _studyRecordService.addRecord(
        type: 'word',
        targetId: _currentWord.id,
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
    setState(() {
      _wordService.toggleFavorite(_currentWord.id);
      _isFavorite = !_isFavorite;
    });
  }

  Future<void> _generateExamples() async {
    if (_isGeneratingExamples) return;

    setState(() {
      _isGeneratingExamples = true;
    });

    try {
      // Create prompt for Gemini
      final prompt =
          '''
다음 일본어 단어에 대한 예문을 3개 만들어주세요. 각 예문은 일상생활에서 자연스럽게 사용할 수 있는 문장이어야 합니다.

단어: ${widget.word.word}
읽기: ${widget.word.reading}
의미: ${widget.word.meaningsText}

다음 형식으로 응답해주세요:
[예문1]
일본어: (일본어 문장)
히라가나: (히라가나로 표기)
한국어: (한국어 번역)

[예문2]
일본어: (일본어 문장)
히라가나: (히라가나로 표기)
한국어: (한국어 번역)

[예문3]
일본어: (일본어 문장)
히라가나: (히라가나로 표기)
한국어: (한국어 번역)
''';

      // Use flutter_gemini directly
      final gemini = Gemini.instance;
      final response = await gemini.prompt(parts: [Part.text(prompt)]);

      if (response?.output != null) {
        // Parse the response to extract examples
        final examples = _parseExamples(response!.output!);
        setState(() {
          _generatedExamples = examples;
        });
      }
    } catch (e) {
      debugPrint('Error generating examples: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예문 생성 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGeneratingExamples = false;
      });
    }
  }

  List<WordExample> _parseExamples(String response) {
    final examples = <WordExample>[];
    final lines = response.split('\n');

    String? japanese;
    String? furigana;
    String? korean;

    for (final line in lines) {
      if (line.startsWith('일본어:')) {
        japanese = line.substring(5).trim();
      } else if (line.startsWith('히라가나:') || line.startsWith('후리가나:')) {
        furigana = line.substring(line.indexOf(':') + 1).trim();
      } else if (line.startsWith('한국어:')) {
        korean = line.substring(5).trim();

        // If we have all three components, create an example
        if (japanese != null && furigana != null) {
          examples.add(
            WordExample(
              japanese: japanese,
              furigana: furigana,
              korean: korean,
              source: 'AI Generated',
              createdAt: DateTime.now(),
            ),
          );

          // Reset for next example
          japanese = null;
          furigana = null;
          korean = null;
        }
      }
    }

    return examples;
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

  Widget _buildWordPage(Word word, FThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Word Information Card
          FCard(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Centered word section
                      Center(
                        child: Column(
                          children: [
                            // Reading (furigana)
                            if (word.reading.isNotEmpty &&
                                word.reading != word.word)
                              Text(
                                word.reading,
                                style: theme.typography.base.copyWith(
                                  color: theme.colors.mutedForeground,
                                  fontSize: 18,
                                ),
                              ),

                            // Main word
                            Text(
                              word.word,
                              style: _showStrokeOrder
                                  ? TextStyle(
                                      fontFamily: 'KanjiStrokeOrders',
                                      fontSize: 90, // 100pt 이상 권장
                                      fontWeight: FontWeight.normal,
                                      color: theme.colors.foreground,
                                      height: 1.2,
                                    )
                                  : GoogleFonts.notoSerifJp(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colors.foreground,
                                      height: 1.2,
                                    ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Meanings by part of speech - Center aligned
                      ...word.meanings.map((meaning) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Part of speech badge - 얇은 알약 형태
                                if (meaning.partOfSpeech.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      meaning.partOfSpeech,
                                      style: theme.typography.sm.copyWith(
                                        color: theme.colors.primary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                // Meaning text
                                Flexible(
                                  child: Text(
                                    meaning.meaning,
                                    style: theme.typography.base.copyWith(
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),

                      // JLPT Level - Center aligned
                      Center(
                        child: JlptBadge(
                          level: word.jlptLevel,
                          showPrefix: true,
                        ),
                      ),
                    ],
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

          const SizedBox(height: 24),

          // Examples Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '예문',
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

          // Display examples
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
              ..._databaseExamples.map((example) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ExampleCard(
                    japanese: example.japanese,
                    furigana: example.furigana,
                    korean: example.korean,
                    explanation: example.explanation,
                    sourceLabel: _getSourceLabel(example.source),
                    japaneseFontSize: 20,
                    rubyFontSize: 11,
                  ),
                );
              }),
            ],
            // Then display AI generated examples
            if (_generatedExamples != null) ...[
              ..._generatedExamples!.map((example) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ExampleCard(
                    japanese: example.japanese,
                    furigana: example.furigana,
                    korean: example.korean,
                    explanation: example.explanation,
                    sourceLabel: 'AI 생성',
                    japaneseFontSize: 20,
                    rubyFontSize: 11,
                  ),
                );
              }),
            ],
          ] else ...[
            FCard(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        PhosphorIconsRegular.sparkle,
                        size: 48,
                        color: theme.colors.mutedForeground,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'AI로 예문을 생성해보세요',
                        style: theme.typography.base.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
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

    // If no wordList provided, show single word without swipe
    if (_wordList.length == 1) {
      return FScaffold(
        header: FHeader.nested(
          title: Text(
            '단어 상세',
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
                child: _buildWordPage(_currentWord, theme),
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
          '단어 상세 (${_currentIndex + 1}/${_wordList.length})',
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
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _wordList.length,
                itemBuilder: (context, index) {
                  return _buildWordPage(_wordList[index], theme);
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
