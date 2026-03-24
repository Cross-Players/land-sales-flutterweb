import 'package:flutter/material.dart';

class AppTheme {
  static const primaryDark = Color(0xFF0A2342);
  static const primaryLight = Color(0xFF0D2D4A);
  static const accentBlue = Color(0xFF1E88E5);
  static const background = Color(0xFFF5F7FA);
  static const textPrimary = Color(0xFF0A2342);
  static const textSecondary = Color(0xFF64748B);

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentBlue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
