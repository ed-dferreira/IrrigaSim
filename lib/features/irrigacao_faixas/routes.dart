import 'package:go_router/go_router.dart';

import 'views/border_project_screen.dart';
import 'views/border_results_screen.dart';

/// Rotas da feature de irrigação por faixas.
///
/// São subrotas do fluxo guiado (`/home`), portanto os caminhos são
/// relativos; o composition root (`app/router/app_router.dart`) as injeta
/// via `children` para preservar os deep links existentes.
final faixasRoutes = <RouteBase>[
  GoRoute(
    path: 'irrigation/border-project',
    builder: (context, state) => const BorderProjectScreen(),
  ),
  GoRoute(
    path: 'irrigation/border-results',
    builder: (context, state) => const BorderResultsScreen(),
  ),
];
