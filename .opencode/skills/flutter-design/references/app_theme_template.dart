// TEMPLATE — padrão de tema para novos projetos Flutter.
// Adapte os valores de AppColors ao branding real do projeto, mas mantenha
// a ESTRUTURA: ThemeData construído a partir de tokens semânticos, nunca de
// cores/valores soltos espalhados pelos widgets.
//
// Princípios embutidos neste template (ver references/design_principles.md
// para a lista completa):
// - Material 3 (useMaterial3: true) como baseline.
// - Design flat: elevation: 0 em quase tudo; separação por borda
//   (outline/outlineVariant), não por sombra.
// - Dois níveis de raio de borda: cardRadius (containers grandes) e
//   controlRadius (botões, inputs, controles menores).
// - Acessibilidade como parâmetro de primeira classe do tema, não um extra:
//   fontScale, highContrast e boldText entram na assinatura de light()/dark().
// - highContrast troca a ColorScheme inteira por uma variante de alto
//   contraste (via ColorScheme.highContrastLight/Dark ou equivalente), não
//   apenas escurece/clareia cores pontualmente.

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light({
    double fontScale = 1,
    bool highContrast = false,
    bool boldText = false,
  }) => _build(_lightColors(highContrast), fontScale, highContrast, boldText);

  static ThemeData dark({
    double fontScale = 1,
    bool highContrast = false,
    bool boldText = false,
  }) => _build(_darkColors(highContrast), fontScale, highContrast, boldText);

  static ThemeData _build(
    ColorScheme colors,
    double scale,
    bool highContrast,
    bool boldText,
  ) {
    // Escala de raio — reutilize estas duas constantes em qualquer widget
    // customizado do projeto em vez de criar novos valores de raio.
    final cardRadius = BorderRadius.circular(24);
    final controlRadius = BorderRadius.circular(16);

    final border = BorderSide(
      color: highContrast ? colors.outline : colors.outlineVariant,
      width: highContrast ? 2 : 1,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      colorScheme: colors,
      textTheme: AppTextStyles.buildTextTheme(scale, boldText: boldText),
      scaffoldBackgroundColor: colors.surface,
      focusColor: colors.primary.withValues(alpha: .16),

      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20 * scale,
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colors.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: cardRadius, side: border),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: colors.surfaceContainerLow,
        indicatorColor: colors.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.onSurfaceVariant,
            size: 24,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12 * scale,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.onSurfaceVariant,
          ),
        ),
      ),

      // Botões/inputs/ícones: alvo de toque mínimo 48x48 (acessibilidade),
      // sempre usando controlRadius, sempre com textStyle escalado por
      // `scale` — nunca fontSize fixo.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: controlRadius),
          textStyle: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          side: BorderSide(color: colors.outline),
          shape: RoundedRectangleBorder(borderRadius: controlRadius),
          textStyle: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: controlRadius, borderSide: border),
        enabledBorder: OutlineInputBorder(borderRadius: controlRadius, borderSide: border),
        focusedBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        labelStyle: TextStyle(fontSize: 14 * scale, color: colors.onSurfaceVariant),
        hintStyle: TextStyle(fontSize: 14 * scale, color: colors.onSurfaceVariant),
      ),

      dividerTheme: DividerThemeData(color: colors.outlineVariant, thickness: 1),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? colors.onPrimary : colors.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? colors.primary
              : colors.surfaceContainerHighest,
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: colors.primary,
        inactiveTrackColor: colors.surfaceContainerHighest,
        thumbColor: colors.primary,
        overlayColor: colors.primary.withValues(alpha: .12),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: TextStyle(color: colors.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // Substitua os valores de AppColors pelos tokens de marca reais do
  // projeto. A ESTRUTURA (ColorScheme completo, variante highContrast
  // separada, light/dark simétricos) deve ser preservada.
  static ColorScheme _lightColors(bool highContrast) {
    if (highContrast) {
      return const ColorScheme.highContrastLight(
        primary: Color(0xFF173B2C),
        onPrimary: Colors.white,
        secondary: Color(0xFF382A00),
        onSecondary: Colors.white,
        error: Color(0xFF8C0009),
        onError: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
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
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      inversePrimary: AppColors.inversePrimary,
      surfaceTint: AppColors.primary,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Colors.white,
      surfaceContainer: Color(0xFFF2EFE5),
      surfaceContainerHigh: Color(0xFFECE9DE),
      surfaceContainerHighest: Color(0xFFE5E3D9),
    );
  }

  static ColorScheme _darkColors(bool highContrast) {
    if (highContrast) {
      return const ColorScheme.highContrastDark(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Color(0xFFFFE787),
        onSecondary: Colors.black,
        error: Color(0xFFFFB4AB),
        onError: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
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
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.inverseSurfaceDark,
      onInverseSurface: AppColors.inverseOnSurfaceDark,
      inversePrimary: AppColors.inversePrimaryDark,
      surfaceTint: AppColors.primaryDark,
      surfaceContainerLowest: Color(0xFF090B0A),
      surfaceContainerLow: Color(0xFF171B18),
      surfaceContainer: Color(0xFF202622),
      surfaceContainerHigh: Color(0xFF282F2B),
      surfaceContainerHighest: Color(0xFF303833),
    );
  }
}
