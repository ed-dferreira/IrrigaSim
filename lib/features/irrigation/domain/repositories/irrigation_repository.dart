import '../../data/models/cenario_salvo.dart';

abstract class IrrigationRepository {
  Future<List<CenarioSalvo>> listar();
  Future<void> salvar(CenarioSalvo cenario);
  Future<CenarioSalvo?> buscarPorId(String id);
  Future<void> excluir(String id);
  Stream<List<CenarioSalvo>> observar();
}
