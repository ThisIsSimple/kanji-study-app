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
        style: FButtonStyle.outline(),
        child: child,
      );
    }

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: borderColor != null ? BorderSide(color: borderColor!) : null,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: child,
      ),
    );
  }
}
