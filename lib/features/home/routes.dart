import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/router/app_routes.dart';

import 'views/home_screen.dart';

/// Rota inicial do aplicativo.
///
/// As features de método publicam rotas relativas a `/home`; este módulo
/// apenas as recebe via [children] para preservar os deep links existentes.
GoRoute homeRoute({List<RouteBase> children = const []}) {
  return GoRoute(
    path: AppRoutes.home,
    builder: (context, state) => const HomeScreen(),
    routes: children,
  );
}
