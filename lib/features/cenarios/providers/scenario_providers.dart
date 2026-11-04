import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/local_scenario_store.dart';
import '../services/cenario_exportador.dart';
import '../services/cenarios_exemplo.dart';
import '../services/project_store.dart';
import '../services/scenario_service.dart';
import '../models/cenario_salvo.dart';

final localScenarioStoreProvider = Provider<LocalScenarioStore>((ref) {
  final store = LocalScenarioStore();
  ref.onDispose(store.dispose);
  return store;
});

final scenarioServiceProvider = Provider<ScenarioService>((ref) {
  final local = ref.watch(localScenarioStoreProvider);
  return ScenarioService(local);
});

final projectStoreProvider = Provider<ProjectStore>((ref) {
  final service = ref.watch(scenarioServiceProvider);
  return ProjectStore(
    listar: service.listar,
    salvar: service.salvar,
    buscarPorId: service.buscarPorId,
    excluir: service.excluir,
  );
});

final cenarioExportadorProvider = Provider<CenarioExportador>((ref) {
  return CenarioExportador(projectStore: ref.watch(projectStoreProvider));
});

final cenariosProvider = StreamProvider.autoDispose<List<CenarioSalvo>>((ref) async* {
  final service = ref.watch(scenarioServiceProvider);
  // Semeia cenários de exemplo (2 por método) na primeira execução com a
  // base vazia, para testar comparação/detalhes com dados completos.
  await ref.watch(semeadorDeExemplosProvider).semearUmaVez();
  yield* service.observar();
});

final semeadorDeExemplosProvider = Provider<SemeadorDeExemplos>((ref) {
  return SemeadorDeExemplos(ref.watch(scenarioServiceProvider));
});
