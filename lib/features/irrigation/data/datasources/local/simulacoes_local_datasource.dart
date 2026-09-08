import 'dart:async';
import '../../models/cenario_salvo.dart';

class SimulacoesLocalDatasource {
  final List<CenarioSalvo> _cenarios = [];
  final _controller = StreamController<List<CenarioSalvo>>.broadcast();

  Future<List<CenarioSalvo>> listar() async =>
      List.unmodifiable(_cenarios);

  Future<void> salvar(CenarioSalvo cenario) async {
    final index = _cenarios.indexWhere((c) => c.id == cenario.id);
    if (index >= 0) {
      _cenarios[index] = cenario;
    } else {
      _cenarios.add(cenario);
    }
    _controller.add(List.unmodifiable(_cenarios));
  }

  Future<CenarioSalvo?> buscarPorId(String id) async {
    try {
      return _cenarios.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> excluir(String id) async {
    _cenarios.removeWhere((c) => c.id == id);
    _controller.add(List.unmodifiable(_cenarios));
  }

  Stream<List<CenarioSalvo>> observar() => _controller.stream;

  void dispose() {
    _controller.close();
  }
}
