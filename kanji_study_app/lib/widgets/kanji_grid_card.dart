import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konnakanji/services/kanji_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/kanji_model.dart';
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
        child: Stack(
          alignment: Alignment.center,

          children: [
            // Top bar with check and favorite
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(AppSpacing.unit * 1.5),
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
            ),
            // Main content
            Container(
              padding: EdgeInsets.all(AppSpacing.unit),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Kanji Character
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    child: Text(
                      kanji.character,
                      style: GoogleFonts.notoSerifJp(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: theme.colors.foreground,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

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
                        fontSize: 10,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
