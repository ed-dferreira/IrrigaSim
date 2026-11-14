import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/router/app_routes.dart';

import 'content/manual_operacao.dart';
import 'views/artigo_tutorial_screen.dart';
import 'views/tutorial_screen.dart';

/// Localização completa de um artigo do tutorial.
String localizacaoArtigoTutorial(String id) => '${AppRoutes.tutorial}/$id';

/// Rotas da feature de tutorial.
///
/// São subrotas da rota do Perfil (`/perfil`), portanto os caminhos são
/// relativos; o composition root as injeta via `children`.
final tutorialRoutes = <RouteBase>[
  GoRoute(
    path: 'tutorial',
    builder: (context, state) => const TutorialScreen(),
    routes: [
      GoRoute(
        path: ':artigoId',
        builder: (context, state) => ArtigoTutorialScreen(
          artigo: buscarArtigoTutorial(state.pathParameters['artigoId'] ?? ''),
        ),
      ),
    ],
  ),
];
