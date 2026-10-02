import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/views/irrigation/sulcos/project_screen.dart';

void main() {
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
    final revisao = find.descendant(of: scroll, matching: find.text('Revisão'));
    expect(revisao, findsOneWidget);
    expect(tester.getTopLeft(revisao).dx, greaterThanOrEqualTo(0));
    expect(tester.getTopRight(revisao).dx, lessThanOrEqualTo(800));
  });
}
