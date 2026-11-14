import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/router/app_routes.dart';
import 'package:irrigasim/core/navigation/main_shell.dart';
import 'package:irrigasim/features/perfil/routes.dart';
import 'package:irrigasim/features/perfil/services/preferencias_app.dart';
import 'package:irrigasim/features/tutorial/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('card do Perfil abre o tutorial', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await PreferenciasApp.init();

    final router = GoRouter(
      initialLocation: AppRoutes.perfil,
      routes: [perfilRoute(children: tutorialRoutes)],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    final abrir = find.text('Abrir tutorial');
    await tester.ensureVisible(abrir);
    await tester.tap(abrir);
    await tester.pumpAndSettle();

    expect(find.text('Tutorial e ajuda'), findsOneWidget);
    expect(find.text('Visão geral do app'), findsOneWidget);
  });

  testWidgets('abrir o tutorial mantém a branch do Perfil', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await PreferenciasApp.init();

    final router = GoRouter(
      initialLocation: AppRoutes.perfil,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (_, _) => const Scaffold(body: Text('Raiz Home')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [perfilRoute(children: tutorialRoutes)],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );

    final abrir = find.text('Abrir tutorial');
    await tester.ensureVisible(abrir);
    await tester.tap(abrir);
    await tester.pumpAndSettle();

    expect(find.text('Visão geral do app'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
  });
}
