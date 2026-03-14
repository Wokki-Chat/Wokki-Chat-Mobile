import 'package:flutter/material.dart';
import 'package:wokki_chat/theme/app_colors.dart';

enum AppThemeMode {
  light,
  slate,
  owl,
  midnight,
}

extension AppThemeModeExtension on AppThemeMode {
  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.slate:
        return 'Slate';
      case AppThemeMode.owl:
        return 'Owl';
      case AppThemeMode.midnight:
        return 'Midnight';
    }
  }

  AppColors get colors {
    switch (this) {
      case AppThemeMode.light:
        return AppColors.light;
      case AppThemeMode.slate:
        return AppColors.slate;
      case AppThemeMode.owl:
        return AppColors.owl;
      case AppThemeMode.midnight:
        return AppColors.midnight;
    }
  }
}

class AppTheme {
  static ThemeData createTheme(AppColors colors) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: colors.surfaceA0,
      colorScheme: ColorScheme(
        brightness: colors.surfaceA0.computeLuminance() > 0.5 
            ? Brightness.light 
            : Brightness.dark,
        primary: colors.primaryA0,
        onPrimary: colors.textWhiteA0,
        secondary: colors.secondaryA0,
        onSecondary: colors.textBlackA0,
        error: colors.dangerA0,
        onError: colors.textWhiteA0,
        surface: colors.surfaceA0,
        onSurface: colors.textA0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surfaceA0,
        foregroundColor: colors.textA0,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primaryA0,
          foregroundColor: colors.textWhiteA0,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primaryA0,
          side: BorderSide(color: colors.primaryA0, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputBgDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.inputBorderBgDarkest),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.inputBorderBgDarkest),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primaryA0, width: 2),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          color: colors.textA30,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          color: colors.textA40,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Inter',
          color: colors.textA0,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Inter',
          color: colors.textA0,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Inter',
          color: colors.textA0,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Inter',
          color: colors.textA0,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Inter',
          color: colors.textA0,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Inter',
          color: colors.textA0,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          color: colors.textA0,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          color: colors.textA10,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Inter',
          color: colors.textA20,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Inter',
          color: colors.textA0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}