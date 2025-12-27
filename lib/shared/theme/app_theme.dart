import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    const navBg = Color(0xFF141E28);
    const navBlue = Color(0xFF1677FF);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.deepLayer,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryAccent,
        secondary: AppColors.secondaryAccent,
        surface: AppColors.primaryBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navBg,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: navBlue),
        actionsIconTheme: IconThemeData(color: navBlue),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBg,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 26,
            color: selected ? navBlue : Colors.white54,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? navBlue : Colors.white54,
          );
        }),
      ),
      cardColor: AppColors.primaryBackground,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: AppColors.deepLayer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.secondaryAccent),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.highlight,
      ),
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
