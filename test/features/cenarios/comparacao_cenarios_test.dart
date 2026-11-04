import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:irrigasim/app/codecs.dart';
import 'package:irrigasim/features/cenarios/services/cenarios_exemplo.dart';
import 'package:irrigasim/features/cenarios/views/comparacao_cenarios.dart';

void main() {
  setUpAll(registrarCodecs);

  testWidgets('a comparação oferece as abas de gráficos comparativos', (
    tester,
  ) async {
    final sulcos =
        const CenariosDeExemplo()
            .gerar()
            .where((cenario) => cenario.metodo.name == 'sulco')
            .toList();

    await tester.pumpWidget(
      MaterialApp(home: ComparacaoCenariosView(cenarios: sulcos)),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // Abas de barras sempre presentes.
    expect(find.text('Desempenho'), findsOneWidget);
    expect(find.text('Balanço de água'), findsOneWidget);
    // Séries hidráulicas presentes quando os exemplos têm dados.
    expect(find.text('Avanço'), findsOneWidget);
    expect(find.text('Perfil de lâminas'), findsOneWidget);

    // A aba inicial (Desempenho) exibe um cenário na legenda e o eixo %.
    expect(find.text('%'), findsWidgets);
    expect(find.text('Exemplo Sulco · básico 1 L/s'), findsWidgets);
  });
}
