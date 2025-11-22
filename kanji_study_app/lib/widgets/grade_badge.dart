import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// 학년(Grade)을 표시하는 공통 뱃지 위젯
class GradeBadge extends StatelessWidget {
  final int grade;
  final double? fontSize;

  const GradeBadge({
    super.key,
    required this.grade,
    this.fontSize,
  });

  /// Grade별 색상 반환
  static Color getGradeColor(int grade) {
    switch (grade) {
      case 1:
        return Colors.purple[600]!;
      case 2:
        return Colors.indigo[600]!;
      case 3:
        return Colors.blue[600]!;
      case 4:
        return Colors.teal[600]!;
      case 5:
        return Colors.green[600]!;
      case 6:
        return Colors.lime[600]!;
      case 7:
      default:
        return Colors.orange[600]!;
    }
  }

  /// Grade 텍스트 반환
  static String getGradeText(int grade) {
    if (grade <= 6) {
      return '${grade}학년';
    } else {
      return '중학교+';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final color = getGradeColor(grade);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        getGradeText(grade),
        style: theme.typography.sm.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: fontSize ?? 11,
        ),
      ),
    );
  }
}

