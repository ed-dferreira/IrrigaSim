import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/domain/entities/simulation_result.dart';
import 'package:irrigasim/features/irrigation/domain/repositories/irrigation_repository.dart';
import 'package:irrigasim/features/irrigation/data/models/cenario_salvo.dart';
import 'package:irrigasim/features/irrigation/providers.dart';

class ResultsState {
  final int abaAtual;
  final String nomeCenario;
  final bool salvando;
  final String? erro;

  const ResultsState({
    this.abaAtual = 0,
    this.nomeCenario = '',
    this.salvando = false,
    this.erro,
  });

  ResultsState copyWith({
    int? abaAtual,
    String? nomeCenario,
    bool? salvando,
    String? erro,
    bool clearErro = false,
  }) {
    return ResultsState(
      abaAtual: abaAtual ?? this.abaAtual,
      nomeCenario: nomeCenario ?? this.nomeCenario,
      salvando: salvando ?? this.salvando,
      erro: clearErro ? null : (erro ?? this.erro),
    );
  }
}

class ResultsViewModel extends StateNotifier<ResultsState> {
  final IrrigationRepository _repository;

  ResultsViewModel(this._repository) : super(const ResultsState());

  void setAba(int index) {
    state = state.copyWith(abaAtual: index);
  }

  void setNomeCenario(String nome) {
    state = state.copyWith(nomeCenario: nome);
  }

  Future<void> salvarCenario({
    required MetodoIrrigacao metodo,
    required IrrigationParameters parametros,
    required SimulationResult resultado,
    String? usuarioId,
  }) async {
    state = state.copyWith(salvando: true, clearErro: true);
    try {
      final now = DateTime.now();
      final cenario = CenarioSalvo(
        id: const Uuid().v4(),
        nome: state.nomeCenario,
        metodo: metodo,
        parametros: parametros,
        resultado: resultado,
        dataCriacao: now,
        dataModificacao: now,
        usuarioId: usuarioId,
      );
      await _repository.salvar(cenario);
      state = state.copyWith(salvando: false);
    } catch (e) {
      state = state.copyWith(
        salvando: false,
        erro: 'Erro ao salvar cenário: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearErro: true);
  }
}

final resultsProvider =
    StateNotifierProvider<ResultsViewModel, ResultsState>((ref) {
  final repository = ref.watch(irrigationRepositoryProvider);
  return ResultsViewModel(repository);
});
