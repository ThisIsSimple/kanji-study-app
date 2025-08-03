import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../models/kanji_model.dart';
import '../services/kanji_service.dart';

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
  bool _showDetails = false;
  bool _isCompleted = false;

  void _toggleDetails() {
    setState(() {
      _showDetails = !_showDetails;
    });
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
        title: const Text('한자 학습'),
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
                  children: [
                    Text(
                      widget.kanji.character,
                      style: theme.typography.xl.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 72,
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
                        children: [
                          Text(
                            '의미',
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.kanji.meanings.join(', '),
                            style: theme.typography.lg.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Show/Hide Details Button
                    FButton(
                      onPress: _toggleDetails,
                      style: FButtonStyle.outline(),
                      child: Text(_showDetails ? '상세 정보 숨기기' : '상세 정보 보기'),
                    ),
                  ],
                ),
              ),
            ),
            
            // Details Section
            if (_showDetails) ...[
              const SizedBox(height: 16),
              
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
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.kanji.readings.on.isNotEmpty) ...[
                            Text(
                              '음독 (音読み)',
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
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
                              '훈독 (訓読み)',
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
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
              
              // Info Card
              FCard(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '학년',
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.kanji.grade <= 6 
                              ? '${widget.kanji.grade}학년'
                              : '중학교+',
                            style: theme.typography.lg.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'JLPT',
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'N${widget.kanji.jlpt}',
                            style: theme.typography.lg.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '빈도',
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '#${widget.kanji.frequency}',
                            style: theme.typography.lg.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                      Text(
                        '예시',
                        style: theme.typography.lg.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                              example,
                              style: theme.typography.base,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Complete Study Button
            FButton(
              onPress: _isCompleted ? null : _markAsStudied,
              child: Text(_isCompleted ? '학습 완료됨' : '학습 완료'),
            ),
          ],
        ),
      ),
    );
  }
}