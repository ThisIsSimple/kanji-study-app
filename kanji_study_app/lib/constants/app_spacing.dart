import 'package:flutter/material.dart';

/// AppSpacing - Centralized spacing constants for consistent layout
///
/// This class provides standardized spacing values across the entire app
/// to ensure visual consistency and easier maintenance.
class AppSpacing {
  // Prevent instantiation
  AppSpacing._();

  // Base spacing unit (4px)
  static const double unit = 4.0;

  // Spacing scale
  static const double xs = 4.0; // 1 unit
  static const double sm = 8.0; // 2 units
  static const double md = 12.0; // 3 units
  static const double base = 16.0; // 4 units (primary)
  static const double lg = 20.0; // 5 units
  static const double xl = 24.0; // 6 units
  static const double xxl = 32.0; // 8 units

  // Common EdgeInsets presets

  /// Standard padding for screen-level content (ListView, GridView, etc.)
  static const EdgeInsets screenPadding = EdgeInsets.all(base); // 16px all sides

  /// Standard padding for card internal content
  static const EdgeInsets cardPadding = EdgeInsets.all(base); // 16px all sides

  /// Standard padding for button containers
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: base, // 16px
    vertical: md, // 12px
  );

  /// Vertical spacing between list items
  static const EdgeInsets listItemSpacing = EdgeInsets.symmetric(
    vertical: sm / 2, // 4px top/bottom = 8px total gap
  );

  /// Tight vertical spacing between list items (for dense lists)
  static const EdgeInsets listItemSpacingTight = EdgeInsets.symmetric(
    vertical: xs / 2, // 2px top/bottom = 4px total gap
  );

  /// Section spacing (larger vertical gaps between major sections)
  static const EdgeInsets sectionSpacing = EdgeInsets.symmetric(
    vertical: xl, // 24px
  );
}
