import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:forui/forui.dart';

class AppTheme {
  static ThemeData getLightTheme() {
    return getFTheme().toApproximateMaterialTheme().copyWith(
      splashFactory: InkRipple.splashFactory,
    );
  }

  static FThemeData getFTheme() {
    const colors = FColors.zincLight;
    final touch = _usesTouchTheme;

    return FThemeData(
      touch: touch,
      debugLabel: touch
          ? 'Konnakanji Zinc Light Touch'
          : 'Konnakanji Zinc Light Desktop',
      colors: colors,
      typography: FTypography.inherit(
        colors: colors,
        touch: touch,
        fontFamily: 'SUITE',
      ),
    );
  }

  static bool get _usesTouchTheme {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => true,
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => false,
    };
  }
}
