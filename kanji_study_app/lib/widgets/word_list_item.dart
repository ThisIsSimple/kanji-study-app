import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word_model.dart';
import '../constants/app_spacing.dart';

class WordListItem extends StatelessWidget {
  final Word word;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const WordListItem({
    super.key,
    required this.word,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return FCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              child: // Favorite button
              IconButton(
                icon: Icon(
                  isFavorite
                      ? PhosphorIconsFill.star
                      : PhosphorIconsRegular.star,
                  size: 20,
                  color: isFavorite
                      ? Colors.amber
                      : theme.colors.mutedForeground,
                ),
                onPressed: onFavoriteToggle,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // JLPT Level badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getJlptColor(
                              word.jlptLevel,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getJlptColor(
                                word.jlptLevel,
                              ).withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'N${word.jlptLevel}',
                            style: theme.typography.sm.copyWith(
                              color: _getJlptColor(word.jlptLevel),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        // Word (main text)
                        Text(
                          word.word,
                          style: GoogleFonts.notoSerifJp(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.colors.foreground,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Meanings
                        Text(
                          word.meaningsText,
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.foreground.withValues(
                              alpha: 0.8,
                            ),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
