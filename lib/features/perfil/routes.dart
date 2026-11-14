import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/router/app_routes.dart';

import 'views/perfil_screen.dart';

/// Rota do Perfil.
///
/// O composition root injeta as rotas filhas, como o tutorial, sem que esta
/// feature precise importá-las.
GoRoute perfilRoute({List<RouteBase> children = const []}) {
  return GoRoute(
    path: AppRoutes.perfil,
    builder: (context, state) => const PerfilScreen(),
    routes: children,
  );
}
