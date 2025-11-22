import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// JLPT 레벨을 표시하는 공통 뱃지 위젯
class JlptBadge extends StatelessWidget {
  final int level;
  final bool showPrefix; // 'JLPT' 접두사 표시 여부
  final double? fontSize;

  const JlptBadge({
    super.key,
    required this.level,
    this.showPrefix = false,
    this.fontSize,
  });

  /// JLPT 레벨별 색상 반환
  static Color getJlptColor(int level) {
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

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final color = getJlptColor(level);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showPrefix ? 12 : 8,
        vertical: showPrefix ? 4 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(showPrefix ? 16 : 12),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        showPrefix ? 'JLPT N$level' : 'N$level',
        style: theme.typography.sm.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: fontSize ?? (showPrefix ? 12.0 : 11.0),
        ),
      ),
    );
  }
}

