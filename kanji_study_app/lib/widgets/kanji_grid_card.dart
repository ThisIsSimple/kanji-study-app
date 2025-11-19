import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/kanji_model.dart';
import '../services/kanji_service.dart';
import '../utils/korean_formatter.dart';
import '../constants/app_spacing.dart';

class KanjiGridCard extends StatelessWidget {
  final Kanji kanji;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const KanjiGridCard({
    super.key,
    required this.kanji,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final kanjiService = KanjiService.instance;
    final progress = kanjiService.getProgress(kanji.character);
    final isFavorite = kanjiService.isFavorite(kanji.character);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colors.border, width: 1),
        ),
        child: Column(
          children: [
            // Top bar with check and favorite
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Check mark
                  if (progress != null && progress.mastered)
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        PhosphorIconsFill.check,
                        size: 14,
                        color: theme.colors.background,
                      ),
                    )
                  else
                    const SizedBox(width: 20),

                  // Favorite button
                  GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Icon(
                      isFavorite
                          ? PhosphorIconsFill.star
                          : PhosphorIconsRegular.star,
                      size: 20,
                      color: isFavorite
                          ? Colors.amber
                          : theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    // Kanji Character
                    Text(
                      kanji.character,
                      style: GoogleFonts.notoSerifJp(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: theme.colors.foreground,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Korean readings
                    if (hasKoreanReadings(
                      kanji.koreanKunReadings,
                      kanji.koreanOnReadings,
                    ))
                      Text(
                        formatKoreanReadings(
                          kanji.koreanKunReadings,
                          kanji.koreanOnReadings,
                        ),
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
