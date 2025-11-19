import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../constants/app_spacing.dart';

/// Reusable success rate indicator widget
/// Displays success rate percentage with icon and styling
class SuccessRateIndicator extends StatelessWidget {
  final double successRate;

  const SuccessRateIndicator({
    super.key,
    required this.successRate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.chartLine,
            size: 20,
            color: theme.colors.secondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '성공률: ${(successRate * 100).toStringAsFixed(1)}%',
            style: theme.typography.base.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
