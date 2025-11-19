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
    final baseTheme = FThemes.zinc.light;
    final baseTypography = baseTheme.typography;

    return baseTheme.copyWith(
      typography: FTypography(
        base: baseTypography.base.copyWith(fontFamily: 'SUITE'),
        sm: baseTypography.sm.copyWith(fontFamily: 'SUITE'),
        xs: baseTypography.xs.copyWith(fontFamily: 'SUITE'),
        lg: baseTypography.lg.copyWith(fontFamily: 'SUITE'),
        xl: baseTypography.xl.copyWith(fontFamily: 'SUITE'),
        xl2: baseTypography.xl2.copyWith(fontFamily: 'SUITE'),
        xl3: baseTypography.xl3.copyWith(fontFamily: 'SUITE'),
        xl4: baseTypography.xl4.copyWith(fontFamily: 'SUITE'),
        xl5: baseTypography.xl5.copyWith(fontFamily: 'SUITE'),
        xl6: baseTypography.xl6.copyWith(fontFamily: 'SUITE'),
        xl7: baseTypography.xl7.copyWith(fontFamily: 'SUITE'),
        xl8: baseTypography.xl8.copyWith(fontFamily: 'SUITE'),
      ),
    );
  }
}
