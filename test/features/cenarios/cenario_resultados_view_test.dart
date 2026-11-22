import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigasim/features/cenarios/controllers/salvar_cenario_controller.dart';
import 'package:irrigasim/features/cenarios/persistence/local_scenario_store.dart';
import 'package:irrigasim/features/cenarios/services/cenarios_exemplo.dart';
import 'package:irrigasim/features/cenarios/services/scenario_service.dart';
import 'package:irrigasim/features/cenarios/views/cenario_resultados_view.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'abre os resultados de um cenário de sulco sem alterar o provedor '
    'durante o build',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cenario = const CenariosDeExemplo().gerar().firstWhere(
        (c) => c.metodo == MetodoIrrigacao.sulco,
      );
      final store = LocalScenarioStore();
      addTearDown(store.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resultsProvider.overrideWith(
              (ref) => ResultsController(ScenarioService(store)),
            ),
          ],
          child: MaterialApp(home: CenarioResultadosView(cenario: cenario)),
        ),
      );
      // O estado de sulco é carregado no primeiro frame; os frames seguintes
      // exibem a tela de resultados (que tem animações contínuas, por isso
      // não usamos `pumpAndSettle`).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('Resultados do projeto'), findsOneWidget);
      expect(find.text('Execute o dimensionamento primeiro.'), findsNothing);
    },
  );
}
