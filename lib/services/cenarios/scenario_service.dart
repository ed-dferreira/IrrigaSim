import '../../models/cenarios/cenario_salvo.dart';
import '../persistence/firestore_scenario_store.dart';
import '../persistence/local_scenario_store.dart';

class ScenarioService {
  final LocalScenarioStore _local;
  final FirestoreScenarioStore? _remote;

  ScenarioService(this._local, [this._remote]);

  Future<List<CenarioSalvo>> listar() async {
    if (_remote != null) {
      try {
        final cenarios = await _remote.listar();
        for (final cenario in cenarios) {
          await _local.salvar(cenario);
        }
        return cenarios;
      } catch (_) {
        return _local.listar();
      }
    }
    return _local.listar();
  }

  Future<void> salvar(CenarioSalvo cenario) async {
    await _local.salvar(cenario);
    if (_remote != null) {
      try {
        await _remote.salvar(cenario);
      } catch (_) {
        // Offline: dados salvos localmente
      }
    }
  }

  Future<CenarioSalvo?> buscarPorId(String id) async {
    if (_remote != null) {
      try {
        final cenario = await _remote.buscarPorId(id);
        if (cenario != null) await _local.salvar(cenario);
        return cenario;
      } catch (_) {
        return _local.buscarPorId(id);
      }
    }
    return _local.buscarPorId(id);
  }

  Future<void> excluir(String id) async {
    await _local.excluir(id);
    if (_remote != null) {
      try {
        await _remote.excluir(id);
      } catch (_) {
        // Offline: dados removidos localmente
      }
    }
  }

  Stream<List<CenarioSalvo>> observar() {
    if (_remote != null) {
      return _remote.observar();
    }
    return _local.observar();
  }
}
