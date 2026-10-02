import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/views/irrigation/faixas/border_project_screen.dart';

void main() {
  testWidgets('projeto de faixas segue etapas agronômicas e hidráulicas', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BorderProjectScreen())),
    );
    expect(find.text('Projeto de faixas'), findsOneWidget);
    expect(find.textContaining('Dimensões do sulco'), findsNothing);
    expect(find.text('Área e geometria'), findsOneWidget);
    expect(find.text('2. Dimensões da faixa'), findsOneWidget);
    expect(find.text('3. Solo'), findsOneWidget);
    expect(find.text('4. Cultura e raízes'), findsOneWidget);
    expect(find.text('5. Clima e demanda'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -550));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar etapa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Próxima etapa'));
    await tester.pumpAndSettle();
    expect(find.text('Dimensões da faixa'), findsOneWidget);
    await tester.ensureVisible(find.text('Confirmar etapa'));
    await tester.tap(find.text('Confirmar etapa'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Próxima etapa'));
    await tester.tap(find.text('Próxima etapa'));
    await tester.pumpAndSettle();
    expect(find.text('Solo'), findsOneWidget);
    expect(find.textContaining('Tabela Booher'), findsOneWidget);
  });

  testWidgets('etapas de faixas cabem com texto ampliado', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const BorderProjectScreen(),
        ),
      ),
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar etapa'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Próxima etapa'));
    await tester.pumpAndSettle();
    expect(find.text('Dimensões da faixa'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar etapa'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Próxima etapa'));
    await tester.pumpAndSettle();
    expect(find.text('Solo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edição reabre confirmação e revisão mostra etapas pendentes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BorderProjectScreen())),
    );

    await tester.drag(find.byType(ListView).first, const Offset(0, -550));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar etapa'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmada'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('comprimentoAreaM')));
    await tester.enterText(
      find.byKey(const ValueKey('comprimentoAreaM')),
      '250',
    );
    await tester.pumpAndSettle();
    expect(find.text('Confirmada'), findsNothing);
    expect(find.text('Confirmar etapa'), findsOneWidget);

    await tester.ensureVisible(find.text('8. Revisão'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8. Revisão'));
    await tester.pumpAndSettle();
    expect(find.text('Solo e cultura'), findsOneWidget);
    expect(find.textContaining('Confirme as etapas pendentes'), findsOneWidget);
  });
}
