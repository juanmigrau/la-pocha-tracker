import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color primary = Color(0xFF2E7D5B);
  static const Color surface = Color(0xFFF2EFE9);
  static const Color onSurface = Color(0xFF2B2B28);
  static const Color onSurfaceVariant = Color(0xFF6B6B66);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      tertiary: const Color(0xFFD9772E),
      tertiaryContainer: const Color(0xFFFCEFE0),
      onTertiaryContainer: const Color(0xFFD9772E),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: const Color(0xFF1A2420),
      onSurface: const Color(0xFFE8E5DE),
      onSurfaceVariant: const Color(0xFFAAA89F),
      primary: const Color(0xFF4CAF82),
      tertiary: const Color(0xFFE8924A),
      tertiaryContainer: const Color(0xFF3D2A1A),
      onTertiaryContainer: const Color(0xFFE8924A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF1A2420),
      cardTheme: CardThemeData(
        color: const Color(0xFF243028),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF82),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
