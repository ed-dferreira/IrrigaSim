import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/views/irrigation/sulcos/project_screen.dart';

void main() {
  testWidgets('geometria e opção Criddle não extrapolam em tela estreita', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProjectScreen())),
    );
    await tester.pumpAndSettle();
    final criddle = find.text('Dimensionar por Criddle');
    await tester.ensureVisible(criddle);
    await tester.pumpAndSettle();
    await tester.tap(criddle);
    await tester.pumpAndSettle();
    for (var step = 0; step < 3; step++) {
      final next = find.text('Próximo');
      if (next.evaluate().isEmpty) break;
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    final blaney = find.text('Blaney–Criddle');
    await tester.ensureVisible(blaney);
    await tester.pumpAndSettle();
    await tester.tap(blaney);
    await tester.pumpAndSettle();

    final temperatura = find.byType(TextFormField).at(0);
    await tester.ensureVisible(temperatura);
    await tester.enterText(temperatura, '25');
    final latitude = find.byType(TextFormField).at(1);
    await tester.ensureVisible(latitude);
    await tester.enterText(latitude, '-23.5');
    final mes = find.byType(DropdownButtonFormField<int>);
    await tester.ensureVisible(mes);
    await tester.tap(mes);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Janeiro').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('etapas do projeto podem ser percorridas no computador', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProjectScreen())),
    );
    await tester.pumpAndSettle();

    final scroll = find.byType(SingleChildScrollView).first;
    final controller = tester.widget<SingleChildScrollView>(scroll).controller!;
    expect(controller.offset, 0);
    await tester.tap(find.byTooltip('Ver próximas etapas'));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));

    await tester.tap(find.text('Pular para revisão'));
    await tester.pumpAndSettle();
    final revisao = find.descendant(
      of: scroll,
      matching: find.text('7. Revisão'),
    );
    expect(revisao, findsOneWidget);
    expect(tester.getTopLeft(revisao).dx, greaterThanOrEqualTo(0));
    expect(tester.getTopRight(revisao).dx, lessThanOrEqualTo(800));
  });
}
