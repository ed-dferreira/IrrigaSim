import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/features/tutorial/content/manual_operacao.dart';
import 'package:irrigasim/features/tutorial/models/artigo_tutorial.dart';
import 'package:irrigasim/features/tutorial/routes.dart';

void main() {
  test('localização do artigo usa o caminho do tutorial', () {
    expect(localizacaoArtigoTutorial('sulcos'), '/perfil/tutorial/sulcos');
  });

  testWidgets('índice lista categorias e artigos', (tester) async {
    final router = GoRouter(
      initialLocation: '/perfil/tutorial',
      routes: [
        GoRoute(
          path: '/perfil',
          builder: (_, _) => const Scaffold(),
          routes: tutorialRoutes,
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Tutorial e ajuda'), findsOneWidget);
    for (final categoria in CategoriaTutorial.values) {
      expect(find.text(categoria.titulo), findsWidgets, reason: categoria.name);
    }
    for (final artigo in manualOperacao) {
      expect(find.text(artigo.titulo), findsWidgets, reason: artigo.id);
    }
  });

  testWidgets('tocar em um artigo do índice abre o artigo', (tester) async {
    final router = GoRouter(
      initialLocation: '/perfil/tutorial',
      routes: [
        GoRoute(
          path: '/perfil',
          builder: (_, _) => const Scaffold(),
          routes: tutorialRoutes,
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final sulcos = find.text('Sulcos');
    await tester.ensureVisible(sulcos);
    await tester.tap(sulcos);
    await tester.pumpAndSettle();

    expect(find.text('Escolha o tipo de sulco'), findsOneWidget);
  });
}
