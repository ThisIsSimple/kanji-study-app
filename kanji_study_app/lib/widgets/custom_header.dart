import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Title alignment options for CustomHeader
enum HeaderTitleAlign {
  left,
  center,
  right,
}

/// Custom header widget with flexible action placement and dynamic title positioning
class CustomHeader extends StatelessWidget {
  final Widget? title;
  final List<Widget> leftActions;
  final List<Widget> rightActions;
  final bool withBack;
  final HeaderTitleAlign titleAlign;

  const CustomHeader({
    super.key,
    this.title,
    this.leftActions = const [],
    this.rightActions = const [],
    this.withBack = false,
    this.titleAlign = HeaderTitleAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    // Build left side with optional back button
    final List<Widget> leftSide = [];
    if (withBack) {
      leftSide.add(
        FButton.icon(
          onPress: () => Navigator.of(context).pop(),
          style: FButtonStyle.ghost(),
          child: Icon(PhosphorIconsRegular.caretLeft, size: 20),
        ),
      );
    }
    leftSide.addAll(leftActions);

    // Build title widget with proper styling
    Widget? styledTitle;
    if (title != null) {
      if (title is Expanded) {
        styledTitle = title;
      } else {
        styledTitle = DefaultTextStyle(
          style: theme.typography.lg.copyWith(
            fontWeight: FontWeight.w600,
          ),
          child: title!,
        );
      }
    }

    // For center alignment, use Stack to achieve true center positioning
    if (titleAlign == HeaderTitleAlign.center) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: SafeArea(
          bottom: false,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Title in true center (bottom layer)
              if (styledTitle != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Center(child: styledTitle),
                ),
              // Actions row on top
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (leftSide.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: leftSide,
                    )
                  else
                    const SizedBox.shrink(),
                  if (rightActions.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: rightActions,
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // For left and right alignment, use Row-based layout
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Left alignment: leftActions + title + spacer + rightActions
            if (titleAlign == HeaderTitleAlign.left) ...[
              if (leftSide.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: leftSide,
                ),
              if (styledTitle != null)
                styledTitle is Expanded
                    ? styledTitle
                    : Flexible(child: styledTitle),
              const Spacer(),
              if (rightActions.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: rightActions,
                ),
            ],

            // Right alignment: leftActions + spacer + title + rightActions
            if (titleAlign == HeaderTitleAlign.right) ...[
              if (leftSide.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: leftSide,
                ),
              const Spacer(),
              if (styledTitle != null)
                styledTitle is Expanded
                    ? styledTitle
                    : Flexible(child: styledTitle),
              if (rightActions.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: rightActions,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Helper widget for header action buttons
class HeaderActionButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;

  const HeaderActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FButton.icon(
      onPress: onPressed,
      style: FButtonStyle.ghost(),
      child: icon,
    );
  }
}
