import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/features/perfil/models/calculos_simulacao.dart';
import 'package:irrigasim/features/perfil/views/calculos_conteudo_section.dart';

void main() {
  Widget tela() => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: CalculosConteudoSection()),
    ),
  );

  testWidgets('seção lista os três métodos e a base comum', (tester) async {
    await tester.pumpWidget(tela());

    final metodos = CalculosSimulacao.modulos.map((m) => m.metodo);
    expect(metodos, ['Sulcos', 'Faixas', 'Inundação', 'Base comum']);
    expect(find.text('Sulcos'), findsOneWidget);
    expect(find.text('Faixas'), findsOneWidget);
    expect(find.text('Inundação'), findsOneWidget);
    expect(find.text('Base comum'), findsOneWidget);
  });

  testWidgets('expandir o método de inundação revela os cálculos', (
    tester,
  ) async {
    await tester.pumpWidget(tela());

    // Fechado por padrão: nada dos cálculos internos aparece.
    expect(find.text('IRN calculada'), findsNothing);

    await tester.tap(find.text('Inundação'));
    await tester.pumpAndSettle();

    expect(find.text('IRN calculada'), findsOneWidget);
    expect(find.text('Volumes de água do arroz'), findsOneWidget);
    // Fórmula visível no card do cálculo expandido.
    expect(find.textContaining('A = 100 · Q/VIB'), findsOneWidget);
    // Cálculo sem fórmula não renderiza a caixa de equação.
    expect(find.textContaining('Vazões de referência'), findsOneWidget);
  });

  testWidgets('expansão em série exibe as fórmulas de cada método', (
    tester,
  ) async {
    await tester.pumpWidget(tela());

    for (final metodo in const ['Sulcos', 'Faixas', 'Inundação']) {
      await tester.ensureVisible(find.text(metodo));
      await tester.pumpAndSettle();
      await tester.tap(find.text(metodo));
      await tester.pumpAndSettle();
    }

    expect(find.textContaining('Tx = k · xᵇ'), findsOneWidget);
    expect(find.textContaining('Q0·tx = 0,77·A0·L'), findsOneWidget);
    expect(find.textContaining('y0 = (Q0²·n²·X/3600)'), findsOneWidget);
  });

  test('cada módulo tem pelo menos um cálculo com título e descrição', () {
    for (final modulo in CalculosSimulacao.modulos) {
      expect(modulo.calculos, isNotEmpty, reason: modulo.metodo);
      for (final calculo in modulo.calculos) {
        expect(calculo.titulo.trim(), isNotEmpty, reason: modulo.metodo);
        expect(calculo.descricao.trim(), isNotEmpty, reason: modulo.metodo);
        final formula = calculo.formula;
        if (formula != null) {
          expect(formula.trim(), isNotEmpty, reason: calculo.titulo);
        }
      }
    }
    // A maioria dos cálculos expõe equação; os que não expõem são conceituais.
    final comFormula = [
      for (final modulo in CalculosSimulacao.modulos)
        for (final calculo in modulo.calculos)
          if (calculo.formula != null) calculo,
    ];
    expect(comFormula.length, greaterThan(20));
  });

  test('os cálculos não referenciam aula, slide nem página de origem', () {
    final origem = RegExp(
      r'aula\s+\d|slides?\s+\d|pp?\.\s*\d|\b[EF]\d{2}\b',
      caseSensitive: false,
    );
    for (final modulo in CalculosSimulacao.modulos) {
      final textos = [
        modulo.metodo,
        for (final calculo in modulo.calculos) ...[
          calculo.titulo,
          calculo.descricao,
        ],
      ];
      for (final texto in textos) {
        expect(
          origem.hasMatch(texto),
          isFalse,
          reason: 'referência de origem em: $texto',
        );
      }
    }
  });
}
