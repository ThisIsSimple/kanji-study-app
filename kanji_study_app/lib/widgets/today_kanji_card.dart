import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/kanji_model.dart';

class TodayKanjiCard extends StatelessWidget {
  final Kanji kanji;

  const TodayKanjiCard({
    super.key,
    required this.kanji,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '오늘의 한자',
                style: theme.typography.lg.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                kanji.character,
                style: GoogleFonts.notoSerifJp(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: theme.colors.foreground,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                kanji.meanings.join(', '),
                style: theme.typography.lg.copyWith(
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'JLPT N${kanji.jlpt} | ${kanji.grade <= 6 ? "${kanji.grade}학년" : "중학교+"}',
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
