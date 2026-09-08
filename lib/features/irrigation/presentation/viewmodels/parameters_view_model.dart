import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/domain/entities/simulation_result.dart';
import 'package:irrigasim/features/irrigation/domain/use_cases/run_border_simulation.dart';
import 'package:irrigasim/features/irrigation/domain/use_cases/run_furrow_simulation.dart';
import 'package:irrigasim/features/irrigation/domain/use_cases/run_basin_simulation.dart';

class ParametersState {
  final MetodoIrrigacao metodo;
  final double comprimento;
  final double declividade;
  final double larguraOuEspacamento;
  final double k;
  final double a;
  final double vib;
  final double vazao;
  final double tempoAplicacao;
  final double laminaRequerida;
  final double manningN;
  final double sigmaZ;
  final SimulationResult? resultado;
  final bool executando;
  final String? erro;

  const ParametersState({
    this.metodo = MetodoIrrigacao.sulco,
    this.comprimento = 100,
    this.declividade = 0.002,
    this.larguraOuEspacamento = 0.3,
    this.k = 0.005,
    this.a = 0.5,
    this.vib = 0.001,
    this.vazao = 2.0,
    this.tempoAplicacao = 120,
    this.laminaRequerida = 60,
    this.manningN = 0.015,
    this.sigmaZ = 0.4,
    this.resultado,
    this.executando = false,
    this.erro,
  });

  ParametersState copyWith({
    MetodoIrrigacao? metodo,
    double? comprimento,
    double? declividade,
    double? larguraOuEspacamento,
    double? k,
    double? a,
    double? vib,
    double? vazao,
    double? tempoAplicacao,
    double? laminaRequerida,
    double? manningN,
    double? sigmaZ,
    SimulationResult? resultado,
    bool? executando,
    String? erro,
  }) {
    return ParametersState(
      metodo: metodo ?? this.metodo,
      comprimento: comprimento ?? this.comprimento,
      declividade: declividade ?? this.declividade,
      larguraOuEspacamento: larguraOuEspacamento ?? this.larguraOuEspacamento,
      k: k ?? this.k,
      a: a ?? this.a,
      vib: vib ?? this.vib,
      vazao: vazao ?? this.vazao,
      tempoAplicacao: tempoAplicacao ?? this.tempoAplicacao,
      laminaRequerida: laminaRequerida ?? this.laminaRequerida,
      manningN: manningN ?? this.manningN,
      sigmaZ: sigmaZ ?? this.sigmaZ,
      resultado: resultado,
      executando: executando ?? this.executando,
      erro: erro,
    );
  }

  IrrigationParameters toIrrigationParameters() {
    return IrrigationParameters(
      comprimento: comprimento,
      declividade: declividade,
      larguraOuEspacamento: larguraOuEspacamento,
      k: k,
      a: a,
      vib: vib,
      vazao: vazao,
      tempoAplicacao: tempoAplicacao,
      laminaRequerida: laminaRequerida,
      manningN: manningN,
      sigmaZ: sigmaZ,
    );
  }
}

class ParametersViewModel extends StateNotifier<ParametersState> {
  ParametersViewModel() : super(const ParametersState());

  void setMetodo(MetodoIrrigacao metodo) {
    state = state.copyWith(metodo: metodo);
  }

  void updateField({String? campo, double? valor}) {
    if (campo == null || valor == null) return;
    switch (campo) {
      case 'comprimento':
        state = state.copyWith(comprimento: valor);
      case 'declividade':
        state = state.copyWith(declividade: valor);
      case 'larguraOuEspacamento':
        state = state.copyWith(larguraOuEspacamento: valor);
      case 'k':
        state = state.copyWith(k: valor);
      case 'a':
        state = state.copyWith(a: valor);
      case 'vib':
        state = state.copyWith(vib: valor);
      case 'vazao':
        state = state.copyWith(vazao: valor);
      case 'tempoAplicacao':
        state = state.copyWith(tempoAplicacao: valor);
      case 'laminaRequerida':
        state = state.copyWith(laminaRequerida: valor);
      case 'manningN':
        state = state.copyWith(manningN: valor);
      case 'sigmaZ':
        state = state.copyWith(sigmaZ: valor);
    }
  }

  Future<void> executarSimulacao() async {
    state = state.copyWith(executando: true, erro: null);
    try {
      final params = state.toIrrigationParameters();
      final resultado = switch (state.metodo) {
        MetodoIrrigacao.faixa => RunBorderSimulation()(params),
        MetodoIrrigacao.sulco => RunFurrowSimulation()(params),
        MetodoIrrigacao.inundacao => RunBasinSimulation()(params),
      };
      state = state.copyWith(resultado: resultado, executando: false);
    } catch (e) {
      state = state.copyWith(erro: e.toString(), executando: false);
    }
  }
}

final parametersProvider =
    StateNotifierProvider<ParametersViewModel, ParametersState>((ref) {
  return ParametersViewModel();
});
