import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/flashcard_item.dart';
import '../models/flashcard_session_model.dart';
import '../services/flashcard_service.dart';
import '../services/word_service.dart';
import '../services/kanji_service.dart';
import '../widgets/word_flashcard_content.dart';
import '../widgets/kanji_flashcard_content.dart';

class FlashcardScreen extends StatefulWidget {
  final List<FlashcardItem> items;
  final FlashcardSession? initialSession;

  const FlashcardScreen({super.key, required this.items, this.initialSession});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  final FlashcardService _flashcardService = FlashcardService.instance;
  final WordService _wordService = WordService.instance;
  final KanjiService _kanjiService = KanjiService.instance;

  late FlashcardSession _session;
  bool _isFlipped = false;
  bool _isLoading = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _session =
        widget.initialSession ??
        FlashcardSession(
          itemType: widget.items.first.itemType,
          itemIds: widget.items.map((i) => i.id).toList(),
          startTime: DateTime.now(),
        );

    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    // Initialize session if new
    if (widget.initialSession == null) {
      _initializeSession();
    }
  }

  Future<void> _initializeSession() async {
    setState(() => _isLoading = true);
    try {
      _session = await _flashcardService.createSession(
        widget.items.first.itemType,
        widget.items.map((i) => i.id).toList(),
      );
    } catch (e) {
      debugPrint('Error initializing session: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    setState(() {
      _isFlipped = !_isFlipped;
    });

    if (_isFlipped) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  Future<void> _recordAnswer(bool isCorrect) async {
    if (_session.currentItemId == null) return;

    setState(() => _isLoading = true);

    try {
      final updatedSession = await _flashcardService.recordResult(
        itemId: _session.currentItemId!,
        isCorrect: isCorrect,
        itemType: _session.itemType, // itemType 파라미터 추가
      );

      if (mounted) {
        setState(() {
          _session = updatedSession;
          _isFlipped = false;
          _isLoading = false;
        });
        _flipController.reset();

        // Show completion screen if done
        if (_session.isCompleted) {
          _showCompletionScreen();
        }
      }
    } catch (e) {
      debugPrint('Error recording answer: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCompletionScreen() {
    final theme = FTheme.of(context);
    final stats = _flashcardService.getSessionStats(_session);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              PhosphorIconsFill.checkCircle,
              color: theme.colors.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              '학습 완료!',
              style: theme.typography.xl.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('총 학습 카드', '${stats['total']}개', theme),
            const SizedBox(height: 8),
            _buildStatRow('맞힌 개수', '${stats['correct']}개', theme, Colors.green),
            const SizedBox(height: 8),
            _buildStatRow('틀린 개수', '${stats['incorrect']}개', theme, Colors.red),
            const SizedBox(height: 8),
            _buildStatRow(
              '정확도',
              '${stats['accuracy'].toStringAsFixed(1)}%',
              theme,
              theme.colors.primary,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _flashcardService.clearSession(_session.itemType);
              if (!mounted) return;
              navigator.pop(); // Close dialog
              navigator.pop(); // Close flashcard screen
            },
            child: Text(
              '완료',
              style: TextStyle(
                color: theme.colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    FThemeData theme, [
    Color? valueColor,
  ]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.typography.base.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
        Text(
          value,
          style: theme.typography.base.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? theme.colors.foreground,
          ),
        ),
      ],
    );
  }

  FlashcardItem? _getCurrentItem() {
    if (_session.currentItemId == null) return null;
    try {
      return widget.items.firstWhere(
        (item) => item.id == _session.currentItemId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final currentItem = _getCurrentItem();

    if (_session.isCompleted) {
      return FScaffold(
        header: FHeader(title: const Text('플래시카드 학습')),
        child: Center(
          child: Text(
            '모든 카드를 학습했습니다!',
            style: theme.typography.lg.copyWith(),
          ),
        ),
      );
    }

    if (currentItem == null) {
      return FScaffold(
        header: FHeader(title: const Text('플래시카드 학습')),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return FScaffold(
      header: FHeader(
        title: Row(
          children: [
            Text(
              '${_session.currentIndex + 1}',
              style: theme.typography.lg.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' / ${_session.itemIds.length}',
              style: theme.typography.lg.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
        suffixes: [
          IconButton(
            icon: Icon(PhosphorIconsRegular.x),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    '학습 종료',
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    '플래시카드 학습을 종료하시겠습니까?\n진행 상태가 저장됩니다.',
                    style: theme.typography.base.copyWith(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('취소', style: TextStyle()),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(context).pop(); // Close flashcard screen
                      },
                      child: Text(
                        '종료',
                        style: TextStyle(
                          color: theme.colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: _session.progressPercentage / 100,
                  backgroundColor: theme.colors.muted,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colors.primary,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        // Flashcard
                        Expanded(
                          child: GestureDetector(
                            onTap: _flipCard,
                            child: AnimatedBuilder(
                              animation: _flipAnimation,
                              builder: (context, child) {
                                final angle = _flipAnimation.value * math.pi;
                                final transform = Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(angle);

                                return Transform(
                                  transform: transform,
                                  alignment: Alignment.center,
                                  child: angle >= math.pi / 2
                                      ? Transform(
                                          transform: Matrix4.identity()
                                            ..rotateY(math.pi),
                                          alignment: Alignment.center,
                                          child: _buildCardBack(
                                            currentItem,
                                            theme,
                                          ),
                                        )
                                      : _buildCardFront(currentItem, theme),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Tap to flip hint
                        if (!_isFlipped)
                          Text(
                            '카드를 탭하여 뒤집기',
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        const SizedBox(height: 20),
                        // Answer buttons
                        if (_isFlipped)
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _recordAnswer(false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: theme.colors.border,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          PhosphorIconsRegular.x,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '모르겠어요',
                                          style: theme.typography.base.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FButton(
                                  onPress: () => _recordAnswer(true),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          PhosphorIconsRegular.check,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '알았어요',
                                          style: theme.typography.base.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCardFront(FlashcardItem item, FThemeData theme) {
    // itemType에 따라 적절한 카드 컴포넌트 사용
    if (item.itemType == 'word') {
      final word = _wordService.getWordById(item.id);
      if (word != null) {
        return WordFlashcardContent(word: word, isBack: false);
      }
    } else if (item.itemType == 'kanji') {
      final kanji = _kanjiService.getKanjiById(item.id);
      if (kanji != null) {
        return KanjiFlashcardContent(kanji: kanji, isBack: false);
      }
    }

    // Fallback: 기본 카드 표시
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colors.border, width: 2),
      ),
      child: Center(
        child: Text(
          '카드를 불러올 수 없습니다',
          style: theme.typography.base.copyWith(),
        ),
      ),
    );
  }

  Widget _buildCardBack(FlashcardItem item, FThemeData theme) {
    // itemType에 따라 적절한 카드 컴포넌트 사용
    if (item.itemType == 'word') {
      final word = _wordService.getWordById(item.id);
      if (word != null) {
        return WordFlashcardContent(word: word, isBack: true);
      }
    } else if (item.itemType == 'kanji') {
      final kanji = _kanjiService.getKanjiById(item.id);
      if (kanji != null) {
        return KanjiFlashcardContent(kanji: kanji, isBack: true);
      }
    }

    // Fallback: 기본 카드 표시
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colors.border, width: 2),
      ),
      child: Center(
        child: Text(
          '카드를 불러올 수 없습니다',
          style: theme.typography.base.copyWith(),
        ),
      ),
    );
  }
}
