import 'package:go_router/go_router.dart';

import 'views/project_results_screen.dart';
import 'views/project_screen.dart';
import 'views/tipo_sulco_screen.dart';

/// Rotas da feature de irrigação por sulcos.
///
/// São subrotas do fluxo guiado (`/home`), portanto os caminhos são
/// relativos; o composition root (`app/router/app_router.dart`) as injeta
/// via `children` para preservar os deep links existentes.
final sulcosRoutes = <RouteBase>[
  GoRoute(
    path: 'irrigation/tipo-sulco',
    builder: (context, state) => const TipoSulcoScreen(),
  ),
  GoRoute(
    path: 'irrigation/project',
    builder: (context, state) => const ProjectScreen(),
  ),
  GoRoute(
    path: 'irrigation/project-results',
    builder: (context, state) => const ProjectResultsScreen(),
  ),
];
