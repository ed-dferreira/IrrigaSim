import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Light Theme
  static const primary = Color(0xFF1565C0);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFD1E4FF);
  static const secondary = Color(0xFF546E7A);
  static const surface = Color(0xFFFDFBFF);
  static const onSurface = Color(0xFF1A1C1E);
  static const error = Color(0xFFBA1A1A);

  // Dark Theme
  static const primaryDark = Color(0xFF9ECAFF);
  static const onPrimaryDark = Color(0xFF003258);
  static const surfaceDark = Color(0xFF1A1C1E);
  static const onSurfaceDark = Color(0xFFE2E2E6);

  // Cores de Status
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF57F17);
  static const info = Color(0xFF1565C0);

  // Cores por Método
  static const sulco = Color(0xFF42A5F5);
  static const faixa = Color(0xFF66BB6A);
  static const inundacao = Color(0xFFFFA726);

  // Cores de classificação (mantidas para compatibilidade)
  static const excelent = success;
  static const good = Color(0xFF689F38);
  static const regular = warning;
  static const bad = error;

  // Cores auxiliares
  static const textPrimary = Color(0xFF1A1C1E);
  static const textSecondary = Color(0xFF757575);
  static const textHint = Color(0xFFBDBDBD);
  static const divider = Color(0xFFE0E0E0);
  static const background = Color(0xFFFAFAFA);
  static const card = Colors.white;
}
