import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light({
    double fontScale = 1.0,
    bool highContrast = false,
    bool boldText = false,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _lightColorScheme(highContrast),
      textTheme: AppTextStyles.buildTextTheme(fontScale, boldText: boldText),
      scaffoldBackgroundColor: highContrast ? Colors.white : AppColors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20 * fontScale,
          fontWeight: FontWeight.w600,
          color: AppColors.onPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: highContrast ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: highContrast
              ? const BorderSide(color: Colors.black, width: 2)
              : BorderSide.none,
        ),
        color: AppColors.card,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontSize: 14 * fontScale,
            fontWeight: boldText ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: highContrast ? Colors.black : AppColors.divider,
            width: highContrast ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: highContrast ? Colors.black : AppColors.divider,
            width: highContrast ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(
          fontSize: 14 * fontScale,
          color: AppColors.textSecondary,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: highContrast ? Colors.black : AppColors.divider,
        thickness: highContrast ? 2 : 1,
      ),
    );
  }

  static ThemeData dark({
    double fontScale = 1.0,
    bool highContrast = false,
    bool boldText = false,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _darkColorScheme(highContrast),
      textTheme: AppTextStyles.buildTextTheme(fontScale, boldText: boldText),
      scaffoldBackgroundColor: AppColors.surfaceDark,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.onSurfaceDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20 * fontScale,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceDark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: highContrast ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: highContrast
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
        ),
        color: const Color(0xFF2C2C2E),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.onPrimaryDark,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontSize: 14 * fontScale,
            fontWeight: boldText ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: highContrast ? Colors.white : AppColors.divider,
            width: highContrast ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: highContrast ? Colors.white : AppColors.divider,
            width: highContrast ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(
          fontSize: 14 * fontScale,
          color: AppColors.onSurfaceDark,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: highContrast ? Colors.white : AppColors.divider,
        thickness: highContrast ? 2 : 1,
      ),
    );
  }

  static ColorScheme _lightColorScheme(bool highContrast) {
    if (highContrast) {
      return const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF000000),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFF000000),
        onPrimaryContainer: Color(0xFFFFFFFF),
        secondary: Color(0xFF000000),
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFF000000),
        onSecondaryContainer: Color(0xFFFFFFFF),
        tertiary: Color(0xFF000000),
        onTertiary: Color(0xFFFFFFFF),
        tertiaryContainer: Color(0xFF000000),
        onTertiaryContainer: Color(0xFFFFFFFF),
        error: Color(0xFFBA1A1A),
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF000000),
        onSurfaceVariant: Color(0xFF000000),
        outline: Color(0xFF000000),
        outlineVariant: Color(0xFF000000),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFF000000),
        onInverseSurface: Color(0xFFFFFFFF),
        inversePrimary: Color(0xFFFFFFFF),
        surfaceTint: Color(0xFF000000),
      );
    }
    return const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: Color(0xFF001D36),
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFD7E5EB),
      onSecondaryContainer: Color(0xFF0E1D24),
      tertiary: Color(0xFF6B5778),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFF2DAFF),
      onTertiaryContainer: Color(0xFF251431),
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: Color(0xFF44474E),
      outline: Color(0xFF74777F),
      outlineVariant: Color(0xFFC4C6CF),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF2F3033),
      onInverseSurface: Color(0xFFF1F0F4),
      inversePrimary: Color(0xFFA1CAFD),
      surfaceTint: AppColors.primary,
    );
  }

  static ColorScheme _darkColorScheme(bool highContrast) {
    if (highContrast) {
      return const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFFFFFFFF),
        onPrimary: Color(0xFF000000),
        primaryContainer: Color(0xFFFFFFFF),
        onPrimaryContainer: Color(0xFF000000),
        secondary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFF000000),
        secondaryContainer: Color(0xFFFFFFFF),
        onSecondaryContainer: Color(0xFF000000),
        tertiary: Color(0xFFFFFFFF),
        onTertiary: Color(0xFF000000),
        tertiaryContainer: Color(0xFFFFFFFF),
        onTertiaryContainer: Color(0xFF000000),
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: Color(0xFF000000),
        onSurface: Color(0xFFFFFFFF),
        onSurfaceVariant: Color(0xFFFFFFFF),
        outline: Color(0xFFFFFFFF),
        outlineVariant: Color(0xFFFFFFFF),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFFFFFFFF),
        onInverseSurface: Color(0xFF000000),
        inversePrimary: Color(0xFF000000),
        surfaceTint: Color(0xFFFFFFFF),
      );
    }
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      onPrimary: AppColors.onPrimaryDark,
      primaryContainer: Color(0xFF00497D),
      onPrimaryContainer: Color(0xFFD1E4FF),
      secondary: Color(0xFFBBC7CF),
      onSecondary: Color(0xFF263239),
      secondaryContainer: Color(0xFF3C4950),
      onSecondaryContainer: Color(0xFFD7E5EB),
      tertiary: Color(0xFFD6BEE4),
      onTertiary: Color(0xFF3B2948),
      tertiaryContainer: Color(0xFF523F5F),
      onTertiaryContainer: Color(0xFFF2DAFF),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: AppColors.surfaceDark,
      onSurface: AppColors.onSurfaceDark,
      onSurfaceVariant: Color(0xFFC4C6CF),
      outline: Color(0xFF8E9099),
      outlineVariant: Color(0xFF44474E),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE2E2E6),
      onInverseSurface: Color(0xFF2F3033),
      inversePrimary: Color(0xFF0061A4),
      surfaceTint: AppColors.primaryDark,
    );
  }
}
