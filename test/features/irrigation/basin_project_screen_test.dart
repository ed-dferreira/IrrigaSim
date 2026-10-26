// Wizard de inundação (revisão das Fases 0–6): as etapas 1–9 distribuem os
// campos do plano, o campo calculado I(t) reage ao tempo de contato e a
// revisão traz o painel didático (pp. 16, 17 e 38) com G3.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/basin_reference_math.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_project_screen.dart';

void main() {
  Future<void> abrirEtapa(
    WidgetTester tester,
    int numero,
    String titulo,
  ) async {
    final indicador = find.text('$numero. $titulo');
    await tester.ensureVisible(indicador);
    await tester.pumpAndSettle();
    await tester.tap(indicador);
    await tester.pumpAndSettle();
    expect(find.text(titulo), findsOneWidget);
  }

  testWidgets('campos ficam nas etapas certas do wizard', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BasinProjectScreen())),
    );
    expect(find.text('Projeto de inundação'), findsOneWidget);
    expect(find.text('1. Regime'), findsOneWidget);
    expect(find.text('9. Revisão'), findsOneWidget);
    expect(find.textContaining('Cenário de infiltração ativo'), findsNothing);

    await abrirEtapa(tester, 2, 'Área e geometria');
    expect(find.text('Textura do solo'), findsOneWidget);
    expect(find.text('Cultura (opcional)'), findsNothing);
    expect(find.text('Evapotranspiração do intervalo (ETc)'), findsNothing);
    expect(find.text('Lâmina inicial Li (opcional)'), findsOneWidget);
    expect(find.text('Lâmina final Lf (opcional)'), findsOneWidget);
    expect(find.text('Sugestão de área × vazão (p. 16)'), findsOneWidget);
    expect(find.text('Vazão disponível na fonte'), findsNothing);

    await abrirEtapa(tester, 3, 'Tabuleiro e taipa');
    expect(find.text('Altura da taipa'), findsOneWidget);
    expect(find.text('Base da taipa'), findsOneWidget);
    expect(find.text('Vazão disponível na fonte'), findsNothing);

    await abrirEtapa(tester, 4, 'Solo e infiltração');
    expect(find.text('Tempo de contato t'), findsOneWidget);
    expect(find.text('Infiltração acumulada I(t)'), findsOneWidget);
    expect(find.text('Lâmina requerida (IRN)'), findsNothing); // etapa 6
    expect(find.textContaining('pp. 53'), findsOneWidget);
    expect(find.text('Primeira irrigação'), findsOneWidget);

    await abrirEtapa(tester, 5, 'Cultura e sistema radicular');
    expect(find.text('Predefinição de cultura'), findsOneWidget);
    expect(find.text('Coeficiente da cultura (Kc)'), findsOneWidget);
    expect(find.text('Profundidade do sistema radicular (z)'), findsOneWidget);
    expect(find.text('Umidade na capacidade de campo (UCC)'), findsOneWidget);
    expect(find.text('Vazão disponível na fonte'), findsNothing);
    // Preset Aula 8 (G16): insumos de solo/planta persistem na tela.
    final uccField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('uccPercentual')),
        matching: find.byType(EditableText),
      ),
    );
    expect(uccField.controller.text, '30,0');

    await abrirEtapa(tester, 6, 'Clima e demanda');
    expect(find.text('ETc adotada'), findsOneWidget); // chip do método
    expect(find.text('Evapotranspiração do intervalo (ETc)'), findsOneWidget);
    expect(find.text('Origem da precipitação'), findsOneWidget);
    expect(find.text('Origem da IRN'), findsOneWidget);
    expect(find.text('Lâmina requerida (IRN)'), findsOneWidget);
    expect(find.textContaining('Demanda e IRN'), findsOneWidget); // (p. 63)
    // Preset Aula 8 (G16): a IRN informada de 56 mm aparece intacta.
    final irnField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('laminaRequeridaMm')),
        matching: find.byType(EditableText),
      ),
    );
    expect(irnField.controller.text, '56,0');

    await abrirEtapa(tester, 7, 'Operação');
    expect(find.text('Vazão disponível na fonte'), findsOneWidget);
    expect(find.text('Lâmina requerida (IRN)'), findsNothing);
    expect(find.text('Expoente r inicial'), findsOneWidget);
    expect(find.textContaining('Saldo de vazão'), findsOneWidget);
    expect(find.textContaining('m³/(min·m)'), findsOneWidget);
    expect(find.text('Checagem operacional (G3)'), findsOneWidget);
    expect(find.text('Viável'), findsOneWidget);

    await abrirEtapa(tester, 8, 'Planejamento');
    expect(find.text('Auditoria F02'), findsNothing); // está em ExpansionTile
    expect(find.textContaining('Auditoria F02'), findsOneWidget);
    expect(find.text('Checagem operacional (G3)'), findsNothing); // G3 na 7
    expect(find.textContaining('Volumes do arroz'), findsNothing);
    expect(find.textContaining('Densidade do solo seco'), findsNothing);

    await abrirEtapa(tester, 9, 'Revisão');
    expect(find.text('Guia de área por vazão (p. 16)'), findsOneWidget);
    expect(find.text('Henderson (p. 17)'), findsOneWidget);
    expect(find.text('Sifões e tubos de Booher (p. 38)'), findsOneWidget);
    expect(find.text('Expoente r inicial'), findsOneWidget);
    expect(find.text('Clima e demanda (p. 63)'), findsOneWidget); // seção nova
    expect(find.text('Cultura e sistema radicular (p. 63)'), findsOneWidget);
    // Confirmação obrigatória: sem as 8 etapas confirmadas o cálculo não abre.
    expect(find.textContaining('Confirme as etapas pendentes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('I(t) é recalculada quando o tempo de contato muda', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BasinProjectScreen())),
    );
    await abrirEtapa(tester, 4, 'Solo e infiltração');

    final projeto = Infiltracao(0.0035, 0.47, 0.00011).acumulada(60) * 1000;
    final texto = projeto == projeto.roundToDouble()
        ? '${projeto.toInt()} mm'
        : '$projeto mm';

    await tester.ensureVisible(
      find.byKey(const ValueKey('tempoInfiltracaoMin')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('tempoInfiltracaoMin')),
      '60',
    );
    await tester.pumpAndSettle();

    expect(find.text(texto), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Confirmar e Próximo ficam à direita, Voltar à esquerda', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BasinProjectScreen())),
    );

    expect(find.text('Voltar'), findsNothing);
    await tester.ensureVisible(find.text('Confirmar'));
    await tester.pumpAndSettle();
    final confirmar = tester.getCenter(find.text('Confirmar'));
    final proximo = tester.getCenter(find.text('Próximo'));
    expect(confirmar.dx, greaterThan(400));
    expect(proximo.dx, greaterThan(confirmar.dx));

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmada'), findsOneWidget);
    expect(find.text('Confirmar'), findsNothing);

    await abrirEtapa(tester, 2, 'Área e geometria');
    final voltar = tester.getCenter(find.text('Voltar'));
    final confirmar2 = tester.getCenter(find.text('Confirmar'));
    expect(voltar.dx, lessThan(200));
    expect(confirmar2.dx, greaterThan(400));

    await tester.ensureVisible(find.text('Voltar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Regime'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permanente planeja TR/Qe/Qm sem campos de arroz', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BasinProjectScreen())),
    );
    await tester.ensureVisible(find.text('Permanente (com circulação)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Permanente (com circulação)'));
    await tester.pumpAndSettle();

    // G8: no contínuo não existe IRN intermitente; o TR sai da camada.
    await abrirEtapa(tester, 6, 'Clima e demanda');
    expect(find.text('Origem da IRN'), findsNothing);
    expect(find.text('Lâmina requerida (IRN)'), findsNothing);
    expect(find.textContaining('TR = DTA · Z · f / ETc'), findsOneWidget);

    await abrirEtapa(tester, 8, 'Planejamento');
    expect(find.textContaining('TR (turno de rega)'), findsOneWidget);
    expect(find.textContaining('Qe (enchimento)'), findsOneWidget);
    expect(find.textContaining('Qm (manutenção)'), findsOneWidget);
    expect(find.textContaining('Densidade do solo seco'), findsNothing);
    expect(find.textContaining('Volumes do arroz'), findsNothing);

    await abrirEtapa(tester, 9, 'Revisão');
    expect(find.textContaining('Volumes do arroz'), findsNothing);
    expect(find.textContaining('TR (turno de rega)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cenário troca para terceira irrigação e recarrega k (p. 63)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BasinProjectScreen())),
    );
    await abrirEtapa(tester, 4, 'Solo e infiltração');
    expect(find.text('Primeira irrigação'), findsOneWidget);
    expect(find.text('Terceira irrigação'), findsNothing);

    await tester.ensureVisible(find.text('Primeira irrigação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Primeira irrigação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terceira irrigação'));
    await tester.pumpAndSettle();

    expect(find.text('Terceira irrigação'), findsOneWidget);
    final kField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('k-0-terceira')),
        matching: find.byType(EditableText),
      ),
    );
    expect(kField.controller.text, '0,0034');
    expect(tester.takeException(), isNull);
  });
}
