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
    final colorScheme = _lightColorScheme(highContrast);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: AppTextStyles.buildTextTheme(fontScale, boldText: boldText),
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22 * fontScale,
          fontWeight: boldText ? FontWeight.w700 : FontWeight.w400,
          color: colorScheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12 * fontScale,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: highContrast
              ? BorderSide(color: colorScheme.outline, width: 2)
              : BorderSide(color: colorScheme.outlineVariant),
        ),
        color: colorScheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: TextStyle(
            fontSize: 14 * fontScale,
            fontWeight: boldText ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: TextStyle(
            fontSize: 14 * fontScale,
            fontWeight: boldText ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: TextStyle(
            fontSize: 14 * fontScale,
            fontWeight: boldText ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: TextStyle(
          fontSize: 14 * fontScale,
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: TextStyle(
          fontSize: 14 * fontScale,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return selected ? colorScheme.onPrimary : colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return selected ? colorScheme.primary : colorScheme.surfaceContainerHighest;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.1),
      ),
    );
  }

  static ThemeData dark({
    double fontScale = 1.0,
    bool highContrast = false,
    bool boldText = false,
  }) {
    final colorScheme = _darkColorScheme(highContrast);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: AppTextStyles.buildTextTheme(fontScale, boldText: boldText),
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22 * fontScale,
          fontWeight: boldText ? FontWeight.w700 : FontWeight.w400,
          color: colorScheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12 * fontScale,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: highContrast
              ? BorderSide(color: colorScheme.outline, width: 2)
              : BorderSide(color: colorScheme.outlineVariant),
        ),
        color: colorScheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: TextStyle(
            fontSize: 14 * fontScale,
            fontWeight: boldText ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: TextStyle(
            fontSize: 14 * fontScale,
            fontWeight: boldText ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: TextStyle(
            fontSize: 14 * fontScale,
            fontWeight: boldText ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: TextStyle(
          fontSize: 14 * fontScale,
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: TextStyle(
          fontSize: 14 * fontScale,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return selected ? colorScheme.onPrimary : colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return selected ? colorScheme.primary : colorScheme.surfaceContainerHighest;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.1),
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
        surfaceContainerLow: Color(0xFFFFFFFF),
        surfaceContainer: Color(0xFFF5F5F5),
        surfaceContainerHigh: Color(0xFFEEEEEE),
        surfaceContainerHighest: Color(0xFFE0E0E0),
      );
    }
    return const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      inversePrimary: AppColors.inversePrimary,
      surfaceTint: AppColors.primary,
      surfaceContainerLow: Color(0xFFFCFCFF),
      surfaceContainer: Color(0xFFF6F6FA),
      surfaceContainerHigh: Color(0xFFF0F0F4),
      surfaceContainerHighest: Color(0xFFEAE8EC),
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
        surfaceContainerLow: Color(0xFF0A0A0A),
        surfaceContainer: Color(0xFF141414),
        surfaceContainerHigh: Color(0xFF1E1E1E),
        surfaceContainerHighest: Color(0xFF282828),
      );
    }
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      onPrimary: AppColors.onPrimaryDark,
      primaryContainer: AppColors.primaryContainerDark,
      onPrimaryContainer: AppColors.onPrimaryContainerDark,
      secondary: AppColors.secondaryDark,
      onSecondary: AppColors.onSecondaryDark,
      secondaryContainer: AppColors.secondaryContainerDark,
      onSecondaryContainer: AppColors.onSecondaryContainerDark,
      tertiary: AppColors.tertiaryDark,
      onTertiary: AppColors.onTertiaryDark,
      tertiaryContainer: AppColors.tertiaryContainerDark,
      onTertiaryContainer: AppColors.onTertiaryContainerDark,
      error: AppColors.errorDark,
      onError: AppColors.onErrorDark,
      errorContainer: AppColors.errorContainerDark,
      onErrorContainer: AppColors.onErrorContainerDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.onSurfaceDark,
      onSurfaceVariant: AppColors.onSurfaceVariantDark,
      outline: AppColors.outlineDark,
      outlineVariant: AppColors.outlineVariantDark,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: AppColors.inverseSurfaceDark,
      onInverseSurface: AppColors.inverseOnSurfaceDark,
      inversePrimary: AppColors.inversePrimaryDark,
      surfaceTint: AppColors.primaryDark,
      surfaceContainerLow: Color(0xFF1A1C1E),
      surfaceContainer: Color(0xFF222426),
      surfaceContainerHigh: Color(0xFF2C2E30),
      surfaceContainerHighest: Color(0xFF363840),
    );
  }
}
