import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/core/navigation/main_shell.dart';
import 'package:irrigasim/features/tutorial/routes.dart';

GoRouter routerPara(String localizacao) {
  return GoRouter(
    initialLocation: localizacao,
    routes: [
      GoRoute(
        path: '/perfil',
        builder: (_, _) => const Scaffold(),
        routes: tutorialRoutes,
      ),
      GoRoute(
        path: '/home/irrigation/tipo-sulco',
        builder: (_, _) => const Scaffold(body: Text('Tela de tipo de sulco')),
      ),
    ],
  );
}

void main() {
  testWidgets('artigo de sulcos mostra seções e abre atalho', (tester) async {
    final router = routerPara('/perfil/tutorial/sulcos');
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Sulcos'), findsOneWidget);
    expect(find.textContaining('tipo de sulco'), findsWidgets);

    final atalho = find.text('Abrir tipo de sulco');
    await tester.ensureVisible(atalho);
    await tester.tap(atalho);
    await tester.pumpAndSettle();

    expect(find.text('Tela de tipo de sulco'), findsOneWidget);
  });

  testWidgets('artigo inexistente mostra fallback e volta ao índice', (
    tester,
  ) async {
    final router = routerPara('/perfil/tutorial/inexistente');
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Artigo não encontrado'), findsOneWidget);

    await tester.tap(find.text('Voltar ao tutorial'));
    await tester.pumpAndSettle();

    expect(find.text('Tutorial e ajuda'), findsOneWidget);
    expect(find.text('Visão geral do app'), findsOneWidget);
  });

  testWidgets('atalho troca para a branch da tela de destino', (tester) async {
    final router = GoRouter(
      initialLocation: '/perfil/tutorial/sulcos',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/perfil',
                  builder: (_, _) => const Scaffold(),
                  routes: tutorialRoutes,
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (_, _) => const Scaffold(body: Text('Raiz Home')),
                  routes: [
                    GoRoute(
                      path: 'irrigation/tipo-sulco',
                      builder: (_, _) =>
                          const Scaffold(body: Text('Tela de tipo de sulco')),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );

    final atalho = find.text('Abrir tipo de sulco');
    await tester.ensureVisible(atalho);
    await tester.tap(atalho);
    await tester.pumpAndSettle();

    expect(find.text('Tela de tipo de sulco'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
  });
}
