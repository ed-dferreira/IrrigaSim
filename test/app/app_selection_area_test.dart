import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'SelectionArea no builder encontra Overlay ao iniciar seleção por toque',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder:
              (context, child) => Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder:
                        (context) => SelectionArea(
                          child: child ?? const SizedBox.shrink(),
                        ),
                  ),
                ],
              ),
          home: Scaffold(
            body: const Center(
              child: Text('texto selecionável para teste'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('texto selecionável para teste'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('texto selecionável para teste'), findsOneWidget);
    },
  );
}
