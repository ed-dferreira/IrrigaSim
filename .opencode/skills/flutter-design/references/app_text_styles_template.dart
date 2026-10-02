// TEMPLATE — padrão de tipografia.
// Regras:
// - `buildTextTheme(scale, boldText)` é a fonte de verdade para o TextTheme
//   do ThemeData — todo texto do app deve vir de Theme.of(context).textTheme,
//   não de TextStyle soltos com fontSize hardcoded.
// - As variantes `*Scaled(fontScale, {bold})` existem para os poucos casos
//   em que um widget precisa de um estilo fora do TextTheme padrão
//   (ex.: um valor de KPI gigante) mas ainda precisa respeitar a escala de
//   fonte do usuário — nunca crie um TextStyle novo sem parametrizar `scale`.
// - Os nomes "legados" (heading1, body, kpiValue...) sem sufixo Scaled não
//   respeitam acessibilidade e só devem existir por compatibilidade com
//   código antigo — não os use em código novo.

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

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

  /// Fonte de verdade do tema: todo texto padrão do app passa por aqui.
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
