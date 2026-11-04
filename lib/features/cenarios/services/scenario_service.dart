import '../models/cenario_salvo.dart';
import '../persistence/local_scenario_store.dart';

class ScenarioService {
  final LocalScenarioStore _local;

  ScenarioService(this._local);

  Future<List<CenarioSalvo>> listar() => _local.listar();

  Future<void> salvar(CenarioSalvo cenario) => _local.salvar(cenario);

  Future<CenarioSalvo?> buscarPorId(String id) => _local.buscarPorId(id);

  Future<void> excluir(String id) => _local.excluir(id);

  Stream<List<CenarioSalvo>> observar() => _local.observar();
}
