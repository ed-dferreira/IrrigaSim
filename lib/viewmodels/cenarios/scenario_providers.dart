import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/persistence/local_scenario_store.dart';
import '../../services/cenarios/scenario_service.dart';
import '../../models/cenarios/cenario_salvo.dart';

final localScenarioStoreProvider = Provider<LocalScenarioStore>((ref) {
  final store = LocalScenarioStore();
  ref.onDispose(store.dispose);
  return store;
});

final scenarioServiceProvider = Provider<ScenarioService>((ref) {
  final local = ref.watch(localScenarioStoreProvider);
  return ScenarioService(local);
});

final cenariosProvider = StreamProvider.autoDispose<List<CenarioSalvo>>((ref) {
  final service = ref.watch(scenarioServiceProvider);
  return service.observar();
});
