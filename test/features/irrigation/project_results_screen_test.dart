import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/app/theme/app_theme.dart';
import 'package:irrigasim/models/cenarios/cenario_salvo.dart';
import 'package:irrigasim/models/sulcos/field_measurements.dart';
import 'package:irrigasim/models/sulcos/irrigation_project.dart';
import 'package:irrigasim/services/persistence/local_scenario_store.dart';
import 'package:irrigasim/services/cenarios/scenario_service.dart';
import 'package:irrigasim/viewmodels/cenarios/scenario_providers.dart';
import 'package:irrigasim/viewmodels/parameters_controller.dart';
import 'package:irrigasim/viewmodels/results_controller.dart';
import 'package:irrigasim/views/irrigation/sulcos/project_results_screen.dart';
import 'package:irrigasim/views/irrigation/sulcos/project_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'mostra resultados agrupados e exporta operação e séries com CSV consistente',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final parameters = ParametersController();
      parameters.setOrigemAvanco(OrigemAvanco.ensaio);
      parameters.setMetodoCurvaAvanco(MetodoCurvaAvanco.minimosQuadrados);
      parameters.setPontosEnsaioAvanco(const [
        PontoEnsaio(distanciaM: 0, tempoMin: 0),
        PontoEnsaio(distanciaM: 50, tempoMin: 20),
        PontoEnsaio(distanciaM: 100, tempoMin: 43),
        PontoEnsaio(distanciaM: 200, tempoMin: 95),
      ]);
      parameters.setOrigemCurvaInfiltracao(
        OrigemCurvaInfiltracao.ensaioEntradaSaida,
      );
      parameters.setMedicoesEntradaSaida(const [
        MedicaoEntradaSaida(tempoMin: 10, vazaoEntradaLs: 1, vazaoSaidaLs: .5),
        MedicaoEntradaSaida(tempoMin: 20, vazaoEntradaLs: 1, vazaoSaidaLs: .6),
        MedicaoEntradaSaida(tempoMin: 30, vazaoEntradaLs: 1, vazaoSaidaLs: .7),
      ]);
      await parameters.executarSimulacao();
      final store = LocalScenarioStore();
      addTearDown(store.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            parametersProvider.overrideWith((ref) => parameters),
            resultsProvider.overrideWith(
              (ref) => ResultsController(ScenarioService(store)),
            ),
            cenariosProvider.overrideWith(
              (ref) => Stream.value(<CenarioSalvo>[]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(fontScale: 1.35),
            home: const ProjectResultsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aplicação e desempenho'), findsOneWidget);
      expect(find.text('Avanço e infiltração'), findsOneWidget);
      expect(find.text('Equação acumulada ajustada'), findsOneWidget);
      await tester.ensureVisible(
        find.text('Planejamento operacional por parcela').first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Planejamento operacional por parcela'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Exportar dados'));
      await tester.pumpAndSettle();
      final csvWidget = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      final csv = csvWidget.data!;
      expect(csv, contains('planejamento operacional'));
      expect(csv, contains('tempo entre parcelas'));
      expect(csv, contains('entrada;origem avanço;ensaio;'));
      expect(csv, contains('Coeficiente acumulado ajustado'));
      expect(csv, contains('série avanço'));
      expect(csv, contains('ensaio avanço'));
      expect(
        csv.split('\n').every((row) => row.split(';').length == 4),
        isTrue,
      );
    },
  );

  testWidgets('mostra avanço estimado por k/b e coleta estacas uniformes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final parameters = ParametersController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [parametersProvider.overrideWith((ref) => parameters)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ProjectScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var step = 0; step < 5; step++) {
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Coeficiente k da curva'), findsOneWidget);
    expect(find.text('Expoente b da curva'), findsOneWidget);
    expect(find.text('Distância X alcançada pela frente'), findsOneWidget);

    await tester.tap(find.text('Ensaio de campo'));
    await tester.pumpAndSettle();
    expect(find.text('Número de estacas medidas'), findsOneWidget);
    expect(find.text('Distância entre estacas'), findsOneWidget);
    expect(find.textContaining('tempo (min)'), findsWidgets);

    await tester.tap(find.text('Dois pontos'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Se não houver estaca exatamente no meio'),
      findsOneWidget,
    );
    await tester.tap(find.text('Mínimos quadrados'));
    await tester.pumpAndSettle();
    expect(find.textContaining('regressão log-log'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
