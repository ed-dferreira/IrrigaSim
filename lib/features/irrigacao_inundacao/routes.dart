import 'package:go_router/go_router.dart';

import 'views/basin_project_screen.dart';
import 'views/basin_reference_screen.dart';
import 'views/basin_results_screen.dart';

/// Rotas da feature de irrigação por inundação.
///
/// São subrotas do fluxo guiado (`/home`), portanto os caminhos são
/// relativos; o composition root (`app/router/app_router.dart`) as injeta
/// via `children` para preservar os deep links existentes.
final inundacaoRoutes = <RouteBase>[
  GoRoute(
    path: 'irrigation/basin-project',
    builder: (context, state) => const BasinProjectScreen(),
  ),
  GoRoute(
    path: 'irrigation/basin-results',
    builder: (context, state) => const BasinResultsScreen(),
  ),
  GoRoute(
    path: 'irrigation/basin-reference',
    builder: (context, state) => const BasinReferenceScreen(),
  ),
];
