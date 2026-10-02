import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/faixas/border_result.dart';
import 'package:irrigasim/services/cenarios/scenario_service.dart';
import 'package:irrigasim/services/persistence/local_scenario_store.dart';
import 'package:irrigasim/viewmodels/cenarios/scenario_providers.dart';
import 'package:irrigasim/viewmodels/faixas/border_project_controller.dart';
import 'package:irrigasim/views/irrigation/faixas/border_results_screen.dart';
import 'package:irrigasim/services/simulation/faixas/border_csv.dart';

void main() {
  test('os oito status canônicos têm texto e ícone próprios na tela', () {
    for (final status in BorderStatus.values) {
      final texto = textoStatusBorder(status);
      expect(texto, isNotEmpty);
    }
    expect(
      textoStatusBorder(BorderStatus.validoNoModelo),
      isNot(textoStatusBorder(BorderStatus.avisoOrientativo)),
    );
    // Só os dois primeiros são aceitos sem ressalva bloqueante.
    expect(BorderStatus.validoNoModelo.bloqueia, isFalse);
    expect(BorderStatus.avisoOrientativo.bloqueia, isFalse);
    expect(
      BorderStatus.values.where((s) => s.bloqueia).length,
      BorderStatus.values.length - 2,
    );
    expect(
      textoStatusBorder(BorderStatus.foraDoDominio),
      contains('fora do domínio'),
    );
    expect(
      textoStatusBorder(BorderStatus.semConvergencia),
      contains('convergência'),
    );
    expect(
      textoStatusBorder(BorderStatus.dadoFonteSuspeito),
      contains('suspeito'),
    );
    expect(
      textoStatusBorder(BorderStatus.modeloNaoImplementado),
      contains('não implementa'),
    );
    expect(
      textoStatusBorder(BorderStatus.balancoInconsistente),
      contains('Balanço'),
    );
    expect(
      textoStatusBorder(BorderStatus.entradaInvalida),
      contains('pendente'),
    );
    // Ícone de bloqueio distinto de sucesso e de atenção.
    expect(
      iconeStatusBorder(BorderStatus.validoNoModelo),
      isNot(iconeStatusBorder(BorderStatus.avisoOrientativo)),
    );
    expect(
      iconeStatusBorder(BorderStatus.foraDoDominio),
      isNot(iconeStatusBorder(BorderStatus.avisoOrientativo)),
    );
    // Nomes legados continuam legíveis.
    expect(BorderStatus.deNome('calculado'), BorderStatus.validoNoModelo);
    expect(
      BorderStatus.deNome('geometriaIncompativel'),
      BorderStatus.foraDoDominio,
    );
    expect(
      BorderStatus.deNome('geometriaPendente'),
      BorderStatus.entradaInvalida,
    );
    expect(
      BorderStatus.deNome('aviso_orientativo'),
      BorderStatus.avisoOrientativo,
    );
    expect(BorderStatus.deNome(null), BorderStatus.validoNoModelo);
  });

  testWidgets(
    'resultado próprio de faixa apresenta hipóteses e gera CSV tipado',
    (tester) async {
      final result = calcularProjetoFaixa(BorderProject.ilustrativo);
      final store = LocalScenarioStore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            borderProjectResultProvider.overrideWith((ref) => result),
            scenarioServiceProvider.overrideWithValue(
              ScenarioService(store, null),
            ),
          ],
          child: const MaterialApp(home: BorderResultsScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Indicadores principais'), findsOneWidget);
      expect(find.text('Eficiência Ea'), findsOneWidget);
      expect(find.text('Comprimento atendido Xa'), findsOneWidget);
      expect(find.text('Perfil amostrado'), findsOneWidget);
      expect(find.text('Distribuição das faixas na área'), findsOneWidget);
      final tabInflitracao = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Gráfico de Infiltração',
      );
      await tester.tap(tabInflitracao);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Semantics>(tabInflitracao).properties.selected,
        isTrue,
      );
      expect(find.text('Infiltração e IRN'), findsOneWidget);
      expect(find.text('Dados e hipóteses'), findsOneWidget);
      expect(find.textContaining('(entrada_invalida)'), findsWidgets);
      expect(find.textContaining('faixas-F01-F32-p43-v2'), findsOneWidget);
      expect(find.textContaining('Núcleo numérico'), findsWidgets);
      expect(find.textContaining('F07'), findsWidgets);
      expect(find.textContaining('L/s/m'), findsWidgets);
      expect(find.textContaining('Ea=Lf/Lm'), findsNothing);
      final r = result.borderResult!;
      final csv = borderCsv(BorderProject.ilustrativo, r);
      expect(csv, contains('versao_equacoes'));
      expect(csv, contains('q0;3.33;L/s/m'));
      // Selo de escopo real (F01–F32) e status canônico.
      expect(csv, contains('faixas-F01-F32-p43-v2'));
      expect(csv, contains('status;${r.status.codigo};'));
      // Grupo numérico declarado nas linhas do CSV.
      expect(csv, contains('num_tolerancia_passo;1e-10;'));
      expect(csv, contains('num_tolerancia_residuo;1e-12;'));
      expect(csv, contains('num_max_iteracoes;250;'));
      expect(csv, contains('num_n_segmentos;2000;pontos'));
      expect(csv, contains('num_versao_expoentes;p43;'));
      expect(csv, contains('num_metodo_integracao;trapezios_cruzamento_irn;'));
      // Proveniência por bloco e por fórmula com página, versão e origem.
      expect(csv, contains('bloco;F01–F05'));
      expect(csv, contains('formula_F07;'));
      expect(csv, contains('p. 53 · única · derivada'));
      expect(csv, contains('derivada'));
      expect(csv, contains('· medida'));
      expect(csv, contains('· assumida'));
      // Avisos saem com código e página.
      expect(csv, contains('[aviso_orientativo]'));
      expect(csv, contains('[entrada_invalida]'));
      store.dispose();
    },
  );
}
