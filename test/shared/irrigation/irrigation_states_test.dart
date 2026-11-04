import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_states.dart';

void main() {
  testWidgets('IrrigationEmptyResult apresenta ícone, textos e ação', (
    tester,
  ) async {
    var acionou = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IrrigationEmptyResult(
            icon: Icons.water_drop_outlined,
            title: 'Nenhum resultado disponível',
            message: 'Volte ao projeto para calcular a irrigação.',
            actionLabel: 'Voltar ao projeto',
            onAction: () => acionou = true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
    expect(find.text('Nenhum resultado disponível'), findsOneWidget);
    expect(find.text('Volte ao projeto para calcular a irrigação.'), findsOneWidget);

    await tester.tap(find.text('Voltar ao projeto'));
    expect(acionou, isTrue);
    expect(tester.takeException(), isNull);
  });
}
