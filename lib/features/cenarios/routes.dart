import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/router/app_routes.dart';

import 'views/cenarios_screen.dart';

final cenariosRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.cenarios,
    builder: (context, state) => const CenariosScreen(),
  ),
];
