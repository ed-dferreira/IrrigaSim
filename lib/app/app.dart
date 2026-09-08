import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/router/app_router.dart';
import 'package:irrigasim/app/theme/app_theme.dart';
import 'package:irrigasim/features/perfil/presentation/perfil_view_model.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final perfilState = ref.watch(perfilProvider);

    final isDark = perfilState.temaEscuro;
    final fontScale = perfilState.tamanhoFonte.scale;
    final highContrast = perfilState.altoContraste;
    final boldText = perfilState.textoNegrito;
    final reducedAnimations = perfilState.animacoesReduzidas;

    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final systemBold = MediaQuery.boldTextOf(context);
    final systemTextScaler = MediaQuery.textScalerOf(context);

    final effectiveDark = isDark || (platformBrightness == Brightness.dark && !isDark && perfilState.temaEscuro == false);
    final effectiveBold = boldText || systemBold;
    final systemScale = systemTextScaler.scale(14) / 14;
    final effectiveFontScale = fontScale * systemScale;

    return MaterialApp.router(
      title: 'IrrigaSim',
      theme: AppTheme.light(
        fontScale: effectiveFontScale,
        highContrast: highContrast,
        boldText: effectiveBold,
      ),
      darkTheme: AppTheme.dark(
        fontScale: effectiveFontScale,
        highContrast: highContrast,
        boldText: effectiveBold,
      ),
      themeMode: effectiveDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return _AccessibilityScope(
          reducedAnimations: reducedAnimations,
          modoLeitorTela: perfilState.modoLeitorTela,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _AccessibilityScope extends InheritedWidget {
  final bool reducedAnimations;
  final bool modoLeitorTela;

  const _AccessibilityScope({
    required this.reducedAnimations,
    required this.modoLeitorTela,
    required super.child,
  });

  static _AccessibilityScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AccessibilityScope>();
  }

  @override
  bool updateShouldNotify(_AccessibilityScope oldWidget) {
    return reducedAnimations != oldWidget.reducedAnimations ||
        modoLeitorTela != oldWidget.modoLeitorTela;
  }
}

class AppAccessibility {
  static bool reducedAnimations(BuildContext context) {
    return _AccessibilityScope.of(context)?.reducedAnimations ?? false;
  }

  static bool modoLeitorTela(BuildContext context) {
    return _AccessibilityScope.of(context)?.modoLeitorTela ?? false;
  }
}
