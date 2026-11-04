import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/router/app_routes.dart';

import 'views/home_screen.dart';
import 'views/selecionar_metodo_screen.dart';

/// Rota de entrada da simulação guiada.
///
/// As subrotas de cada método continuam sendo definidas pelas features de
/// método e chegam aqui via [children], mantendo o roteador central apenas
/// como composition root.
GoRoute simulacaoGuiadaRoute({List<RouteBase> children = const []}) {
  return GoRoute(
    path: AppRoutes.home,
    builder: (context, state) => const HomeScreen(),
    routes: [
      GoRoute(
        path: 'tutorial',
        builder: (context, state) => const SelecionarMetodoScreen(),
      ),
      ...children,
    ],
  );
}
