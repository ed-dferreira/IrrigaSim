import 'package:flutter/material.dart';

/// Cores semânticas do IrrigaSim: Agro natural no claro e Premium no escuro.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF276749);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFDDEADF);
  static const onPrimaryContainer = Color(0xFF173B2C);
  static const secondary = Color(0xFF6B5A2B);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFF2E7C2);
  static const onSecondaryContainer = Color(0xFF392F12);
  static const tertiary = Color(0xFF9A6700);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFFFE6A7);
  static const onTertiaryContainer = Color(0xFF382A00);
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF410002);
  static const background = Color(0xFFF7F3E8);
  static const onBackground = Color(0xFF173B2C);
  static const surface = Color(0xFFF7F3E8);
  static const onSurface = Color(0xFF173B2C);
  static const surfaceVariant = Color(0xFFE8E5DA);
  static const onSurfaceVariant = Color(0xFF52645A);
  static const outline = Color(0xFF687970);
  static const outlineVariant = Color(0xFFD4D9D2);
  static const inverseSurface = Color(0xFF29332E);
  static const inverseOnSurface = Color(0xFFF1F5F2);
  static const inversePrimary = Color(0xFF8DDBB3);

  static const primaryDark = Color(0xFF4ADE9E);
  static const onPrimaryDark = Color(0xFF063B28);
  static const primaryContainerDark = Color(0xFF174D39);
  static const onPrimaryContainerDark = Color(0xFFB8F5D7);
  static const secondaryDark = Color(0xFFD9C98D);
  static const onSecondaryDark = Color(0xFF38300D);
  static const secondaryContainerDark = Color(0xFF4E4520);
  static const onSecondaryContainerDark = Color(0xFFF6E6A5);
  static const tertiaryDark = Color(0xFFE5C45A);
  static const onTertiaryDark = Color(0xFF3D3100);
  static const tertiaryContainerDark = Color(0xFF574800);
  static const onTertiaryContainerDark = Color(0xFFFFE787);
  static const errorDark = Color(0xFFFFB4AB);
  static const onErrorDark = Color(0xFF690005);
  static const errorContainerDark = Color(0xFF93000A);
  static const onErrorContainerDark = Color(0xFFFFDAD6);
  static const backgroundDark = Color(0xFF0E110F);
  static const onBackgroundDark = Color(0xFFF1F5F2);
  static const surfaceDark = Color(0xFF0E110F);
  static const onSurfaceDark = Color(0xFFF1F5F2);
  static const surfaceVariantDark = Color(0xFF303833);
  static const onSurfaceVariantDark = Color(0xFFB8C2BC);
  static const outlineDark = Color(0xFF89958E);
  static const outlineVariantDark = Color(0xFF354039);
  static const inverseSurfaceDark = Color(0xFFF1F5F2);
  static const inverseOnSurfaceDark = Color(0xFF202622);
  static const inversePrimaryDark = Color(0xFF276749);

  static const success = primary;
  static const onSuccess = onPrimary;
  static const successContainer = primaryContainer;
  static const onSuccessContainer = onPrimaryContainer;
  static const warning = Color(0xFF825500);
  static const onWarning = Color(0xFFFFFFFF);
  static const warningContainer = tertiaryContainer;
  static const onWarningContainer = onTertiaryContainer;
  static const info = Color(0xFF356A73);
  static const onInfo = Color(0xFFFFFFFF);
  static const infoContainer = Color(0xFFBCEBF3);
  static const onInfoContainer = Color(0xFF002F35);
  static const successDark = primaryDark;
  static const onSuccessDark = onPrimaryDark;
  static const successContainerDark = primaryContainerDark;
  static const onSuccessContainerDark = onPrimaryContainerDark;
  static const warningDark = tertiaryDark;
  static const onWarningDark = onTertiaryDark;
  static const warningContainerDark = tertiaryContainerDark;
  static const onWarningContainerDark = onTertiaryContainerDark;
  static const infoDark = Color(0xFF8ED3DF);
  static const onInfoDark = Color(0xFF00363D);
  static const infoContainerDark = Color(0xFF174E57);
  static const onInfoContainerDark = Color(0xFFBCEBF3);

  static const sulco = Color(0xFF3B7C78);
  static const faixa = Color(0xFF4D7C45);
  static const inundacao = Color(0xFFB7791F);
  static const excelent = success;
  static const good = Color(0xFF5F7D32);
  static const regular = warning;
  static const bad = error;

  // Compatibilidade com widgets legados. Widgets novos usam ColorScheme.
  static const textPrimary = onSurface;
  static const textSecondary = onSurfaceVariant;
  static const textHint = Color(0xFF829087);
  static const divider = outlineVariant;
  static const card = Color(0xFFFFFFFF);
}
