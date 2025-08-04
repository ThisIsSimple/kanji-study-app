import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'SUITE', // SUITE 폰트를 기본 폰트로 설정
      textTheme: const TextTheme(
        // Display
        displayLarge: TextStyle(
          fontFamily: 'SUITE',
          fontWeight: FontWeight.w700,
          fontSize: 57,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontFamily: 'SUITE',
          fontWeight: FontWeight.w700,
          fontSize: 45,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          fontFamily: 'SUITE',
          fontWeight: FontWeight.w600,
          fontSize: 36,
          height: 1.2,
        ),
        
        // Headline
        headlineLarge: TextStyle(
          fontFamily: 'SUITE',
          fontWeight: FontWeight.w600,
          fontSize: 32,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'SUITE',
          fontWeight: FontWeight.w600,
          fontSize: 28,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'SUITE',
          fontWeight: FontWeight.w500,
          fontSize: 24,
          height: 1.3,
        ),
        
        // Title
        titleLarge: TextStyle(
          fontFamily: 'SUITE',
          fontWeight: FontWeight.w600,
          fontSize: 22,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontFamily: 'SUITE',
          fontWeight: FontWeight.w500,
          fontSize: 16,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontFamily: 'SUITE',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          height: 1.4,
        ),
        
        // Body
        bodyLarge: TextStyle(
          fontFamily: 'SUITE',
          fontWeight: FontWeight.w400,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'SUITE',
          fontWeight: FontWeight.w400,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: 'SUITE',
          fontWeight: FontWeight.w400,
          fontSize: 12,
          height: 1.5,
        ),
        
        // Label
        labelLarge: TextStyle(
          fontFamily: 'SUITE',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          fontFamily: 'SUITE',
          fontWeight: FontWeight.w500,
          fontSize: 12,
          height: 1.4,
        ),
        labelSmall: TextStyle(
          fontFamily: 'SUITE',
          fontWeight: FontWeight.w500,
          fontSize: 11,
          height: 1.4,
        ),
      ),
    );
  }

}