import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class AuthProviderButton extends StatelessWidget {
  const AuthProviderButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.outline = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: foregroundColor),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w500),
        ),
      ],
    );

    if (outline) {
      return FButton(
        onPress: onPressed,
        variant: FButtonVariant.outline,
        child: child,
      );
    }

    final theme = FTheme.of(context);
    final textColor = foregroundColor ?? theme.colors.primaryForeground;

    return FButton.raw(
      onPress: onPressed,
      variant: FButtonVariant.ghost,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.colors.primary,
            border: borderColor != null
                ? Border.all(color: borderColor!)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: IconTheme(
              data: IconThemeData(color: textColor, size: 20),
              child: DefaultTextStyle(
                style: theme.typography.sm.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
