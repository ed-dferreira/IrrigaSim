import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/tipo_sulco_info.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/furrow_simulation_coordinator.dart';
import 'package:irrigasim/shared/irrigacao/services/lamina_requerida.dart';
import 'package:irrigasim/shared/irrigacao/services/blaney_criddle.dart';
import 'package:irrigasim/features/irrigacao_sulcos/services/flow_management.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/irrigation_project.dart'
    show MetodoAjusteAvanco, PontoEnsaio;
import 'package:irrigasim/features/irrigacao_sulcos/models/field_measurements.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/curva_infiltracao_sulco.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/entradas_projeto_sulco.dart';
import 'package:irrigasim/features/irrigacao_sulcos/services/advance_curve_model.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/parameters_state.dart';

export 'parameters_state.dart';

class ParametersController extends StateNotifier<ParametersState> {
  ParametersController() : super(_recalcularLamina(const ParametersState()));

  static ParametersState _recalcularLamina(ParametersState current) {
    final entradas = current.entradasSulco;
    if (!entradas.podeRecalcularIrrigacao) {
      return current.copyWith(clearLaminaRequeridaResultado: true);
    }
    final etoCalculada = current.metodoEtc == MetodoEtcSulco.blaneyCriddle
        ? _etoBlaneyCriddle(current)
        : current.etoMmDia;
    if (current.metodoEtc == MetodoEtcSulco.blaneyCriddle &&
        etoCalculada == null) {
      return current.copyWith(clearLaminaRequeridaResultado: true);
    }
    final etc = current.evapotranspiracaoCulturaMmDia;
    final demandaLiquida = etc - current.precipitacaoEfetivaMmDia;
    if (demandaLiquida <= 0) {
      return current.copyWith(clearLaminaRequeridaResultado: true);
    }

    try {
      final resultado = LaminaRequeridaCalculator.calcular(
        uccPercentual: current.uccPercentual,
        upmpPercentual: current.upmpPercentual,
        densidadeGcm3: current.densidadeAparenteGcm3,
        profundidadeRaizesCm: current.profundidadeRaizesCm,
        fracaoAguaDisponivel: current.fracaoAguaDisponivel,
        demandaLiquidaMmDia: demandaLiquida,
        etoMmDia: etoCalculada,
        etcMmDia: etc,
        precipitacaoEfetivaMmDia: current.precipitacaoEfetivaMmDia,
      );
      return current.copyWith(
        laminaRequerida: resultado.irnMm,
        laminaRequeridaResultado: resultado,
      );
    } on ArgumentError {
      return current.copyWith(clearLaminaRequeridaResultado: true);
    }
  }

  static double? _etoBlaneyCriddle(ParametersState state) {
    final temperatura = state.temperaturaMediaC;
    final latitude = state.latitudeGraus;
    final mes = state.mesReferencia;
    if (temperatura == null || latitude == null || mes == null) return null;
    try {
      return BlaneyCriddle.etoMmDia(
        temperaturaMediaC: temperatura,
        latitudeGraus: latitude,
        mes: mes,
      );
    } on ArgumentError {
      return null;
    }
  }

  void _redimensionarCriddleSeSelecionado() {
    if (!state.dimensionarComprimentoCriddle) return;
    if (state.laminaRequeridaResultado == null) {
      if (state.origemGeometria == ProvenienciaSulco.calculado) {
        state = state.copyWith(
          origemGeometria: ProvenienciaSulco.naoInformado,
          mensagemPlanejamento: null,
        );
      }
      return;
    }
    dimensionarComprimentoCriddle();
  }

  /// Restaura os padrões do projeto de sulco — usado ao abrir um cenário
  /// salvo, para que campos ausentes não herdem valores da sessão anterior.
  void resetar() {
    state = _recalcularLamina(const ParametersState());
  }

  void setTipoSulco(TipoSulco tipo) {
    final defaults = _getDefaultsForTipoSulco(tipo);
    final b =
        (math.log(
          defaults.tempoAvancoMetadeMin / defaults.tempoAvancoFinalMin,
        ) /
        math.log(0.5));
    final k = defaults.tempoAvancoFinalMin / math.pow(defaults.comprimento, b);
    state = _recalcularLamina(
      state.copyWith(
        tipoSulco: tipo,
        comprimento: defaults.comprimento,
        larguraOuEspacamento: defaults.larguraOuEspacamento,
        vazao: defaults.vazao,
        tempoAplicacao: defaults.tempoAplicacao,
        laminaRequerida: defaults.laminaRequerida,
        tempoAvancoMetadeMin: defaults.tempoAvancoMetadeMin,
        tempoAvancoFinalMin: defaults.tempoAvancoFinalMin,
        coeficienteAvancoKInformado: k,
        expoenteAvancoBInformado: b,
        distanciaReferenciaAvancoM: defaults.comprimento,
      ),
    );
  }

  ParametersState _getDefaultsForTipoSulco(TipoSulco tipo) {
    return switch (tipo) {
      TipoSulco.sulcos_comuns => const ParametersState(
        comprimento: 200,
        larguraOuEspacamento: 0.9,
        vazao: 1,
        tempoAplicacao: 130,
        laminaRequerida: 42,
        tempoAvancoMetadeMin: 35,
        tempoAvancoFinalMin: 90,
      ),
      TipoSulco.sulcos_contorno => const ParametersState(
        comprimento: 110,
        larguraOuEspacamento: 0.9,
        vazao: 0.8,
        tempoAplicacao: 120,
        laminaRequerida: 42,
        tempoAvancoMetadeMin: 25,
        tempoAvancoFinalMin: 70,
      ),
      TipoSulco.sulcos_corrugados => const ParametersState(
        comprimento: 100,
        larguraOuEspacamento: 0.6,
        vazao: 0.3,
        tempoAplicacao: 90,
        laminaRequerida: 30,
        tempoAvancoMetadeMin: 15,
        tempoAvancoFinalMin: 45,
      ),
      TipoSulco.sulcos_nivel_tabuleiros => const ParametersState(
        comprimento: 80,
        larguraOuEspacamento: 1.0,
        vazao: 0.5,
        tempoAplicacao: 100,
        laminaRequerida: 50,
        tempoAvancoMetadeMin: 20,
        tempoAvancoFinalMin: 60,
      ),
      TipoSulco.sulcos_nivel_fechados => const ParametersState(
        comprimento: 50,
        larguraOuEspacamento: 1.2,
        vazao: 0.6,
        tempoAplicacao: 80,
        laminaRequerida: 45,
        tempoAvancoMetadeMin: 15,
        tempoAvancoFinalMin: 40,
      ),
      TipoSulco.sulcos_em_zigue_zague => const ParametersState(
        comprimento: 100,
        larguraOuEspacamento: 0.8,
        vazao: 0.7,
        tempoAplicacao: 110,
        laminaRequerida: 40,
        tempoAvancoMetadeMin: 20,
        tempoAvancoFinalMin: 55,
      ),
    };
  }

  void loadFromParams(IrrigationParameters params) {
    final projeto = params.entradasProjetoSulco;
    // Cenários legados preservam a inclinação, não recuperam uma base medida.
    final distancia = projeto?.baseLongitudinalM ?? 100.0;
    final distanciaReferenciaAvanco =
        params.distanciaReferenciaAvancoM ?? params.comprimento;
    final bAvanco =
        params.expoenteAvancoB ??
        (params.tempoAvancoMetadeMin > 0 && params.tempoAvancoFinalMin > 0
            ? -math.log(
                    params.tempoAvancoMetadeMin / params.tempoAvancoFinalMin,
                  ) /
                  math.ln2
            : 1.3625700793847084);
    final kAvanco =
        params.coeficienteAvancoK ??
        (params.comprimento > 0
            ? params.tempoAvancoFinalMin / math.pow(params.comprimento, bAvanco)
            : 0.0659064448778603);
    final pontosAvanco = params.medicoesAvanco
        .map(
          (point) => PontoEnsaio(
            distanciaM: point.distanciaM,
            tempoMin: point.tempoMin,
          ),
        )
        .toList();
    final desnivel =
        projeto?.desnivelLongitudinalM ?? params.declividade * distancia;
    ProvenienciaSulco origem(String key, double? value) =>
        projeto?.origens[key] ??
        (value == null
            ? ProvenienciaSulco.naoInformado
            : ProvenienciaSulco.informado);
    final origens = <String, ProvenienciaSulco>{
      'uccPercentual': origem('uccPercentual', projeto?.uccPercentual),
      'upmpPercentual': origem('upmpPercentual', projeto?.upmpPercentual),
      'densidadeAparenteGcm3': origem(
        'densidadeAparenteGcm3',
        projeto?.densidadeAparenteGcm3,
      ),
      'profundidadeRaizesCm': origem(
        'profundidadeRaizesCm',
        projeto?.profundidadeRadicularCm,
      ),
      'fracaoAguaDisponivel': origem(
        'fracaoAguaDisponivel',
        projeto?.fracaoDisponivel,
      ),
      'evapotranspiracaoMmDia': origem(
        'evapotranspiracaoMmDia',
        projeto?.etcAdotadaMmDia,
      ),
      'kc': origem('kc', projeto?.kc),
      'precipitacaoEfetivaMmDia': origem(
        'precipitacaoEfetivaMmDia',
        projeto?.precipitacaoMmDia,
      ),
      'k': origem('k', projeto?.curvaInfiltracao?.coeficiente),
      'a': origem('a', projeto?.curvaInfiltracao?.expoente),
    };
    final distanciaTransversal = 10.0;
    state = _recalcularLamina(
      state.copyWith(
        comprimento: params.comprimento,
        desnivelM: desnivel,
        distanciaHorizontalM: distancia,
        desnivelTransversalM:
            params.declividadeTransversal * distanciaTransversal,
        distanciaTransversalM: distanciaTransversal,
        larguraOuEspacamento: params.larguraOuEspacamento,
        k: params.k,
        a: params.a,
        projetoSulcoLegado: projeto == null,
        origemEntradasSulco: origens,
        curvaInfiltracaoSulco: projeto?.curvaInfiltracao,
        clearCurvaInfiltracaoSulco: projeto?.curvaInfiltracao == null,
        etoMmDia: projeto?.etoMmDia,
        clearEtoMmDia: projeto?.etoMmDia == null,
        temperaturaMediaC: projeto?.temperaturaMediaC,
        clearTemperaturaMediaC: projeto?.temperaturaMediaC == null,
        latitudeGraus: projeto?.latitudeGraus,
        clearLatitudeGraus: projeto?.latitudeGraus == null,
        mesReferencia: projeto?.mesReferencia,
        origemChuva: projeto?.origemChuva ?? OrigemChuvaSulco.naoInformada,
        metodoEtc: projeto?.metodoEtc ?? MetodoEtcSulco.adotada,
        decliveEncostaPercent: projeto?.decliveEncostaPercent,
        clearDecliveEncostaPercent: projeto?.decliveEncostaPercent == null,
        orientacaoSulco: projeto?.orientacaoSulco ?? '',
        origemGeometria:
            projeto?.origemGeometria ?? ProvenienciaSulco.naoInformado,
        dimensionarComprimentoCriddle:
            projeto?.dimensionarComprimentoCriddle == true ||
            projeto?.origemGeometria == ProvenienciaSulco.calculado,
        vib: params.vib,
        vazao: params.vazao,
        tempoAplicacao: params.tempoAplicacao,
        laminaRequerida: params.laminaRequerida,
        uccPercentual: projeto?.uccPercentual ?? state.uccPercentual,
        upmpPercentual: projeto?.upmpPercentual ?? state.upmpPercentual,
        densidadeAparenteGcm3:
            projeto?.densidadeAparenteGcm3 ?? state.densidadeAparenteGcm3,
        profundidadeRaizesCm:
            projeto?.profundidadeRadicularCm ?? state.profundidadeRaizesCm,
        fracaoAguaDisponivel:
            projeto?.fracaoDisponivel ?? state.fracaoAguaDisponivel,
        manningN: params.manningN,
        sigmaZ: params.sigmaZ,
        texturaSolo: params.texturaSolo,
        tipoSulco: params.tipoSulco,
        tempoAvancoMetadeMin: params.tempoAvancoMetadeMin,
        tempoAvancoFinalMin: params.tempoAvancoFinalMin,
        coeficienteAvancoKInformado: kAvanco,
        expoenteAvancoBInformado: bAvanco,
        distanciaReferenciaAvancoM: distanciaReferenciaAvanco,
        instanteRecessaoInicioMin: params.instanteRecessaoInicioMin,
        instanteRecessaoFinalMin: params.instanteRecessaoFinalMin,
        evapotranspiracaoMmDia:
            projeto?.etcAdotadaMmDia ?? params.evapotranspiracaoMmDia,
        vazaoDisponivelLps: params.vazaoDisponivelLps,
        manejoSulco: params.manejoSulco,
        vazaoReduzidaLs: params.vazaoReduzidaLs,
        tempoMudancaMin: params.tempoMudancaMin,
        cicloSurtirMin: params.cicloSurtirMin,
        jornadaDiariaH: params.jornadaDiariaH,
        periodoIrrigacaoDias: params.periodoIrrigacaoDias,
        tempoMudancaParcelaMin: params.tempoMudancaParcelaMin,
        perdasConducaoLs: params.perdasConducaoLs,
        precipitacaoEfetivaMmDia:
            projeto?.precipitacaoMmDia ?? params.precipitacaoEfetivaMmDia,
        nomeCultura: params.nomeCultura,
        kc: projeto?.kc ?? params.kc,
        espacamentoFileirasM: params.espacamentoFileirasM,
        espacamentoPlantasM: params.espacamentoPlantasM,
        larguraSulcoM: params.larguraSulcoM,
        profundidadeSulcoM: params.profundidadeSulcoM,
        origemCurvaInfiltracao: params.origemCurvaInfiltracao,
        distanciaEnsaioInfiltracaoM: params.distanciaEnsaioInfiltracaoM,
        espacamentoEnsaioInfiltracaoM: params.espacamentoEnsaioInfiltracaoM,
        medicoesEntradaSaida: params.medicoesEntradaSaida,
        hipoteseRecessao: params.hipoteseRecessao,
        medicoesRecessao: params.medicoesRecessao,
        pontosEnsaioAvanco: pontosAvanco,
        metodoCurvaAvanco: params.metodoCurvaAvanco,
        origemAvanco: params.usarEnsaioAvanco
            ? OrigemAvanco.ensaio
            : OrigemAvanco.estimativa,
        origemVazaoReduzida: params.origemVazaoReduzida,
        fator11Vib: params.fator11Vib,
        vazaoEnsaioAvancoLs: params.vazaoEnsaioAvancoLs,
        condicoesEnsaioAvanco: params.condicoesEnsaioAvanco ?? '',
        ensaioErosao: params.ensaioErosao,
        clearEnsaioErosao: params.ensaioErosao == null,
      ),
    );
  }

  void updateField({String? campo, String? valor}) {
    if (campo == null || valor == null) return;
    final atualCurva =
        state.curvaInfiltracaoSulco ?? state.entradasSulco.curvaInfiltracao;
    if ({
          'curvaEspacamentoM',
          'curvaVibMmHora',
          'curvaTempoMin',
          'curvaTempoMax',
        }.contains(campo) &&
        atualCurva != null) {
      final number = double.tryParse(valor.replaceAll(',', '.'));
      final nova = switch (campo) {
        'curvaEspacamentoM' => atualCurva.copyWith(
          espacamentoConversaoM: number,
          clearEspacamento: number == null,
        ),
        'curvaVibMmHora' => atualCurva.copyWith(
          vibMmHora: number,
          clearVib: number == null,
        ),
        'curvaTempoMin' => atualCurva.copyWith(
          tempoMinCalibrado: number,
          clearTempoMin: number == null,
        ),
        _ => atualCurva.copyWith(
          tempoMaxCalibrado: number,
          clearTempoMax: number == null,
        ),
      };
      state = state.copyWith(
        curvaInfiltracaoSulco: nova,
        projetoSulcoLegado: false,
      );
      _redimensionarCriddleSeSelecionado();
      return;
    }
    if ({
      'etoMmDia',
      'decliveEncostaPercent',
      'temperaturaMediaC',
      'latitudeGraus',
    }.contains(campo)) {
      final number = double.tryParse(valor.replaceAll(',', '.'));
      state = switch (campo) {
        'etoMmDia' => state.copyWith(
          etoMmDia: number,
          clearEtoMmDia: number == null,
          projetoSulcoLegado: false,
          origemEntradasSulco: {
            ...state.origemEntradasSulco,
            'etoMmDia': number == null
                ? ProvenienciaSulco.naoInformado
                : ProvenienciaSulco.informado,
          },
        ),
        'temperaturaMediaC' => state.copyWith(
          temperaturaMediaC: number,
          clearTemperaturaMediaC: number == null,
          projetoSulcoLegado: false,
        ),
        'latitudeGraus' => state.copyWith(
          latitudeGraus: number,
          clearLatitudeGraus: number == null,
          projetoSulcoLegado: false,
        ),
        _ => state.copyWith(
          decliveEncostaPercent: number,
          clearDecliveEncostaPercent: number == null,
          projetoSulcoLegado: false,
        ),
      };
      if (campo != 'decliveEncostaPercent') {
        state = _recalcularLamina(state);
        _redimensionarCriddleSeSelecionado();
      }
      return;
    }
    if (campo == 'larguraSulcoM' || campo == 'profundidadeSulcoM') {
      final parsedOptional = double.tryParse(valor.replaceAll(',', '.'));
      state = campo == 'larguraSulcoM'
          ? state.copyWith(
              larguraSulcoM: parsedOptional,
              clearLarguraSulcoM: parsedOptional == null,
            )
          : state.copyWith(
              profundidadeSulcoM: parsedOptional,
              clearProfundidadeSulcoM: parsedOptional == null,
            );
      return;
    }
    final parsed = double.tryParse(valor.replaceAll(',', '.'));
    if (parsed == null) return;

    var recalcularLamina = false;
    final comprimentoAnterior = state.comprimento;
    switch (campo) {
      case 'comprimento':
        state = state.copyWith(
          comprimento: parsed,
          origemGeometria: ProvenienciaSulco.medido,
          dimensionarComprimentoCriddle: false,
        );
      case 'distanciaReferenciaAvancoM':
        state = state.copyWith(distanciaReferenciaAvancoM: parsed);
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
        if (atualCurva?.tipo == TipoCurvaInfiltracaoSulco.acumulada &&
            atualCurva?.base == BaseInfiltracaoSulco.milimetros) {
          state = state.copyWith(
            curvaInfiltracaoSulco: atualCurva!.copyWith(
              coeficiente: parsed,
              proveniencia: ProvenienciaSulco.informado,
            ),
          );
        }
      case 'a':
        state = state.copyWith(a: parsed);
        if (atualCurva?.tipo == TipoCurvaInfiltracaoSulco.acumulada &&
            atualCurva?.base == BaseInfiltracaoSulco.milimetros) {
          state = state.copyWith(
            curvaInfiltracaoSulco: atualCurva!.copyWith(
              expoente: parsed,
              proveniencia: ProvenienciaSulco.informado,
            ),
          );
        }
      case 'curvaCoeficiente':
        if (atualCurva != null) {
          state = state.copyWith(
            curvaInfiltracaoSulco: atualCurva.copyWith(
              coeficiente: parsed,
              proveniencia: ProvenienciaSulco.informado,
            ),
          );
        }
      case 'curvaExpoente':
        if (atualCurva != null) {
          state = state.copyWith(
            curvaInfiltracaoSulco: atualCurva.copyWith(
              expoente: parsed,
              proveniencia: ProvenienciaSulco.informado,
            ),
          );
        }
      case 'vib':
        state = state.copyWith(vib: parsed);
      case 'vazao':
        state = state.copyWith(vazao: parsed);
      case 'tempoAplicacao':
        state = state.copyWith(tempoAplicacao: parsed);
      case 'manningN':
        state = state.copyWith(manningN: parsed);
      case 'sigmaZ':
        state = state.copyWith(sigmaZ: parsed);
      case 'tempoAvancoMetadeMin':
        state = state.copyWith(tempoAvancoMetadeMin: parsed);
      case 'tempoAvancoFinalMin':
        state = state.copyWith(tempoAvancoFinalMin: parsed);
      case 'coeficienteAvancoK':
        state = state.copyWith(coeficienteAvancoKInformado: parsed);
      case 'expoenteAvancoB':
        state = state.copyWith(
          coeficienteAvancoKInformado: state.coeficienteAvancoK,
          expoenteAvancoBInformado: parsed,
        );
      case 'comprimentoMaximoTerrenoM':
        state = state.copyWith(comprimentoMaximoTerrenoM: parsed);
      case 'distanciaEnsaioIntermediariaM':
        state = state.copyWith(distanciaEnsaioIntermediariaM: parsed);
      case 'tempoEnsaioIntermediarioMin':
        state = state.copyWith(tempoEnsaioIntermediarioMin: parsed);
      case 'distanciaEnsaioInfiltracaoM':
        state = state.copyWith(distanciaEnsaioInfiltracaoM: parsed);
      case 'espacamentoEnsaioInfiltracaoM':
        state = state.copyWith(espacamentoEnsaioInfiltracaoM: parsed);
      case 'instanteRecessaoInicioMin':
        state = state.copyWith(instanteRecessaoInicioMin: parsed);
      case 'instanteRecessaoFinalMin':
        state = state.copyWith(instanteRecessaoFinalMin: parsed);
      case 'areaHectares':
        state = state.copyWith(areaHectares: parsed);
      case 'evapotranspiracaoMmDia':
        state = state.copyWith(evapotranspiracaoMmDia: parsed);
        recalcularLamina = true;
      case 'vazaoDisponivelLps':
        state = state.copyWith(vazaoDisponivelLps: parsed);
      case 'kc':
        state = state.copyWith(kc: parsed);
        if (state.metodoEtc == MetodoEtcSulco.etoVezesKc ||
            state.metodoEtc == MetodoEtcSulco.blaneyCriddle) {
          recalcularLamina = true;
        }
      case 'espacamentoFileirasM':
        state = state.copyWith(espacamentoFileirasM: parsed);
      case 'espacamentoPlantasM':
        state = state.copyWith(espacamentoPlantasM: parsed);
      case 'precipitacaoEfetivaMmDia':
        state = state.copyWith(precipitacaoEfetivaMmDia: parsed);
        recalcularLamina = true;
      case 'uccPercentual':
        state = state.copyWith(uccPercentual: parsed);
        recalcularLamina = true;
      case 'upmpPercentual':
        state = state.copyWith(upmpPercentual: parsed);
        recalcularLamina = true;
      case 'densidadeAparenteGcm3':
        state = state.copyWith(densidadeAparenteGcm3: parsed);
        recalcularLamina = true;
      case 'profundidadeRaizesCm':
        state = state.copyWith(profundidadeRaizesCm: parsed);
        recalcularLamina = true;
      case 'fracaoAguaDisponivel':
        state = state.copyWith(fracaoAguaDisponivel: parsed);
        recalcularLamina = true;
      case 'vazaoReduzidaLs':
        state = state.copyWith(vazaoReduzidaLs: parsed);
      case 'vazaoEnsaioAvancoLs':
        state = state.copyWith(vazaoEnsaioAvancoLs: parsed);
      case 'jornadaDiariaH':
        state = state.copyWith(jornadaDiariaH: parsed);
      case 'periodoIrrigacaoDias':
        if (parsed != parsed.truncateToDouble()) return;
        state = state.copyWith(periodoIrrigacaoDias: parsed.toInt());
      case 'tempoMudancaParcelaMin':
        state = state.copyWith(tempoMudancaParcelaMin: parsed);
      case 'perdasConducaoLs':
        state = state.copyWith(perdasConducaoLs: parsed);
      case 'tempoMudancaMin':
        state = state.copyWith(tempoMudancaMin: parsed);
      case 'cicloSurtirMin':
        state = state.copyWith(cicloSurtirMin: parsed);
    }
    const tracked = {
      'uccPercentual',
      'upmpPercentual',
      'densidadeAparenteGcm3',
      'profundidadeRaizesCm',
      'fracaoAguaDisponivel',
      'evapotranspiracaoMmDia',
      'precipitacaoEfetivaMmDia',
      'kc',
      'k',
      'a',
    };
    if (tracked.contains(campo)) {
      state = state.copyWith(
        projetoSulcoLegado: false,
        origemEntradasSulco: {
          ...state.origemEntradasSulco,
          campo: ProvenienciaSulco.informado,
        },
        origemChuva: campo == 'precipitacaoEfetivaMmDia'
            ? OrigemChuvaSulco.efetiva
            : null,
      );
    }
    if ((campo == 'k' || campo == 'a') &&
        atualCurva == null &&
        state.origemCurvaInfiltracao ==
            OrigemCurvaInfiltracao.equacaoAcumuladaInformada) {
      state = state.copyWith(
        curvaInfiltracaoSulco: CurvaInfiltracaoSulco(
          tipo: TipoCurvaInfiltracaoSulco.acumulada,
          base: BaseInfiltracaoSulco.milimetros,
          coeficiente: state.k,
          expoente: state.a,
          proveniencia: ProvenienciaSulco.informado,
        ),
      );
    }
    if (campo == 'comprimento' ||
        campo == 'coeficienteAvancoK' ||
        campo == 'expoenteAvancoB') {
      if (campo == 'comprimento' &&
          (state.distanciaReferenciaAvancoM - comprimentoAnterior).abs() <
              1e-9) {
        state = state.copyWith(distanciaReferenciaAvancoM: state.comprimento);
      }
      state = _sincronizarAvancoEstimado(state);
    }
    if (recalcularLamina) {
      state = _recalcularLamina(state);
    }
    _redimensionarCriddleSeSelecionado();
  }

  ParametersState _sincronizarAvancoEstimado(ParametersState source) {
    if (source.origemAvanco != OrigemAvanco.estimativa ||
        source.comprimento <= 0 ||
        source.coeficienteAvancoK <= 0 ||
        source.expoenteAvancoB <= 0) {
      return source;
    }
    final curve = AdvanceCurveResult(
      k: source.coeficienteAvancoK,
      b: source.expoenteAvancoB,
      metodo: MetodoAjusteAvanco.doisPontos,
      pontosOriginais: const [],
    );
    return source.copyWith(
      tempoAvancoMetadeMin: AdvanceCurveModel.tempoAvanco(
        distanciaM: source.comprimento / 2,
        parametros: curve,
      ),
      tempoAvancoFinalMin: AdvanceCurveModel.tempoAvanco(
        distanciaM: source.comprimento,
        parametros: curve,
      ),
    );
  }

  void setTexturaSolo(TexturaSolo textura) {
    state = state.copyWith(texturaSolo: textura);
  }

  void setNomeCultura(String nome) {
    state = state.copyWith(nomeCultura: nome);
  }

  void setManejoSulco(ManejoSulco manejo) {
    state = state.copyWith(manejoSulco: manejo);
  }

  void setOrigemVazaoReduzida(OrigemVazaoReduzida origem) =>
      state = state.copyWith(
        origemVazaoReduzida: origem,
        vazaoReduzidaLs: origem == OrigemVazaoReduzida.informada
            ? state.vazaoReduzidaLs
            : 0,
      );

  void setFator11Vib(bool value) => state = state.copyWith(fator11Vib: value);

  void setCondicoesEnsaioAvanco(String value) {
    state = state.copyWith(condicoesEnsaioAvanco: value);
    _redimensionarCriddleSeSelecionado();
  }

  void setEnsaioErosao(EnsaioErosaoSulco? value) => state = state.copyWith(
    ensaioErosao: value,
    clearEnsaioErosao: value == null,
  );

  void setOrigemAvanco(OrigemAvanco origem) {
    state = _sincronizarAvancoEstimado(
      state.copyWith(origemAvanco: origem, mensagemPlanejamento: null),
    );
    _redimensionarCriddleSeSelecionado();
  }

  void setPontosEnsaioAvanco(List<PontoEnsaio> pontos) {
    state = state.copyWith(pontosEnsaioAvanco: List.unmodifiable(pontos));
    _redimensionarCriddleSeSelecionado();
  }

  void setMetodoCurvaAvanco(MetodoCurvaAvanco method) {
    state = state.copyWith(metodoCurvaAvanco: method);
    _redimensionarCriddleSeSelecionado();
  }

  void setOrigemCurvaInfiltracao(OrigemCurvaInfiltracao origem) {
    state = state.copyWith(origemCurvaInfiltracao: origem);
    _redimensionarCriddleSeSelecionado();
  }

  void setMetodoEtc(MetodoEtcSulco metodo) {
    state = _recalcularLamina(
      state.copyWith(metodoEtc: metodo, projetoSulcoLegado: false),
    );
    _redimensionarCriddleSeSelecionado();
  }

  void setMesReferencia(int mes) {
    state = _recalcularLamina(
      state.copyWith(mesReferencia: mes, projetoSulcoLegado: false),
    );
    _redimensionarCriddleSeSelecionado();
  }

  void setOrigemChuva(OrigemChuvaSulco origem) {
    state = _recalcularLamina(
      state.copyWith(origemChuva: origem, projetoSulcoLegado: false),
    );
    _redimensionarCriddleSeSelecionado();
  }

  void setOrientacaoSulco(String value) =>
      state = state.copyWith(orientacaoSulco: value, projetoSulcoLegado: false);

  void setOrigemGeometria(ProvenienciaSulco origem) => state = state.copyWith(
    origemGeometria: origem,
    dimensionarComprimentoCriddle: false,
    projetoSulcoLegado: false,
  );

  void setDimensionarComprimentoCriddle(bool ativo) {
    state = state.copyWith(
      dimensionarComprimentoCriddle: ativo,
      origemGeometria: ativo ? state.origemGeometria : ProvenienciaSulco.medido,
      mensagemPlanejamento: null,
    );
    _redimensionarCriddleSeSelecionado();
  }

  void configurarCurvaInfiltracao({
    TipoCurvaInfiltracaoSulco? tipo,
    BaseInfiltracaoSulco? base,
  }) {
    final curva =
        state.curvaInfiltracaoSulco ??
        state.entradasSulco.curvaInfiltracao ??
        CurvaInfiltracaoSulco(
          tipo: TipoCurvaInfiltracaoSulco.acumulada,
          base: BaseInfiltracaoSulco.milimetros,
          coeficiente: state.k,
          expoente: state.a,
          proveniencia: ProvenienciaSulco.ilustrativo,
        );
    state = state.copyWith(
      curvaInfiltracaoSulco: curva.copyWith(
        tipo: tipo,
        base: base,
        proveniencia: ProvenienciaSulco.informado,
        clearEspacamento: base == BaseInfiltracaoSulco.litrosPorMetro,
      ),
      projetoSulcoLegado: false,
    );
    _redimensionarCriddleSeSelecionado();
  }

  void setDataCurvaInfiltracao(DateTime? data) {
    final curva = state.entradasSulco.curvaInfiltracao;
    if (curva != null) {
      state = state.copyWith(
        curvaInfiltracaoSulco: curva.copyWith(
          dataEnsaio: data,
          clearData: data == null,
        ),
        projetoSulcoLegado: false,
      );
      _redimensionarCriddleSeSelecionado();
    }
  }

  void setMedicoesEntradaSaida(List<MedicaoEntradaSaida> points) {
    state = state.copyWith(medicoesEntradaSaida: List.unmodifiable(points));
    _redimensionarCriddleSeSelecionado();
  }

  void setHipoteseRecessao(HipoteseRecessao hipotese) {
    state = state.copyWith(hipoteseRecessao: hipotese);
    _redimensionarCriddleSeSelecionado();
  }

  void setMedicoesRecessao(List<MedicaoRecessao> points) {
    state = state.copyWith(medicoesRecessao: List.unmodifiable(points));
    _redimensionarCriddleSeSelecionado();
  }

  String? validarEnsaio() {
    if (state.origemAvanco == OrigemAvanco.estimativa) {
      if (!state.coeficienteAvancoK.isFinite ||
          state.coeficienteAvancoK <= 0 ||
          !state.expoenteAvancoB.isFinite ||
          state.expoenteAvancoB <= 0 ||
          !state.distanciaReferenciaAvancoM.isFinite ||
          state.distanciaReferenciaAvancoM <= 0) {
        return 'Informe k, X e b positivos para Tx = k·xᵇ.';
      }
      return null;
    }
    if (state.pontosEnsaioAvanco.length < 3) {
      return 'Informe pelo menos duas estacas medidas, além da origem automática.';
    }
    final erros = AdvanceCurveModel.validarPontos(state.pontosEnsaioAvanco);
    if (erros.isNotEmpty) return erros.join('; ');
    if (state.vazaoEnsaioAvancoLs == null ||
        !state.vazaoEnsaioAvancoLs!.isFinite ||
        state.vazaoEnsaioAvancoLs! <= 0 ||
        state.condicoesEnsaioAvanco?.trim().isEmpty != false) {
      return 'Informe vazão e condições do ensaio de avanço medido.';
    }
    if ((state.vazaoEnsaioAvancoLs! - state.vazao).abs() > 1e-8) {
      return 'A vazão do ensaio de avanço difere da vazão de projeto; faça novo ensaio.';
    }
    try {
      _curvaAvancoDaOrigem(state);
      return null;
    } on ArgumentError catch (error) {
      return error.message.toString();
    }
  }

  AdvanceCurveResult _curvaAvancoDaOrigem(ParametersState source) {
    if (source.origemAvanco == OrigemAvanco.ensaio) {
      return source.metodoCurvaAvanco == MetodoCurvaAvanco.minimosQuadrados
          ? AdvanceCurveModel.ajustarMinimosQuadrados(source.pontosEnsaioAvanco)
          : AdvanceCurveModel.ajustarDoisPontosPorEstacas(
              source.pontosEnsaioAvanco,
            );
    }
    if (source.coeficienteAvancoK <= 0 ||
        source.expoenteAvancoB <= 0 ||
        !source.coeficienteAvancoK.isFinite ||
        !source.expoenteAvancoB.isFinite) {
      throw ArgumentError('k e b da curva de avanço devem ser positivos.');
    }
    return AdvanceCurveResult(
      k: source.coeficienteAvancoK,
      b: source.expoenteAvancoB,
      metodo: MetodoAjusteAvanco.doisPontos,
      pontosOriginais: const [],
    );
  }

  /// Dimensiona o sulco pela regra prática de Criddle: Ta(L) = To / 4.
  /// To vem da inversa da curva acumulada para a IRN; a curva de avanço
  /// ajustada ao ensaio é invertida e limitada ao domínio das estacas medidas.
  void dimensionarComprimentoCriddle() {
    if (!state.dimensionarComprimentoCriddle) {
      state = state.copyWith(dimensionarComprimentoCriddle: true);
    }
    try {
      final irn =
          state.laminaRequeridaResultado?.irnMm ?? state.laminaRequerida;
      if (!irn.isFinite || irn <= 0) {
        throw const FormatException('Informe uma IRN positiva.');
      }

      final infiltracao =
          state.curvaInfiltracaoSulco?.acumuladaMm() ??
          (k: state.k, a: state.a);
      if (!infiltracao.k.isFinite ||
          infiltracao.k <= 0 ||
          !infiltracao.a.isFinite ||
          infiltracao.a <= 0) {
        throw const FormatException(
          'Informe uma curva de infiltração acumulada válida para calcular To.',
        );
      }
      final to = math.pow(irn / infiltracao.k, 1 / infiltracao.a).toDouble();
      if (!to.isFinite || to <= 0) {
        throw const FormatException('Não foi possível calcular To pela IRN.');
      }
      final avisoInfiltracao = state.curvaInfiltracaoSulco
          ?.avisoParaOportunidade(to, menorTempoMin: to);
      final taAlvo = to / 4;
      double comprimento;
      AdvanceCurveResult? curva;
      if (state.origemAvanco == OrigemAvanco.ensaio) {
        final erroEnsaio = validarEnsaio();
        if (erroEnsaio != null) throw FormatException(erroEnsaio);
        final pontos = [...state.pontosEnsaioAvanco]
          ..sort((a, b) => a.distanciaM.compareTo(b.distanciaM));
        if (taAlvo > pontos.last.tempoMin) {
          throw FormatException(
            'Ta alvo (${taAlvo.toStringAsFixed(2)} min) excede o último tempo '
            'medido (${pontos.last.tempoMin.toStringAsFixed(2)} min); '
            'o ensaio não cobre o comprimento necessário.',
          );
        }
        final curvaMedida = _curvaAvancoDaOrigem(state);
        comprimento = AdvanceCurveModel.distanciaEmTempo(
          tempoMin: taAlvo,
          parametros: curvaMedida,
        );
        if (comprimento < pontos.first.distanciaM ||
            comprimento > pontos.last.distanciaM) {
          throw const FormatException(
            'O comprimento calculado fica fora do intervalo coberto pelas estacas.',
          );
        }
      } else {
        curva = _curvaAvancoDaOrigem(state);
        comprimento = AdvanceCurveModel.distanciaEmTempo(
          tempoMin: taAlvo,
          parametros: curva,
        );
      }
      if (!comprimento.isFinite || comprimento <= 0) {
        throw const FormatException('O comprimento calculado não é válido.');
      }
      if (comprimento > state.comprimentoMaximoTerrenoM) {
        throw FormatException(
          'Criddle resulta em ${comprimento.toStringAsFixed(1)} m, acima do '
          'limite informado para o terreno (${state.comprimentoMaximoTerrenoM.toStringAsFixed(1)} m). '
          'Ajuste o limite ou escolha outro critério; nenhum comprimento foi alterado.',
        );
      }
      final advance = state.origemAvanco == OrigemAvanco.ensaio
          ? _curvaAvancoDaOrigem(state)
          : curva!;
      final avancoMetade = AdvanceCurveModel.tempoAvanco(
        distanciaM: comprimento / 2,
        parametros: advance,
      );
      final avancoFinal = state.origemAvanco == OrigemAvanco.ensaio
          ? taAlvo
          : AdvanceCurveModel.tempoAvanco(
              distanciaM: comprimento,
              parametros: advance,
            );
      state = state.copyWith(
        comprimento: comprimento,
        origemGeometria: ProvenienciaSulco.calculado,
        tempoAplicacao: to,
        tempoAvancoMetadeMin: avancoMetade,
        tempoAvancoFinalMin: avancoFinal,
        distanciaReferenciaAvancoM: comprimento,
        distanciaEnsaioIntermediariaM: comprimento / 2,
        tempoEnsaioIntermediarioMin: avancoMetade,
        mensagemPlanejamento:
            'Comprimento dimensionado pela regra prática de Criddle: '
            'IRN=${irn.toStringAsFixed(2)} mm, To=${to.toStringAsFixed(2)} min, '
            'Ta alvo=To/4=${taAlvo.toStringAsFixed(2)} min e '
            'L=${comprimento.toStringAsFixed(2)} m. '
            'Confirme depois erosão, eficiência, domínio do ensaio e operação.'
            '${avisoInfiltracao == null ? '' : ' Aviso: $avisoInfiltracao'}',
      );
    } on FormatException catch (error) {
      state = state.copyWith(
        origemGeometria: state.dimensionarComprimentoCriddle
            ? ProvenienciaSulco.naoInformado
            : null,
        mensagemPlanejamento: error.message.toString(),
      );
    } on ArgumentError catch (error) {
      state = state.copyWith(
        origemGeometria: state.dimensionarComprimentoCriddle
            ? ProvenienciaSulco.naoInformado
            : null,
        mensagemPlanejamento: error.message.toString(),
      );
    }
  }

  ParametersState _stateComAvancoDaOrigem(ParametersState source) {
    final curve = _curvaAvancoDaOrigem(source);
    return source.copyWith(
      tempoAvancoMetadeMin: AdvanceCurveModel.tempoAvanco(
        distanciaM: source.comprimento / 2,
        parametros: curve,
      ),
      tempoAvancoFinalMin: AdvanceCurveModel.tempoAvanco(
        distanciaM: source.comprimento,
        parametros: curve,
      ),
    );
  }

  void recomendarMaiorComprimento() {
    final erroEnsaio = validarEnsaio();
    if (erroEnsaio != null) {
      state = state.copyWith(mensagemPlanejamento: erroEnsaio);
      return;
    }

    try {
      final declividadePercent = state.declividade * 100;
      final tipo = state.tipoSulco ?? TipoSulco.sulcos_comuns;
      if (!tipo.suportaEscoamentoTerminal) {
        state = state.copyWith(
          mensagemPlanejamento: tipo.motivoSemSuporteTerminal,
        );
        return;
      }
      final qmax = declividadePercent > 0
          ? FlowManagement.calcularVazaoMaxima(
              declividadePercent: declividadePercent,
              textura: state.texturaSolo,
            ).qmaxLs
          : double.infinity;

      final base = _stateComAvancoDaOrigem(state);
      final curve = _curvaAvancoDaOrigem(base);
      ParametersState? recomendado;
      final avaliacoes = <String>[];
      final comprimentos = <double>[];
      for (
        var comprimento = 50.0;
        comprimento <= state.comprimentoMaximoTerrenoM;
        comprimento += 50
      ) {
        comprimentos.add(comprimento);
      }
      if (state.comprimentoMaximoTerrenoM >= 50 &&
          !comprimentos.contains(state.comprimentoMaximoTerrenoM)) {
        comprimentos.add(state.comprimentoMaximoTerrenoM);
      }
      comprimentos.sort();
      for (final comprimento in comprimentos) {
        if (state.origemAvanco == OrigemAvanco.ensaio &&
            comprimento > state.pontosEnsaioAvanco.last.distanciaM) {
          avaliacoes.add(
            '${comprimento.toStringAsFixed(0)} m: sem validação — ensaio cobre apenas '
            '${state.pontosEnsaioAvanco.last.distanciaM.toStringAsFixed(0)} m; '
            'extrapolação não é aprovada.',
          );
          continue;
        }
        final declividadeFaixa = TipoSulcoInfo.getInfo(tipo).declividade;
        final faixa = declividadeFaixa.classificar(declividadePercent);
        if (faixa == FaixaDeclividade.fora) {
          avaliacoes.add(
            '${comprimento.toStringAsFixed(0)} m: reprovado — declividade '
            '${declividadePercent.toStringAsFixed(3)}% fora da faixa usável '
            '(${declividadeFaixa.faixaUsavelLabel}).',
          );
          continue;
        }
        if (state.vazao > qmax) {
          avaliacoes.add(
            '${comprimento.toStringAsFixed(0)} m: reprovado — '
            'Q=${state.vazao.toStringAsFixed(2)} L/s excede '
            'qmax=${qmax.toStringAsFixed(2)} L/s.',
          );
          continue;
        }
        final candidato = base.copyWith(
          comprimento: comprimento,
          distanciaEnsaioIntermediariaM:
              state.origemAvanco == OrigemAvanco.ensaio &&
                  state.metodoCurvaAvanco == MetodoCurvaAvanco.doisPontos
              ? comprimento / 2
              : null,
          tempoAvancoMetadeMin: AdvanceCurveModel.tempoAvanco(
            distanciaM: comprimento / 2,
            parametros: curve,
          ),
          tempoAvancoFinalMin: AdvanceCurveModel.tempoAvanco(
            distanciaM: comprimento,
            parametros: curve,
          ),
          tempoEnsaioIntermediarioMin: state.origemAvanco == OrigemAvanco.ensaio
              ? AdvanceCurveModel.tempoAvanco(
                  distanciaM: state.distanciaEnsaioIntermediariaM,
                  parametros: curve,
                )
              : null,
        );
        try {
          final resultado = const FurrowSimulationCoordinator().simular(
            candidato.toIrrigationParameters(),
          );
          final aprovado =
              (resultado.balancoSulco?.eaIntegral ?? resultado.eficiencia) >=
                  60 &&
              resultado.alertaVazaoExcedida == null &&
              resultado.alertaInfiltracao == null &&
              !resultado.extrapolouAvanco &&
              (resultado.planejamentoOperacional?.agendaViavel ?? true) &&
              (resultado.planejamentoOperacional?.vazaoDisponivelSuficiente ??
                  true);
          final alertas = <String>[
            if ((resultado.eficienciaDistribuicaoEd ?? 100) < 70)
              'Ed abaixo da referência de 70% (indicativa)',
            if (resultado.perdaPercolacao > 15) 'Pp elevada (>15%)',
            if (resultado.perdaEscoamento > 10) 'Pe elevada (>10%)',
            if (faixa == FaixaDeclividade.usavel)
              'declividade fora do aconselhável',
            if (resultado.extrapolouAvanco) 'curva de avanço extrapolada',
            ?resultado.alertaInfiltracao,
            if (resultado.planejamentoOperacional?.agendaViavel == false ||
                resultado.planejamentoOperacional?.vazaoDisponivelSuficiente ==
                    false)
              'operação ou oferta de água inviável',
          ];
          avaliacoes.add(
            '${comprimento.toStringAsFixed(0)} m: '
            '${aprovado ? 'candidato segundo hipóteses' : 'reprovado'} — '
            'Ta=${resultado.tempoAvanco.toStringAsFixed(1)} min, '
            'Ea integral=${(resultado.balancoSulco?.eaIntegral ?? resultado.eficiencia).toStringAsFixed(1)}% '
            '(mín. 60%), '
            'Ed=${(resultado.eficienciaDistribuicaoEd ?? 0).toStringAsFixed(1)}%, '
            'Pp=${resultado.perdaPercolacao.toStringAsFixed(1)}%, '
            'Pe=${resultado.perdaEscoamento.toStringAsFixed(1)}%, '
            'Q=${state.vazao.toStringAsFixed(2)} / '
            'qmax=${qmax.toStringAsFixed(2)} L/s'
            '${alertas.isEmpty ? '' : '; alertas: ${alertas.join(', ')}'}.',
          );
          if (aprovado) {
            recomendado = candidato;
          }
        } catch (error) {
          avaliacoes.add(
            '${comprimento.toStringAsFixed(0)} m: reprovado — ${error.toString().replaceFirst('FormatException: ', '')}',
          );
        }
      }
      final relatorio =
          'Avaliação de comprimentos (critérios: declividade usável, '
          'Q ≤ qmax, Ea integral ≥ 60%, cobertura do ensaio e operação):\n${avaliacoes.join('\n')}';
      if (recomendado == null) {
        state = state.copyWith(
          mensagemPlanejamento:
              'Nenhum comprimento atende aos critérios com os dados disponíveis.\n$relatorio',
        );
        return;
      }
      state = recomendado.copyWith(
        mensagemPlanejamento:
            'Maior candidato segundo as hipóteses: ${recomendado.comprimento.toStringAsFixed(0)} m.\n$relatorio',
      );
    } on FormatException catch (e) {
      state = state.copyWith(mensagemPlanejamento: e.message.toString());
    } catch (_) {
      state = state.copyWith(
        mensagemPlanejamento: 'Não foi possível avaliar os dados informados.',
      );
    }
  }

  double calcularDeclividade() {
    return state.declividade;
  }

  Future<void> executarSimulacao() async {
    final erroEnsaio = validarEnsaio();
    if (erroEnsaio != null) {
      state = state.copyWith(erro: erroEnsaio);
      return;
    }
    state = state.copyWith(executando: true, erro: null);
    try {
      final curvaAvanco = _curvaAvancoDaOrigem(state);
      final params = _stateComAvancoDaOrigem(state).toIrrigationParameters();
      final resultado = const FurrowSimulationCoordinator().executar(
        params,
        curvaAvanco: curvaAvanco,
      );
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
