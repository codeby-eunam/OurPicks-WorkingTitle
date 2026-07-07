import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.heading(20),
      ),
      textTheme: TextTheme(
        headlineLarge: AppTypography.heading(32),
        headlineMedium: AppTypography.heading(28),
        headlineSmall: AppTypography.heading(24),
        titleLarge: AppTypography.heading(20),
        titleMedium: AppTypography.heading(16),
        titleSmall: AppTypography.heading(14),
        bodyLarge: AppTypography.bodyStyle(16),
        bodyMedium: AppTypography.bodyStyle(14),
        bodySmall: AppTypography.bodyStyle(12, color: AppColors.textSecondary),
        labelLarge: AppTypography.heading(15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: AppTypography.heading(15, color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle: AppTypography.heading(15),
          side: BorderSide(
            color: AppColors.border,
            width: AppRadius.hairline,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(
            color: AppColors.border,
            width: AppRadius.hairline,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        shape: AppRadius.sheetShape,
      ),
    );
  }
}
