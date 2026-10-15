import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/views/home/home_screen.dart';
import 'package:irrigasim/views/irrigation/irrigation_screen.dart';
import 'package:irrigasim/views/irrigation/parameters_screen.dart';
import 'package:irrigasim/views/irrigation/faixas/border_project_screen.dart';
import 'package:irrigasim/views/irrigation/faixas/border_results_screen.dart';
import 'package:irrigasim/views/irrigation/inundacao/basin_project_screen.dart';
import 'package:irrigasim/views/irrigation/inundacao/basin_reference_screen.dart';
import 'package:irrigasim/views/irrigation/inundacao/basin_results_screen.dart';
import 'package:irrigasim/views/irrigation/sulcos/project_screen.dart';
import 'package:irrigasim/views/irrigation/sulcos/project_results_screen.dart';
import 'package:irrigasim/views/irrigation/results_screen.dart';
import 'package:irrigasim/views/irrigation/sulcos/tipo_sulco_screen.dart';
import 'package:irrigasim/views/cenarios/cenarios_screen.dart';
import 'package:irrigasim/views/tutorial/tutorial_screen.dart';
import 'package:irrigasim/views/perfil/perfil_screen.dart';
import 'package:irrigasim/core/navigation/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'irrigation',
                    builder: (context, state) => const IrrigationScreen(),
                  ),
                  GoRoute(
                    path: 'irrigation/tipo-sulco',
                    builder: (context, state) => const TipoSulcoScreen(),
                  ),
                  GoRoute(
                    path: 'irrigation/parameters',
                    builder: (context, state) => const ParametersScreen(),
                  ),
                  GoRoute(
                    path: 'irrigation/border-project',
                    builder: (context, state) => const BorderProjectScreen(),
                  ),
                  GoRoute(
                    path: 'irrigation/border-results',
                    builder: (context, state) => const BorderResultsScreen(),
                  ),
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
                  GoRoute(
                    path: 'irrigation/project',
                    builder: (context, state) => const ProjectScreen(),
                  ),
                  GoRoute(
                    path: 'irrigation/project-results',
                    builder: (context, state) => const ProjectResultsScreen(),
                  ),
                  GoRoute(
                    path: 'irrigation/results',
                    builder: (context, state) => const ResultsScreen(),
                  ),
                  GoRoute(
                    path: 'tutorial',
                    builder: (context, state) => const TutorialScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cenarios',
                builder: (context, state) => const CenariosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/perfil',
                builder: (context, state) => const PerfilScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
