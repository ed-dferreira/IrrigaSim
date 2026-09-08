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

    return MaterialApp.router(
      title: 'IrrigaSim',
      theme: AppTheme.light(
        fontScale: fontScale,
        highContrast: highContrast,
        boldText: boldText,
      ),
      darkTheme: AppTheme.dark(
        fontScale: fontScale,
        highContrast: highContrast,
        boldText: boldText,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
