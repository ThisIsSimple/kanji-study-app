import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import '../models/word_model.dart';
import '../models/word_example_model.dart';
import '../services/word_service.dart';
import '../services/gemini_service.dart';
import '../services/supabase_service.dart';
import '../widgets/furigana_text.dart';

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
  
  late PageController _pageController;
  late int _currentIndex;
  late List<Word> _wordList;
  late Word _currentWord;
  
  late bool _isFavorite;
  bool _isGeneratingExamples = false;
  List<WordExample>? _generatedExamples;
  List<WordExample> _databaseExamples = [];
  bool _isLoadingExamples = true;

  @override
  void initState() {
    super.initState();
    _wordList = widget.wordList ?? [widget.word];
    _currentIndex = widget.currentIndex ?? 0;
    _currentWord = _wordList[_currentIndex];
    _pageController = PageController(initialPage: _currentIndex);
    _isFavorite = _wordService.isFavorite(_currentWord.id);
    _loadDatabaseExamples();
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
    });
    _loadDatabaseExamples();
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
      final prompt = '''
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
      final response = await gemini.prompt(parts: [
        Part.text(prompt),
      ]);
      
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
        if (japanese != null && furigana != null && korean != null) {
          examples.add(WordExample(
            japanese: japanese,
            furigana: furigana,
            korean: korean,
            source: 'AI Generated',
            createdAt: DateTime.now(),
          ));
          
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Centered word section
                    Center(
                      child: Column(
                        children: [
                          // Reading (furigana)
                          if (word.reading.isNotEmpty && word.reading != word.word)
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
                            style: GoogleFonts.notoSerifJp(
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
                    
                    // JLPT Level
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getJlptColor(word.jlptLevel).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getJlptColor(word.jlptLevel).withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'JLPT N${word.jlptLevel}',
                            style: theme.typography.sm.copyWith(
                              color: _getJlptColor(word.jlptLevel),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Meanings by part of speech
                    Text(
                      '의미',
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SUITE',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...word.meanings.map((meaning) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Part of speech badge
                            if (meaning.partOfSpeech.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: theme.colors.secondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  meaning.partOfSpeech,
                                  style: theme.typography.sm.copyWith(
                                    color: theme.colors.secondary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            // Meaning text
                            Expanded(
                              child: Text(
                                meaning.meaning,
                                style: theme.typography.base.copyWith(
                                  fontFamily: 'SUITE',
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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
                  '예문',
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
                        : Text(
                            'AI 예문 생성',
                            style: TextStyle(fontFamily: 'SUITE'),
                          ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Display examples
            if (_isLoadingExamples) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ] else if (_databaseExamples.isNotEmpty || _generatedExamples != null) ...[
              // Display database examples first
              if (_databaseExamples.isNotEmpty) ...[
                ..._databaseExamples.map((example) {
                  final sourceLabel = _getSourceLabel(example.source);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
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
                            FuriganaText(
                              text: example.furigana.contains('[') ? example.furigana : example.japanese,
                              style: GoogleFonts.notoSerifJp(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: theme.colors.foreground,
                                height: 1.5,  // 행간 조절
                              ),
                              rubyStyle: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                                fontSize: 11,
                              ),
                              spacing: -1.0,  // 한자와 후리가나 사이 간격을 더 좁게
                            ),
                            const SizedBox(height: 12),
                            Text(
                              example.korean,
                              style: theme.typography.base.copyWith(
                                fontWeight: FontWeight.w500,
                                fontFamily: 'SUITE',
                                fontSize: 16,
                              ),
                            ),
                            // Explanation if exists
                            if (example.explanation != null && example.explanation!.isNotEmpty) ...[
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
                    ),
                  );
                }),
              ],
              // Then display AI generated examples
              if (_generatedExamples != null) ...[
                ..._generatedExamples!.map((example) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // AI Generated label
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colors.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'AI 생성',
                                style: theme.typography.xs.copyWith(
                                  color: theme.colors.secondary,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'SUITE',
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FuriganaText(
                              text: example.furigana.contains('[') ? example.furigana : example.japanese,
                              style: GoogleFonts.notoSerifJp(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: theme.colors.foreground,
                                height: 1.5,  // 행간 조절
                              ),
                              rubyStyle: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                                fontSize: 11,
                              ),
                              spacing: -1.0,  // 한자와 후리가나 사이 간격을 더 좁게
                            ),
                            const SizedBox(height: 12),
                            Text(
                              example.korean,
                              style: theme.typography.base.copyWith(
                                fontWeight: FontWeight.w500,
                                fontFamily: 'SUITE',
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                            fontFamily: 'SUITE',
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
            style: TextStyle(fontFamily: 'SUITE'),
          ),
          prefixes: [
            FHeaderAction.back(
              onPress: () => Navigator.of(context).pop(),
            ),
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
        child: _buildWordPage(_currentWord, theme),
      );
    }
    
    // Show with PageView for swipe navigation
    return FScaffold(
      header: FHeader.nested(
        title: Text(
          '단어 상세 (${_currentIndex + 1}/${_wordList.length})',
          style: TextStyle(fontFamily: 'SUITE'),
        ),
        prefixes: [
          FHeaderAction.back(
            onPress: () => Navigator.of(context).pop(),
          ),
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
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: _wordList.length,
        itemBuilder: (context, index) {
          return _buildWordPage(_wordList[index], theme);
        },
      ),
    );
  }

  Color _getJlptColor(int level) {
    switch (level) {
      case 1:
        return Colors.red[700]!;
      case 2:
        return Colors.orange[700]!;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.green[600]!;
      case 5:
        return Colors.blue[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}