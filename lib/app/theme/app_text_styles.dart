import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Constantes originais (compatibilidade)
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle kpiValue = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle kpiLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Métodos com fontScale para acessibilidade
  static TextStyle scaled(double fontScale, {bool bold = false}) {
    return TextStyle(
      fontSize: 14 * fontScale,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );
  }

  static TextStyle heading1Scaled(double fontScale, {bool bold = false}) {
    return TextStyle(
      fontSize: 24 * fontScale,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle heading2Scaled(double fontScale, {bool bold = false}) {
    return TextStyle(
      fontSize: 20 * fontScale,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle heading3Scaled(double fontScale, {bool bold = false}) {
    return TextStyle(
      fontSize: 16 * fontScale,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle bodyScaled(double fontScale, {bool bold = false}) {
    return TextStyle(
      fontSize: 14 * fontScale,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle bodySmallScaled(double fontScale, {bool bold = false}) {
    return TextStyle(
      fontSize: 12 * fontScale,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: AppColors.textSecondary,
    );
  }

  static TextStyle labelScaled(double fontScale, {bool bold = false}) {
    return TextStyle(
      fontSize: 12 * fontScale,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: AppColors.textSecondary,
    );
  }

  static TextStyle kpiValueScaled(double fontScale, {bool bold = false}) {
    return TextStyle(
      fontSize: 28 * fontScale,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
      color: AppColors.primary,
    );
  }

  static TextStyle kpiLabelScaled(double fontScale, {bool bold = false}) {
    return TextStyle(
      fontSize: 12 * fontScale,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: AppColors.textSecondary,
    );
  }

  // Material 3 Text Theme
  static TextTheme buildTextTheme(double fontScale, {bool boldText = false}) {
    final weight = boldText ? FontWeight.w700 : FontWeight.w400;
    final labelWeight = boldText ? FontWeight.w800 : FontWeight.w500;

    return TextTheme(
      displayLarge: TextStyle(fontSize: 57 * fontScale, fontWeight: weight),
      displayMedium: TextStyle(fontSize: 45 * fontScale, fontWeight: weight),
      displaySmall: TextStyle(fontSize: 36 * fontScale, fontWeight: weight),
      headlineLarge: TextStyle(fontSize: 32 * fontScale, fontWeight: weight),
      headlineMedium: TextStyle(fontSize: 28 * fontScale, fontWeight: weight),
      headlineSmall: TextStyle(fontSize: 24 * fontScale, fontWeight: weight),
      titleLarge: TextStyle(fontSize: 22 * fontScale, fontWeight: weight),
      titleMedium: TextStyle(fontSize: 16 * fontScale, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontSize: 14 * fontScale, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16 * fontScale, fontWeight: weight),
      bodyMedium: TextStyle(fontSize: 14 * fontScale, fontWeight: weight),
      bodySmall: TextStyle(fontSize: 12 * fontScale, fontWeight: weight),
      labelLarge: TextStyle(fontSize: 14 * fontScale, fontWeight: labelWeight),
      labelMedium: TextStyle(fontSize: 12 * fontScale, fontWeight: labelWeight),
      labelSmall: TextStyle(fontSize: 11 * fontScale, fontWeight: labelWeight),
    );
  }
}
