import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/kanji_model.dart';
import '../utils/korean_formatter.dart';
import 'jlpt_badge.dart';
import 'grade_badge.dart';

/// 한자 상세 정보 카드 위젯
///
/// 바텀시트나 상세 화면에서 한자의 핵심 정보를 표시합니다.
/// 예시 문장은 포함하지 않습니다.
class KanjiInfoCard extends StatefulWidget {
  final Kanji kanji;
  final bool showStrokeOrderToggle;

  const KanjiInfoCard({
    super.key,
    required this.kanji,
    this.showStrokeOrderToggle = true,
  });

  /// 바텀시트로 한자 정보 카드를 표시합니다.
  static void showKanjiInfoSheet({
    required BuildContext context,
    required Kanji kanji,
  }) {
    final theme = FTheme.of(context);

    showFSheet(
      context: context,
      side: FLayout.btt,
      mainAxisMaxRatio: 0.85,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16 + MediaQuery.of(context).padding.bottom,
                ),
                child: KanjiInfoCard(kanji: kanji),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  State<KanjiInfoCard> createState() => _KanjiInfoCardState();
}

class _KanjiInfoCardState extends State<KanjiInfoCard> {
  bool _showStrokeOrder = false;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final kanji = widget.kanji;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Kanji Card
        FCard(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        kanji.character,
                        style: _showStrokeOrder
                            ? const TextStyle(
                                fontFamily: 'KanjiStrokeOrders',
                                fontSize: 100,
                                fontWeight: FontWeight.normal,
                              )
                            : GoogleFonts.notoSerifJp(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: theme.colors.foreground,
                              ),
                      ),
                      const SizedBox(height: 24),

                      // Korean meanings
                      Text(
                        formatKoreanReadings(
                          kanji.koreanKunReadings,
                          kanji.koreanOnReadings,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // JLPT and Grade badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          if (kanji.grade > 0) GradeBadge(grade: kanji.grade),
                          if (kanji.jlpt > 0)
                            JlptBadge(level: kanji.jlpt, showPrefix: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Stroke Order Toggle Button
              if (widget.showStrokeOrderToggle)
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
        const SizedBox(height: 16),

        // Details Section
        FCard(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 부수 (radical)
                if (kanji.radical != null && kanji.radical!.isNotEmpty) ...[
                  _buildInfoRow(
                    theme: theme,
                    label: '부수',
                    children: [_buildPill(theme: theme, text: kanji.radical!)],
                  ),
                  const SizedBox(height: 16),
                ],

                // 훈독 (kun readings)
                if (kanji.readings.kun.isNotEmpty) ...[
                  _buildInfoRow(
                    theme: theme,
                    label: '훈독',
                    children: kanji.readings.kun
                        .map((r) => _buildPill(theme: theme, text: r))
                        .toList(),
                  ),
                ],

                if (kanji.readings.kun.isNotEmpty &&
                    kanji.readings.on.isNotEmpty)
                  const SizedBox(height: 16),

                // 음독 (on readings)
                if (kanji.readings.on.isNotEmpty) ...[
                  _buildInfoRow(
                    theme: theme,
                    label: '음독',
                    children: kanji.readings.on
                        .map((r) => _buildPill(theme: theme, text: r))
                        .toList(),
                  ),
                ],

                // 한자 해설 (commentary)
                if (kanji.commentary != null &&
                    kanji.commentary!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(theme: theme, label: '한자 해설', children: []),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      kanji.commentary!,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.foreground,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required FThemeData theme,
    required String label,
    required List<Widget> children,
  }) {
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          label,
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildPill({required FThemeData theme, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: theme.typography.base),
    );
  }
}
