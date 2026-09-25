import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/features/irrigation/models/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/models/simulation_result.dart';
import 'package:irrigasim/features/irrigation/services/simulation/run_border_simulation.dart';
import 'package:irrigasim/features/irrigation/services/simulation/run_furrow_simulation.dart';
import 'package:irrigasim/features/irrigation/services/simulation/run_basin_simulation.dart';
import 'package:irrigasim/features/irrigation/services/simulation/run_permanent_basin_simulation.dart';

class ParametersState {
  final MetodoIrrigacao metodo;
  final double comprimento;
  final double desnivelM;
  final double distanciaHorizontalM;
  final double desnivelTransversalM;
  final double distanciaTransversalM;
  final double larguraOuEspacamento;
  final double k;
  final double a;
  final double vib;
  final double vazao;
  final double tempoAplicacao;
  final double laminaRequerida;
  final double manningN;
  final double sigmaZ;
  final TexturaSolo texturaSolo;
  final double tempoAvancoMetadeMin;
  final double tempoAvancoFinalMin;
  final double instanteRecessaoInicioMin;
  final double instanteRecessaoFinalMin;
  final TipoInundacao tipoInundacao;
  final double areaHectares;
  final double porosidade;
  final double profundidadeCamadaMm;
  final double condutividadeHidraulicaMmDia;
  final double dtaMmCm;
  final double fatorDisponibilidade;
  final double evapotranspiracaoMmDia;
  final double laminaSuperficialMm;
  final double vazaoDisponivelLps;
  final SimulationResult? resultado;
  final bool executando;
  final String? erro;

  const ParametersState({
    this.metodo = MetodoIrrigacao.sulco,
    this.comprimento = 200,
    this.desnivelM = 1,
    this.distanciaHorizontalM = 200,
    this.desnivelTransversalM = 0,
    this.distanciaTransversalM = 10,
    this.larguraOuEspacamento = 0.9,
    this.k = 2.83,
    this.a = 0.554,
    this.vib = 0.0001,
    this.vazao = 1,
    this.tempoAplicacao = 130,
    this.laminaRequerida = 42,
    this.manningN = 0.015,
    this.sigmaZ = 0.4,
    this.texturaSolo = TexturaSolo.media,
    this.tempoAvancoMetadeMin = 35,
    this.tempoAvancoFinalMin = 90,
    this.instanteRecessaoInicioMin = 125,
    this.instanteRecessaoFinalMin = 180,
    this.tipoInundacao = TipoInundacao.intermitente,
    this.areaHectares = 2,
    this.porosidade = 0.5,
    this.profundidadeCamadaMm = 500,
    this.condutividadeHidraulicaMmDia = 7,
    this.dtaMmCm = 2,
    this.fatorDisponibilidade = 0.5,
    this.evapotranspiracaoMmDia = 7.2,
    this.laminaSuperficialMm = 150,
    this.vazaoDisponivelLps = 36,
    this.resultado,
    this.executando = false,
    this.erro,
  });

  double get declividade =>
      distanciaHorizontalM > 0 ? desnivelM / distanciaHorizontalM : 0;

  double get declividadeTransversal => distanciaTransversalM > 0
      ? desnivelTransversalM / distanciaTransversalM
      : 0;

  ParametersState copyWith({
    MetodoIrrigacao? metodo,
    double? comprimento,
    double? desnivelM,
    double? distanciaHorizontalM,
    double? desnivelTransversalM,
    double? distanciaTransversalM,
    double? larguraOuEspacamento,
    double? k,
    double? a,
    double? vib,
    double? vazao,
    double? tempoAplicacao,
    double? laminaRequerida,
    double? manningN,
    double? sigmaZ,
    TexturaSolo? texturaSolo,
    double? tempoAvancoMetadeMin,
    double? tempoAvancoFinalMin,
    double? instanteRecessaoInicioMin,
    double? instanteRecessaoFinalMin,
    TipoInundacao? tipoInundacao,
    double? areaHectares,
    double? porosidade,
    double? profundidadeCamadaMm,
    double? condutividadeHidraulicaMmDia,
    double? dtaMmCm,
    double? fatorDisponibilidade,
    double? evapotranspiracaoMmDia,
    double? laminaSuperficialMm,
    double? vazaoDisponivelLps,
    SimulationResult? resultado,
    bool? executando,
    String? erro,
  }) {
    return ParametersState(
      metodo: metodo ?? this.metodo,
      comprimento: comprimento ?? this.comprimento,
      desnivelM: desnivelM ?? this.desnivelM,
      distanciaHorizontalM: distanciaHorizontalM ?? this.distanciaHorizontalM,
      desnivelTransversalM: desnivelTransversalM ?? this.desnivelTransversalM,
      distanciaTransversalM:
          distanciaTransversalM ?? this.distanciaTransversalM,
      larguraOuEspacamento: larguraOuEspacamento ?? this.larguraOuEspacamento,
      k: k ?? this.k,
      a: a ?? this.a,
      vib: vib ?? this.vib,
      vazao: vazao ?? this.vazao,
      tempoAplicacao: tempoAplicacao ?? this.tempoAplicacao,
      laminaRequerida: laminaRequerida ?? this.laminaRequerida,
      manningN: manningN ?? this.manningN,
      sigmaZ: sigmaZ ?? this.sigmaZ,
      texturaSolo: texturaSolo ?? this.texturaSolo,
      tempoAvancoMetadeMin: tempoAvancoMetadeMin ?? this.tempoAvancoMetadeMin,
      tempoAvancoFinalMin: tempoAvancoFinalMin ?? this.tempoAvancoFinalMin,
      instanteRecessaoInicioMin:
          instanteRecessaoInicioMin ?? this.instanteRecessaoInicioMin,
      instanteRecessaoFinalMin:
          instanteRecessaoFinalMin ?? this.instanteRecessaoFinalMin,
      tipoInundacao: tipoInundacao ?? this.tipoInundacao,
      areaHectares: areaHectares ?? this.areaHectares,
      porosidade: porosidade ?? this.porosidade,
      profundidadeCamadaMm: profundidadeCamadaMm ?? this.profundidadeCamadaMm,
      condutividadeHidraulicaMmDia:
          condutividadeHidraulicaMmDia ?? this.condutividadeHidraulicaMmDia,
      dtaMmCm: dtaMmCm ?? this.dtaMmCm,
      fatorDisponibilidade: fatorDisponibilidade ?? this.fatorDisponibilidade,
      evapotranspiracaoMmDia:
          evapotranspiracaoMmDia ?? this.evapotranspiracaoMmDia,
      laminaSuperficialMm: laminaSuperficialMm ?? this.laminaSuperficialMm,
      vazaoDisponivelLps: vazaoDisponivelLps ?? this.vazaoDisponivelLps,
      resultado: resultado,
      executando: executando ?? this.executando,
      erro: erro,
    );
  }

  IrrigationParameters toIrrigationParameters() {
    return IrrigationParameters(
      comprimento: comprimento,
      declividade: declividade,
      declividadeTransversal: declividadeTransversal,
      larguraOuEspacamento: larguraOuEspacamento,
      k: k,
      a: a,
      vib: vib,
      vazao: vazao,
      tempoAplicacao: tempoAplicacao,
      laminaRequerida: laminaRequerida,
      manningN: manningN,
      sigmaZ: sigmaZ,
      texturaSolo: texturaSolo,
      tempoAvancoMetadeMin: tempoAvancoMetadeMin,
      tempoAvancoFinalMin: tempoAvancoFinalMin,
      instanteRecessaoInicioMin: instanteRecessaoInicioMin,
      instanteRecessaoFinalMin: instanteRecessaoFinalMin,
      tipoInundacao: tipoInundacao,
      areaHectares: areaHectares,
      porosidade: porosidade,
      profundidadeCamadaMm: profundidadeCamadaMm,
      condutividadeHidraulicaMmDia: condutividadeHidraulicaMmDia,
      dtaMmCm: dtaMmCm,
      fatorDisponibilidade: fatorDisponibilidade,
      evapotranspiracaoMmDia: evapotranspiracaoMmDia,
      laminaSuperficialMm: laminaSuperficialMm,
      vazaoDisponivelLps: vazaoDisponivelLps,
    );
  }
}

class ParametersController extends StateNotifier<ParametersState> {
  ParametersController() : super(const ParametersState());

  void setMetodo(MetodoIrrigacao metodo) {
    state = switch (metodo) {
      MetodoIrrigacao.sulco => ParametersState(
        metodo: metodo,
        comprimento: 200,
        desnivelM: 1,
        distanciaHorizontalM: 200,
        larguraOuEspacamento: 0.9,
        k: 2.83,
        a: 0.554,
        vazao: 1,
        tempoAplicacao: 130,
        laminaRequerida: 42,
        tempoAvancoMetadeMin: 35,
        tempoAvancoFinalMin: 90,
      ),
      MetodoIrrigacao.faixa => ParametersState(
        metodo: metodo,
        comprimento: 400,
        desnivelM: 0.4,
        distanciaHorizontalM: 400,
        larguraOuEspacamento: 50,
        k: 0.0034,
        a: 0.45,
        vib: 0.0001,
        vazao: 1.8,
        laminaRequerida: 56,
        manningN: 0.04,
        sigmaZ: 0.66,
      ),
      MetodoIrrigacao.inundacao => ParametersState(
        metodo: metodo,
        comprimento: 100,
        desnivelM: 0.05,
        distanciaHorizontalM: 100,
        larguraOuEspacamento: 20,
        distanciaTransversalM: 20,
        vazao: 100,
        tempoAvancoMetadeMin: 15,
        tempoAvancoFinalMin: 45,
      ),
    };
  }

  void setTipoInundacao(TipoInundacao tipo) {
    state = state.copyWith(tipoInundacao: tipo);
  }

  void loadFromParams(IrrigationParameters params) {
    // declividade is in m/m; convert to desnivelM/distanciaHorizontalM pair
    final distancia = 100.0;
    final desnivel = params.declividade * distancia;
    final distanciaTransversal = 10.0;
    state = state.copyWith(
      comprimento: params.comprimento,
      desnivelM: desnivel,
      distanciaHorizontalM: distancia,
      desnivelTransversalM:
          params.declividadeTransversal * distanciaTransversal,
      distanciaTransversalM: distanciaTransversal,
      larguraOuEspacamento: params.larguraOuEspacamento,
      k: params.k,
      a: params.a,
      vib: params.vib,
      vazao: params.vazao,
      tempoAplicacao: params.tempoAplicacao,
      laminaRequerida: params.laminaRequerida,
      manningN: params.manningN,
      sigmaZ: params.sigmaZ,
      texturaSolo: params.texturaSolo,
      tempoAvancoMetadeMin: params.tempoAvancoMetadeMin,
      tempoAvancoFinalMin: params.tempoAvancoFinalMin,
      instanteRecessaoInicioMin: params.instanteRecessaoInicioMin,
      instanteRecessaoFinalMin: params.instanteRecessaoFinalMin,
      tipoInundacao: params.tipoInundacao,
      areaHectares: params.areaHectares,
      porosidade: params.porosidade,
      profundidadeCamadaMm: params.profundidadeCamadaMm,
      condutividadeHidraulicaMmDia: params.condutividadeHidraulicaMmDia,
      dtaMmCm: params.dtaMmCm,
      fatorDisponibilidade: params.fatorDisponibilidade,
      evapotranspiracaoMmDia: params.evapotranspiracaoMmDia,
      laminaSuperficialMm: params.laminaSuperficialMm,
      vazaoDisponivelLps: params.vazaoDisponivelLps,
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
      case 'desnivelTransversalM':
        state = state.copyWith(desnivelTransversalM: parsed);
      case 'distanciaTransversalM':
        state = state.copyWith(distanciaTransversalM: parsed);
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
      case 'tempoAvancoMetadeMin':
        state = state.copyWith(tempoAvancoMetadeMin: parsed);
      case 'tempoAvancoFinalMin':
        state = state.copyWith(tempoAvancoFinalMin: parsed);
      case 'instanteRecessaoInicioMin':
        state = state.copyWith(instanteRecessaoInicioMin: parsed);
      case 'instanteRecessaoFinalMin':
        state = state.copyWith(instanteRecessaoFinalMin: parsed);
      case 'areaHectares':
        state = state.copyWith(areaHectares: parsed);
      case 'porosidade':
        state = state.copyWith(porosidade: parsed);
      case 'profundidadeCamadaMm':
        state = state.copyWith(profundidadeCamadaMm: parsed);
      case 'condutividadeHidraulicaMmDia':
        state = state.copyWith(condutividadeHidraulicaMmDia: parsed);
      case 'dtaMmCm':
        state = state.copyWith(dtaMmCm: parsed);
      case 'fatorDisponibilidade':
        state = state.copyWith(fatorDisponibilidade: parsed);
      case 'evapotranspiracaoMmDia':
        state = state.copyWith(evapotranspiracaoMmDia: parsed);
      case 'laminaSuperficialMm':
        state = state.copyWith(laminaSuperficialMm: parsed);
      case 'vazaoDisponivelLps':
        state = state.copyWith(vazaoDisponivelLps: parsed);
    }
  }

  void setTexturaSolo(TexturaSolo textura) {
    state = state.copyWith(texturaSolo: textura);
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
        MetodoIrrigacao.inundacao =>
          state.tipoInundacao == TipoInundacao.permanente
              ? RunPermanentBasinSimulation()(params)
              : RunBasinSimulation()(params),
      };
      state = state.copyWith(resultado: resultado, executando: false);
    } catch (e) {
      state = state.copyWith(erro: e.toString(), executando: false);
    }
  }
}

/// Mantém a escolha durante a navegação. Com `autoDispose`, o estado podia ser
/// recriado como Sulco entre o toque no cartão e a abertura do formulário.
final parametersProvider =
    StateNotifierProvider<ParametersController, ParametersState>((ref) {
      return ParametersController();
    });
