import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/word_model.dart';
import '../services/favorite_service.dart';
import 'jlpt_badge.dart';

/// 단어 플래시카드 컨텐츠 위젯
/// 앞면: 단어(한자) + JLPT 배지 + 획순 버튼
/// 뒷면: 단어 + 후리가나 + 뜻 + 획순 버튼
class WordFlashcardContent extends StatefulWidget {
  final Word word;
  final bool isBack; // true: 뒷면, false: 앞면

  const WordFlashcardContent({
    super.key,
    required this.word,
    required this.isBack,
  });

  @override
  State<WordFlashcardContent> createState() => _WordFlashcardContentState();
}

class _WordFlashcardContentState extends State<WordFlashcardContent> {
  bool _showStrokeOrder = false;

  Color _getJlptColor(int level) {
    switch (level) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStrokeOrderToggle(FThemeData theme) {
    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () => setState(() => _showStrokeOrder = !_showStrokeOrder),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colors.muted,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colors.border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showStrokeOrder
                      ? PhosphorIconsRegular.eyeSlash
                      : PhosphorIconsRegular.eye,
                  size: 16,
                  color: theme.colors.foreground,
                ),
                const SizedBox(width: 4),
                Text(
                  _showStrokeOrder ? '획순 숨기기' : '획순 보기',
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteToggle(FThemeData theme) {
    final isFavorite =
        FavoriteService.instance.isFavorite('word', widget.word.id);

    return Positioned(
      top: 16,
      right: 16,
      child: GestureDetector(
        onTap: () async {
          await FavoriteService.instance.toggleFavorite(
            type: 'word',
            targetId: widget.word.id,
          );
          setState(() {});
        },
        child: Icon(
          isFavorite ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
          size: 28,
          color: isFavorite ? Colors.amber : theme.colors.mutedForeground,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return widget.isBack ? _buildBack(theme) : _buildFront(theme);
  }

  Widget _buildFront(FThemeData theme) {
    final displayWord = widget.word.word
        .replaceAll(RegExp(r'[·•・∙/,;、]'), '\n')
        .trim();

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: theme.colors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colors.border, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40), // 획순 버튼 공간
              Text(
                displayWord,
                textAlign: TextAlign.center,
                style: _showStrokeOrder
                    ? TextStyle(
                        fontFamily: 'KanjiStrokeOrders',
                        fontSize: 90,
                        fontWeight: FontWeight.normal,
                        color: theme.colors.foreground,
                        height: 1.3,
                      )
                    : GoogleFonts.notoSerifJp(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: theme.colors.foreground,
                        height: 1.3,
                      ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getJlptColor(
                    widget.word.jlptLevel,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'JLPT N${widget.word.jlptLevel}',
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getJlptColor(widget.word.jlptLevel),
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildStrokeOrderToggle(theme),
        _buildFavoriteToggle(theme),
      ],
    );
  }

  Widget _buildBack(FThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
              decoration: BoxDecoration(
                color: theme.colors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colors.border, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32), // 획순 버튼 공간
                      // Reading (furigana)
                      if (widget.word.reading.isNotEmpty &&
                          widget.word.reading != widget.word.word)
                        Text(
                          widget.word.reading,
                          style: theme.typography.base.copyWith(
                            color: theme.colors.mutedForeground,
                            fontSize: 18,
                          ),
                        ),

                      // Main word
                      Text(
                        widget.word.word,
                        textAlign: TextAlign.center,
                        style: _showStrokeOrder
                            ? TextStyle(
                                fontFamily: 'KanjiStrokeOrders',
                                fontSize: 90,
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
                      const SizedBox(height: 24),

                      // Meanings by part of speech - Center aligned
                      ...widget.word.meanings.map((meaning) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Part of speech badge
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

                      // JLPT Level
                      JlptBadge(level: widget.word.jlptLevel, showPrefix: true),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            _buildStrokeOrderToggle(theme),
            _buildFavoriteToggle(theme),
          ],
        );
      },
    );
  }
}
