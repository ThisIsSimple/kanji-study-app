import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../l10n/localization_extensions.dart';
import '../services/connectivity_service.dart';

/// Title alignment options for CustomHeader
enum HeaderTitleAlign { left, center, right }

/// Custom header widget with flexible action placement and dynamic title positioning
class CustomHeader extends StatelessWidget {
  final Widget? title;
  final List<Widget> leftActions;
  final List<Widget> rightActions;
  final bool withBack;
  final HeaderTitleAlign titleAlign;
  final bool showOfflineBanner;
  final bool showSearch;
  final TextEditingController? searchController;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClear;

  const CustomHeader({
    super.key,
    this.title,
    this.leftActions = const [],
    this.rightActions = const [],
    this.withBack = false,
    this.titleAlign = HeaderTitleAlign.left,
    this.showOfflineBanner = true,
    this.showSearch = false,
    this.searchController,
    this.searchHint,
    this.onSearchChanged,
    this.onSearchClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    // Use StreamBuilder to reactively listen to connectivity changes
    return StreamBuilder<bool>(
      stream: ConnectivityService.instance.onConnectivityChanged,
      initialData: ConnectivityService.instance.isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        final shouldShowBanner = showOfflineBanner && !isOnline;

        return _buildHeader(context, theme, shouldShowBanner);
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    FThemeData theme,
    bool shouldShowBanner,
  ) {
    final l10n = context.l10n;
    // Build left side with optional back button
    final List<Widget> leftSide = [];
    if (withBack) {
      leftSide.add(
        FButton.icon(
          onPress: () => Navigator.of(context).pop(),
          variant: FButtonVariant.ghost,
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
        // Calculate conditional padding based on actions (skip for center alignment)
        EdgeInsets titlePadding = EdgeInsets.zero;
        if (titleAlign != HeaderTitleAlign.center) {
          final hasLeftActions = withBack || leftActions.isNotEmpty;
          final hasRightActions = rightActions.isNotEmpty;
          titlePadding = EdgeInsets.only(
            left: hasLeftActions ? 0 : 8,
            right: hasRightActions ? 0 : 8,
          );
        }

        styledTitle = Padding(
          padding: titlePadding,
          child: DefaultTextStyle(
            style: theme.typography.lg.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colors.foreground,
            ),
            child: title!,
          ),
        );
      }
    }

    // Build offline banner widget
    Widget buildOfflineBanner() {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 8,
          left: 16,
          right: 16,
        ),
        color: theme.colors.muted,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIconsRegular.wifiSlash,
              size: 16,
              color: theme.colors.mutedForeground,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.offlineMode,
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    // Build search bar widget
    Widget buildSearchBar() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: FTextField(
          control: FTextFieldControl.managed(
            controller: searchController,
            onChange: (value) => onSearchChanged?.call(value.text),
          ),
          hint: searchHint ?? l10n.searchGenericHint,
          prefixBuilder: (context, style, variants) =>
              FTextField.prefixIconBuilder(
                context,
                style,
                variants,
                Icon(PhosphorIconsRegular.magnifyingGlass, size: 18),
              ),
          clearable: (value) => value.text.isNotEmpty,
          clearIconBuilder: (context, style, clear) {
            return FTextField.defaultClearIconBuilder(context, style, () {
              clear();
              onSearchClear?.call();
            });
          },
          onSubmit: (_) => FocusScope.of(context).unfocus(),
          textInputAction: TextInputAction.search,
        ),
      );
    }

    // For center alignment, use Stack to achieve true center positioning
    if (titleAlign == HeaderTitleAlign.center) {
      final content = Stack(
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
                Row(mainAxisSize: MainAxisSize.min, children: leftSide)
              else
                const SizedBox.shrink(),
              if (rightActions.isNotEmpty)
                Row(mainAxisSize: MainAxisSize.min, children: rightActions)
              else
                const SizedBox.shrink(),
            ],
          ),
        ],
      );

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (shouldShowBanner) buildOfflineBanner(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: shouldShowBanner
                ? content
                : SafeArea(bottom: false, child: content),
          ),
          if (showSearch) buildSearchBar(),
        ],
      );
    }

    // For left and right alignment, use Row-based layout
    final content = Row(
      children: [
        // Left alignment: leftActions + title + spacer + rightActions
        if (titleAlign == HeaderTitleAlign.left) ...[
          if (leftSide.isNotEmpty)
            Row(mainAxisSize: MainAxisSize.min, children: leftSide),
          if (styledTitle != null)
            styledTitle is Expanded
                ? styledTitle
                : Flexible(child: styledTitle),
          const Spacer(),
          if (rightActions.isNotEmpty)
            Row(mainAxisSize: MainAxisSize.min, children: rightActions),
        ],

        // Right alignment: leftActions + spacer + title + rightActions
        if (titleAlign == HeaderTitleAlign.right) ...[
          if (leftSide.isNotEmpty)
            Row(mainAxisSize: MainAxisSize.min, children: leftSide),
          const Spacer(),
          if (styledTitle != null)
            styledTitle is Expanded
                ? styledTitle
                : Flexible(child: styledTitle),
          if (rightActions.isNotEmpty)
            Row(mainAxisSize: MainAxisSize.min, children: rightActions),
        ],
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shouldShowBanner) buildOfflineBanner(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: shouldShowBanner
              ? content
              : SafeArea(bottom: false, child: content),
        ),
        if (showSearch) buildSearchBar(),
      ],
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
      variant: FButtonVariant.ghost,
      child: icon,
    );
  }
}
