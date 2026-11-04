import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/router/app_routes.dart';

import 'views/perfil_screen.dart';

final perfilRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.perfil,
    builder: (context, state) => const PerfilScreen(),
  ),
];
