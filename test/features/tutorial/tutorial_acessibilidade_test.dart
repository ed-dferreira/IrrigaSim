import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/features/tutorial/routes.dart';

List<String> rotulosSemanticos(WidgetTester tester) {
  final root = tester
      .binding
      .renderViews
      .first
      .owner!
      .semanticsOwner!
      .rootSemanticsNode!;
  final rotulos = <String>[];
  void visit(SemanticsNode node) {
    if (node.label.isNotEmpty) rotulos.add(node.label);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return rotulos;
}

Widget appComEscala(GoRouter router) {
  return MaterialApp.router(
    routerConfig: router,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(2)),
      child: child ?? const SizedBox.shrink(),
    ),
  );
}

GoRouter routerPara(String localizacao) {
  return GoRouter(
    initialLocation: localizacao,
    routes: [
      GoRoute(
        path: '/perfil',
        builder: (_, _) => const Scaffold(),
        routes: tutorialRoutes,
      ),
    ],
  );
}

void main() {
  testWidgets('índice não estoura em 320 px com fonte 2x', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = routerPara('/perfil/tutorial');
    addTearDown(router.dispose);

    await tester.pumpWidget(appComEscala(router));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('artigo não estoura em 320 px com fonte 2x', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = routerPara('/perfil/tutorial/sulcos');
    addTearDown(router.dispose);

    await tester.pumpWidget(appComEscala(router));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sulcos'), findsOneWidget);
  });

  testWidgets('cards do índice não repetem o rótulo acessível', (tester) async {
    final semantics = tester.ensureSemantics();

    final router = routerPara('/perfil/tutorial');
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final rotulos = rotulosSemanticos(tester);
    expect(
      rotulos.where((rotulo) => rotulo == 'Métodos de irrigação'),
      hasLength(1),
    );
    expect(
      rotulos.where((rotulo) => rotulo.startsWith('Sulcos. ')),
      hasLength(1),
    );
    expect(rotulos.where((rotulo) => rotulo == 'Sulcos'), isEmpty);
    semantics.dispose();
  });

  testWidgets('seções e atalhos do artigo não repetem o rótulo', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    final router = routerPara('/perfil/tutorial/sulcos');
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final rotulos = rotulosSemanticos(tester);
    expect(
      rotulos.where((rotulo) => rotulo.startsWith('Escolha o tipo de sulco')),
      hasLength(1),
    );
    expect(
      rotulos.where(
        (rotulo) =>
            rotulo ==
            'Abrir tipo de sulco. Comece pela escolha do tipo de sulco.',
      ),
      hasLength(1),
    );
    semantics.dispose();
  });
}
