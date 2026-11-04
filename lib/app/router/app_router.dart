import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/router/app_routes.dart';
import 'package:irrigasim/core/navigation/main_shell.dart';
import 'package:irrigasim/features/cenarios/routes.dart';
import 'package:irrigasim/features/irrigacao_faixas/routes.dart';
import 'package:irrigasim/features/irrigacao_inundacao/routes.dart';
import 'package:irrigasim/features/irrigacao_sulcos/routes.dart';
import 'package:irrigasim/features/perfil/routes.dart';
import 'package:irrigasim/features/simulacao_guiada/routes.dart';

/// Composition root: junta as rotas das features no shell principal.
///
/// Cada feature de método publica suas próprias rotas no respectivo
/// `routes.dart`; este arquivo apenas as monta como subrotas do fluxo
/// guiado, preservando os deep links existentes.
final _rotasDeMetodo = <RouteBase>[
  ...sulcosRoutes,
  ...faixasRoutes,
  ...inundacaoRoutes,
];

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [simulacaoGuiadaRoute(children: _rotasDeMetodo)],
          ),
          StatefulShellBranch(routes: cenariosRoutes),
          StatefulShellBranch(routes: perfilRoutes),
        ],
      ),
    ],
  );
});
