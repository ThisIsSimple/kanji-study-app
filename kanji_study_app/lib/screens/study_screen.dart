import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/kanji_model.dart';
import '../models/kanji_example.dart';
import '../services/kanji_service.dart';
import '../services/gemini_service.dart';
import '../utils/korean_formatter.dart';

class StudyScreen extends StatefulWidget {
  final Kanji kanji;
  
  const StudyScreen({
    super.key,
    required this.kanji,
  });

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final KanjiService _kanjiService = KanjiService.instance;
  final GeminiService _geminiService = GeminiService.instance;
  bool _isCompleted = false;
  bool _isGeneratingExamples = false;
  List<KanjiExample>? _generatedExamples;

  Future<void> _generateExamples() async {
    if (_isGeneratingExamples) return;
    
    setState(() {
      _isGeneratingExamples = true;
    });
    
    try {
      final examples = await _geminiService.generateExamples(widget.kanji);
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

  void _markAsStudied() async {
    await _kanjiService.markAsStudied(widget.kanji.character);
    setState(() {
      _isCompleted = true;
    });
    
    // Show completion dialog
    if (mounted) {
      await showAdaptiveDialog(
        context: context,
        builder: (context) => FDialog(
          title: const Text('학습 완료!'),
          body: Text('${widget.kanji.character} 한자를 학습했습니다.'),
          actions: [
            FButton(
              onPress: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    
    return FScaffold(
      header: FHeader.nested(
        title: Text(
          '한자 학습',
          style: TextStyle(fontFamily: 'SUITE'),
        ),
        prefixes: [
          FHeaderAction.back(
            onPress: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main Kanji Card
            FCard(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.kanji.character,
                      style: GoogleFonts.notoSerifJp(
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
                        color: theme.colors.secondary.withValues(alpha: 0.1),
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
                            widget.kanji.meanings.join(', '),
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
                          if (hasKoreanReadings(widget.kanji.koreanKunReadings, widget.kanji.koreanOnReadings)) ...[
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
                                formatKoreanReadings(widget.kanji.koreanKunReadings, widget.kanji.koreanOnReadings),
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
                          if (widget.kanji.readings.on.isNotEmpty) ...[
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
                              children: widget.kanji.readings.on.map((reading) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colors.primary.withValues(alpha: 0.1),
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
                          if (widget.kanji.readings.on.isNotEmpty && 
                              widget.kanji.readings.kun.isNotEmpty)
                            const SizedBox(height: 16),
                          if (widget.kanji.readings.kun.isNotEmpty) ...[
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
                              children: widget.kanji.readings.kun.map((reading) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colors.secondary.withValues(alpha: 0.1),
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
              const SizedBox(height: 16),
              
              
              // Examples Card
              FCard(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                  : Text(
                                      'AI 예문 생성',
                                      style: TextStyle(fontFamily: 'SUITE'),
                                    ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Display generated examples if available, otherwise show default examples
                      if (_generatedExamples != null) ...[
                        ..._generatedExamples!.map((example) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colors.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colors.primary.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    example.japanese,
                                    style: GoogleFonts.notoSerifJp(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: theme.colors.foreground,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    example.hiragana,
                                    style: theme.typography.sm.copyWith(
                                      color: theme.colors.mutedForeground,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    example.korean,
                                    style: theme.typography.base.copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'SUITE',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ] else if (widget.kanji.examples.isNotEmpty) ...[
                        ...widget.kanji.examples.map((example) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colors.secondary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colors.border,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                example.toString(),
                                style: theme.typography.base,
                              ),
                            ),
                          );
                        }),
                      ] else ...[
                        Text(
                          '예문이 없습니다.',
                          style: theme.typography.base.copyWith(
                            color: theme.colors.mutedForeground,
                            fontFamily: 'SUITE',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),
            
            // Complete Study Button
            FButton(
              onPress: _isCompleted ? null : _markAsStudied,
              child: Text(
                _isCompleted ? '학습 완료됨' : '학습 완료',
                style: TextStyle(fontFamily: 'SUITE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}