import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Toast type enum for styling
enum AppToastType {
  /// Info toast - black background with white text (default)
  info,

  /// Error toast - red (destructive) background with white text
  error,
}

/// Shows a custom styled toast notification
///
/// [context] must be from under FScaffold (use GlobalKey context)
/// [message] the text to display
/// [type] defaults to AppToastType.info (black background)
/// [icon] optional custom icon, defaults based on type
/// [duration] how long to show the toast
void showAppToast(
  BuildContext context, {
  required String message,
  AppToastType type = AppToastType.info,
  IconData? icon,
  Duration duration = const Duration(seconds: 2),
}) {
  final isError = type == AppToastType.error;
  final backgroundColor = isError
      ? FTheme.of(context).colors.destructive
      : Colors.black;
  final defaultIcon = isError
      ? PhosphorIconsRegular.warningCircle
      : PhosphorIconsRegular.checkCircle;

  showRawFToast(
    context: context,
    duration: duration,
    alignment: FToastAlignment.topLeft, // Will be centered via builder
    builder: (context, entry) {
      final topPadding = MediaQuery.of(context).padding.top + 20;
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon ?? defaultIcon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
