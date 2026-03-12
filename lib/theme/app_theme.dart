import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const navy = Color(0xFF0A1628);
  static const blue = Color(0xFF1A56DB);
  static const blueLight = Color(0xFFEEF3FF);
  static const blueMid = Color(0xFF3B82F6);

  // Status colors
  static const green = Color(0xFF10B981);
  static const greenLight = Color(0xFFECFDF5);
  static const red = Color(0xFFEF4444);
  static const redLight = Color(0xFFFEF2F2);
  static const amber = Color(0xFFF59E0B);
  static const amberLight = Color(0xFFFFFBEB);
  static const purple = Color(0xFF8B5CF6);
  static const purpleLight = Color(0xFFF5F3FF);

  // Neutrals
  static const background = Color(0xFFF0F4F8);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1E293B);
  static const textMuted = Color(0xFF64748B);
  static const surfaceSecondary = Color(0xFFF8FAFC);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
      secondary: AppColors.navy,
      surface: AppColors.surface,
      background: AppColors.background,
      error: AppColors.red,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.blue,
        side: const BorderSide(color: AppColors.blue, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.blue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red),
      ),
      labelStyle: const TextStyle(
        color: AppColors.textMuted,
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(
        color: AppColors.textMuted,
        fontFamily: 'Nunito',
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28, fontWeight: FontWeight.w800,
        color: AppColors.textPrimary, fontFamily: 'Nunito',
      ),
      headlineMedium: TextStyle(
        fontSize: 22, fontWeight: FontWeight.w800,
        color: AppColors.textPrimary, fontFamily: 'Nunito',
      ),
      headlineSmall: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, fontFamily: 'Nunito',
      ),
      titleLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, fontFamily: 'Nunito',
      ),
      titleMedium: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, fontFamily: 'Nunito',
      ),
      bodyLarge: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary, fontFamily: 'Nunito',
      ),
      bodyMedium: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w400,
        color: AppColors.textMuted, fontFamily: 'Nunito',
      ),
      labelSmall: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: AppColors.textMuted, fontFamily: 'Nunito',
        letterSpacing: 0.5,
      ),
    ),
  );
}
