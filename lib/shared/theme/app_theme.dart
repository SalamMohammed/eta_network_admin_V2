import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.deepLayer,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryAccent,
        secondary: AppColors.secondaryAccent,
        surface: AppColors.primaryBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBackground,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: AppColors.primaryBackground,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: AppColors.deepLayer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.secondaryAccent),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.highlight),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.vipAccent,
        labelStyle: const TextStyle(color: Colors.white),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      dividerColor: AppColors.primaryBackground.withValues(alpha: 0.6),
    );
  }
}
