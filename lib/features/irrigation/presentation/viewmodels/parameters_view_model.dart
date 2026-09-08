import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/domain/entities/simulation_result.dart';
import 'package:irrigasim/features/irrigation/domain/use_cases/run_border_simulation.dart';
import 'package:irrigasim/features/irrigation/domain/use_cases/run_furrow_simulation.dart';
import 'package:irrigasim/features/irrigation/domain/use_cases/run_basin_simulation.dart';

class ParametersState {
  final MetodoIrrigacao metodo;
  final double comprimento;
  final double desnivelM;
  final double distanciaHorizontalM;
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
    this.desnivelM = 0.2,
    this.distanciaHorizontalM = 100,
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

  double get declividade =>
      distanciaHorizontalM > 0 ? (desnivelM / distanciaHorizontalM) * 100 : 0;

  ParametersState copyWith({
    MetodoIrrigacao? metodo,
    double? comprimento,
    double? desnivelM,
    double? distanciaHorizontalM,
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
      desnivelM: desnivelM ?? this.desnivelM,
      distanciaHorizontalM: distanciaHorizontalM ?? this.distanciaHorizontalM,
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
      declividade: declividade / 100, // Converter de % para m/m
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

  void loadFromParams(IrrigationParameters params) {
    // declividade is in m/m; convert to desnivelM/distanciaHorizontalM pair
    final distancia = 100.0;
    final desnivel = params.declividade * distancia;
    state = state.copyWith(
      comprimento: params.comprimento,
      desnivelM: desnivel,
      distanciaHorizontalM: distancia,
      larguraOuEspacamento: params.larguraOuEspacamento,
      k: params.k,
      a: params.a,
      vib: params.vib,
      vazao: params.vazao,
      tempoAplicacao: params.tempoAplicacao,
      laminaRequerida: params.laminaRequerida,
      manningN: params.manningN,
      sigmaZ: params.sigmaZ,
    );
  }

  void updateField({String? campo, String? valor}) {
    if (campo == null || valor == null) return;
    final parsed = double.tryParse(valor.replaceAll(',', '.'));
    if (parsed == null) return;

    switch (campo) {
      case 'comprimento':
        state = state.copyWith(comprimento: parsed);
      case 'desnivelM':
        state = state.copyWith(desnivelM: parsed);
      case 'distanciaHorizontalM':
        state = state.copyWith(distanciaHorizontalM: parsed);
      case 'larguraOuEspacamento':
        state = state.copyWith(larguraOuEspacamento: parsed);
      case 'k':
        state = state.copyWith(k: parsed);
      case 'a':
        state = state.copyWith(a: parsed);
      case 'vib':
        state = state.copyWith(vib: parsed);
      case 'vazao':
        state = state.copyWith(vazao: parsed);
      case 'tempoAplicacao':
        state = state.copyWith(tempoAplicacao: parsed);
      case 'laminaRequerida':
        state = state.copyWith(laminaRequerida: parsed);
      case 'manningN':
        state = state.copyWith(manningN: parsed);
      case 'sigmaZ':
        state = state.copyWith(sigmaZ: parsed);
    }
  }

  double calcularDeclividade() {
    return state.declividade;
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
    StateNotifierProvider.autoDispose<ParametersViewModel, ParametersState>(
        (ref) {
  return ParametersViewModel();
});
