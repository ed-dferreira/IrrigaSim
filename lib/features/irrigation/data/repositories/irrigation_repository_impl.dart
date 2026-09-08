import '../../domain/repositories/irrigation_repository.dart';
import '../datasources/local/simulacoes_local_datasource.dart';
import '../datasources/remote/firestore_datasource.dart';
import '../models/cenario_salvo.dart';

class IrrigationRepositoryImpl implements IrrigationRepository {
  final SimulacoesLocalDatasource _local;
  final FirestoreDatasource? _remote;

  IrrigationRepositoryImpl(this._local, {this._remote});

  @override
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

  @override
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

  @override
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

  @override
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

  @override
  Stream<List<CenarioSalvo>> observar() {
    if (_remote != null) {
      return _remote.observar();
    }
    return _local.observar();
  }
}
