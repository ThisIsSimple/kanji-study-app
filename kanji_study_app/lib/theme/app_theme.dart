import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class AppTheme {
  static ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'SUITE', // SUITE 폰트를 기본 폰트로 설정
      textTheme: const TextTheme(
        // Display
        displayLarge: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 57,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 45,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 36,
          height: 1.2,
        ),

        // Headline
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 32,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 28,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 24,
          height: 1.3,
        ),

        // Title
        titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 22,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          height: 1.4,
        ),

        // Body
        bodyLarge: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12,
          height: 1.5,
        ),

        // Label
        labelLarge: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
          height: 1.4,
        ),
        labelSmall: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
          height: 1.4,
        ),
      ),
    );
  }

  static FThemeData getFTheme() {
    return FThemeData(
      colors: FThemes.zinc.light.colors,
      typography: FTypography(
        defaultFontFamily: 'SUITE',
        xs: const TextStyle(fontFamily: 'SUITE', fontSize: 12, height: 1.33),
        sm: const TextStyle(fontFamily: 'SUITE', fontSize: 14, height: 1.43),
        base: const TextStyle(fontFamily: 'SUITE', fontSize: 16, height: 1.5),
        lg: const TextStyle(fontFamily: 'SUITE', fontSize: 18, height: 1.56),
        xl: const TextStyle(fontFamily: 'SUITE', fontSize: 20, height: 1.4),
        xl2: const TextStyle(fontFamily: 'SUITE', fontSize: 24, height: 1.33),
        xl3: const TextStyle(fontFamily: 'SUITE', fontSize: 30, height: 1.2),
        xl4: const TextStyle(fontFamily: 'SUITE', fontSize: 36, height: 1.11),
        xl5: const TextStyle(fontFamily: 'SUITE', fontSize: 48, height: 1),
        xl6: const TextStyle(fontFamily: 'SUITE', fontSize: 60, height: 1),
        xl7: const TextStyle(fontFamily: 'SUITE', fontSize: 72, height: 1),
        xl8: const TextStyle(fontFamily: 'SUITE', fontSize: 96, height: 1),
      ),
    );
  }
}
