import 'dart:math';

import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/simulation_result.dart';
import 'package:irrigasim/models/sulcos/tipo_sulco_info.dart';
import 'package:irrigasim/models/sulcos/field_measurements.dart';
import 'package:irrigasim/models/sulcos/indicadores_balanco_sulco.dart';
import 'package:irrigasim/models/sulcos/irrigation_project.dart'
    show MetodoAjusteAvanco, PontoEnsaio;

import 'advance_curve_model.dart';
import 'infiltration_model.dart';

import 'flow_management.dart';
import '../performance_indicators.dart';
import '../surface_irrigation_math.dart';

class RunFurrowSimulation {
  SimulationResult call(
    IrrigationParameters params, {
    AdvanceCurveResult? advanceCurve,
  }) {
    if (params.origemCurvaInfiltracao ==
            OrigemCurvaInfiltracao.equacaoAcumuladaInformada &&
        params.entradasProjetoSulco?.curvaInfiltracao == null) {
      _validate(params);
    }
    final calculationParams = _parametersWithSelectedInfiltration(params);
    final tipo = calculationParams.tipoSulco ?? TipoSulco.sulcos_comuns;
    if (!tipo.suportaEscoamentoTerminal) {
      throw FormatException(tipo.motivoSemSuporteTerminal);
    }
    _validate(calculationParams);
    final slopePercent = calculationParams.declividade * 100;
    final maximumFlowLps = _calcularVazaoMaxima(
      tipo,
      slopePercent,
      calculationParams.texturaSolo,
    );
    final selectedAdvanceCurve =
        advanceCurve ?? _fitAdvanceFromMeasurements(calculationParams);
    if (selectedAdvanceCurve != null &&
        (!selectedAdvanceCurve.k.isFinite ||
            !selectedAdvanceCurve.b.isFinite ||
            selectedAdvanceCurve.k <= 0 ||
            selectedAdvanceCurve.b <= 0)) {
      throw const FormatException(
        'A curva de avanço deve ter coeficientes finitos e positivos.',
      );
    }
    final advance = selectedAdvanceCurve == null
        ? SurfaceIrrigationMath.fitAdvanceCurve(
            lengthM: calculationParams.comprimento,
            halfTimeMin: calculationParams.tempoAvancoMetadeMin,
            endTimeMin: calculationParams.tempoAvancoFinalMin,
          )
        : AdvanceCurve(
            coefficient: selectedAdvanceCurve.k,
            exponent: selectedAdvanceCurve.b,
            rSquared: selectedAdvanceCurve.r2,
            points:
                AdvanceCurveModel.gerarCurva(
                      comprimentoM: calculationParams.comprimento,
                      parametros: selectedAdvanceCurve,
                    )
                    .map(
                      (point) => PontoGrafico(point.distanciaM, point.tempoMin),
                    )
                    .toList(),
          );
    final requiredDepthM = calculationParams.laminaRequerida / 1000;
    final advanceTimeAtEndMin = advance.timeAt(calculationParams.comprimento);
    if (!advanceTimeAtEndMin.isFinite || advanceTimeAtEndMin <= 0) {
      throw const FormatException(
        'O avanço no fim do sulco está fora do domínio numérico.',
      );
    }

    // ---- Cálculo conforme o modo de manejo ----
    switch (params.manejoSulco) {
      case ManejoSulco.reduzida:
        return _simularVazaoReduzida(
          calculationParams,
          advance,
          advanceTimeAtEndMin,
          requiredDepthM,
          maximumFlowLps,
          tipo,
        );
      case ManejoSulco.surtir:
        throw const FormatException(
          'Surtirção exige um modelo de infiltração calibrado e ainda não é calculada.',
        );
      case ManejoSulco.constante:
        return _simularVazaoConstante(
          calculationParams,
          advance,
          advanceTimeAtEndMin,
          requiredDepthM,
          maximumFlowLps,
          tipo,
        );
    }
  }

  IrrigationParameters _parametersWithSelectedInfiltration(
    IrrigationParameters params,
  ) {
    final curve = params.entradasProjetoSulco?.curvaInfiltracao;
    if (curve != null) {
      if (params.origemCurvaInfiltracao !=
          OrigemCurvaInfiltracao.equacaoAcumuladaInformada) {
        throw const FormatException(
          'Selecione apenas uma curva de infiltração: ensaio entrada/saída ou equação tipada.',
        );
      }
      final converted = curve.acumuladaMm();
      return params.copyWith(k: converted.k, a: converted.a);
    }
    if (params.origemCurvaInfiltracao ==
        OrigemCurvaInfiltracao.equacaoAcumuladaInformada) {
      return params;
    }
    final areaM2 =
        params.distanciaEnsaioInfiltracaoM *
        params.espacamentoEnsaioInfiltracaoM;
    if (!areaM2.isFinite ||
        areaM2 <= 0 ||
        params.medicoesEntradaSaida.length < 2) {
      throw const FormatException(
        'O ensaio de entrada/saída requer área positiva e pelo menos duas observações.',
      );
    }
    var previous = -1.0;
    for (final point in params.medicoesEntradaSaida) {
      if (!point.tempoMin.isFinite ||
          point.tempoMin <= previous ||
          point.tempoMin <= 0 ||
          !point.vazaoEntradaLs.isFinite ||
          !point.vazaoSaidaLs.isFinite ||
          point.vazaoEntradaLs <= 0 ||
          point.vazaoSaidaLs < 0 ||
          point.vazaoSaidaLs >= point.vazaoEntradaLs) {
        throw const FormatException(
          'Ensaio de entrada/saída: tempos crescentes e vazões finitas com 0 ≤ Qsaída < Qentrada são obrigatórios.',
        );
      }
      previous = point.tempoMin;
    }
    final viPoints = params.medicoesEntradaSaida.map((point) {
      return PontoInfiltracaoMedido(
        tempoMin: point.tempoMin,
        volumeMm: InfiltrationModel.viEnsaioSaida(
          qEntradaLs: point.vazaoEntradaLs,
          qSaidaLs: point.vazaoSaidaLs,
          areaM2: areaM2,
        ),
      );
    }).toList();
    final rateCurve = InfiltrationModel.ajustarCurva(viPoints);
    final accumulatedExponent = rateCurve.n + 1;
    if (accumulatedExponent <= 0) {
      throw const FormatException(
        'A curva de taxa não pode ser integrada: n deve ser maior que −1.',
      );
    }
    return params.copyWith(
      k: rateCurve.k / (60 * accumulatedExponent),
      a: accumulatedExponent,
    );
  }

  AdvanceCurveResult? _fitAdvanceFromMeasurements(IrrigationParameters params) {
    if (params.usarEnsaioAvanco) {
      if (params.medicoesAvanco.isEmpty) {
        throw const FormatException(
          'Ensaio de avanço ativo sem medições; informe estacas ou desative o ensaio.',
        );
      }
      final points = params.medicoesAvanco
          .map(
            (point) => PontoEnsaio(
              distanciaM: point.distanciaM,
              tempoMin: point.tempoMin,
            ),
          )
          .toList();
      if (params.metodoCurvaAvanco == MetodoCurvaAvanco.minimosQuadrados) {
        return AdvanceCurveModel.ajustarMinimosQuadrados(points);
      }
      return AdvanceCurveModel.ajustarDoisPontosPorEstacas(points);
    }
    final k = params.coeficienteAvancoK;
    final b = params.expoenteAvancoB;
    if (k == null && b == null) return null;
    if (k == null ||
        b == null ||
        !k.isFinite ||
        !b.isFinite ||
        k <= 0 ||
        b <= 0) {
      throw const FormatException(
        'Informe coeficiente k e expoente b positivos para a curva Tx = k·xᵇ.',
      );
    }
    return AdvanceCurveResult(
      k: k,
      b: b,
      metodo: MetodoAjusteAvanco.doisPontos,
      pontosOriginais: const [],
    );
  }

  /// Vazão constante — comportamento original.
  SimulationResult _simularVazaoConstante(
    IrrigationParameters params,
    AdvanceCurve advance,
    double advanceTimeAtEndMin,
    double requiredDepthM,
    double maximumFlowLps,
    TipoSulco tipo,
  ) {
    final opportunityMin = params.tempoAplicacao;
    final applicationTimeMin = advanceTimeAtEndMin + opportunityMin;
    final profile = _calcularPerfil(params, advance, applicationTimeMin);
    final appliedDepthM =
        (params.vazao * applicationTimeMin * 60) /
        (params.comprimento * params.larguraOuEspacamento) /
        1000;
    return _montarResultado(
      params: params,
      advance: advance,
      profile: profile,
      requiredDepthM: requiredDepthM,
      appliedDepthM: appliedDepthM,
      maximumFlowLps: maximumFlowLps,
      tipo: tipo,
      applicationTimeMin: applicationTimeMin,
      opportunityMin: _oportunidadeFinal(
        params,
        opportunityMin,
        advanceTimeAtEndMin,
      ),
      advanceTimeAtEndMin: advanceTimeAtEndMin,
      metricasAdicionais: {},
    );
  }

  /// Vazão reduzida após avanço (§43).
  SimulationResult _simularVazaoReduzida(
    IrrigationParameters params,
    AdvanceCurve advance,
    double advanceTimeAtEndMin,
    double requiredDepthM,
    double maximumFlowLps,
    TipoSulco tipo,
  ) {
    final qOriginal = params.vazao;
    final opportunityMin = params.tempoAplicacao;
    final applicationTimeMin = advanceTimeAtEndMin + opportunityMin;
    final origem =
        params.origemVazaoReduzida == OrigemVazaoReduzida.taxaFinalDaCurva &&
            params.vazaoReduzidaLs > 0
        ? OrigemVazaoReduzida
              .informada // cenários legados
        : params.origemVazaoReduzida;
    final instanteMudanca = advanceTimeAtEndMin + params.tempoMudancaMin;
    final reductionEstimate = switch (origem) {
      OrigemVazaoReduzida.informada => null,
      OrigemVazaoReduzida.taxaFinalDaCurva =>
        FlowManagement.estimarVazaoReduzidaDaCurva(
          coeficienteAcumuladoMmMinA: params.k,
          expoenteAcumulado: params.a,
          oportunidadeFinalMin: opportunityMin,
          comprimentoM: params.comprimento,
          espacamentoM: params.larguraOuEspacamento,
        ),
      OrigemVazaoReduzida.vib => FlowManagement.calcularVazaoReduzida(
        f0MmH: params.vib * 60000, // vib legado: m/min → mm/h
        comprimentoM: params.comprimento,
        espacamentoM: params.larguraOuEspacamento,
        fator11: params.fator11Vib ? 1.1 : 1.0,
      ),
      OrigemVazaoReduzida.somatorioEspacial =>
        FlowManagement.estimarSomatorioEspacial(
          estacas: params.medicoesAvanco,
          comprimentoM: params.comprimento,
          espacamentoM: params.larguraOuEspacamento,
          instanteMudancaMin: instanteMudanca,
          coeficienteAcumuladoMmMinA: params.k,
          expoenteAcumulado: params.a,
        ),
    };
    final qReduzida =
        reductionEstimate?.vazaoReduzidaLs ?? params.vazaoReduzidaLs;
    if (!qReduzida.isFinite || qReduzida > params.vazao || qReduzida <= 0) {
      throw const FormatException(
        'A vazão reduzida deve ser positiva e não pode superar a vazão inicial.',
      );
    }
    if (origem == OrigemVazaoReduzida.vib && params.vib <= 0) {
      throw const FormatException(
        'Estimativa pela VIB exige taxa básica positiva informada (m/min).',
      );
    }
    if (params.vazaoDisponivelLps <= 0) {
      throw const FormatException(
        'Informe a vazão disponível na fonte para testar a oferta de água.',
      );
    }
    if (qOriginal + params.perdasConducaoLs >
        params.vazaoDisponivelLps + 1e-8) {
      throw const FormatException(
        'Oferta de água insuficiente para a vazão inicial e perdas de condução.',
      );
    }
    double? demandaEspacialLs;
    if (params.usarEnsaioAvanco &&
        origem != OrigemVazaoReduzida.somatorioEspacial &&
        params.medicoesAvanco.first.distanciaM == 0 &&
        params.medicoesAvanco.last.distanciaM == params.comprimento &&
        instanteMudanca > params.medicoesAvanco.last.tempoMin) {
      demandaEspacialLs = FlowManagement.estimarSomatorioEspacial(
        estacas: params.medicoesAvanco,
        comprimentoM: params.comprimento,
        espacamentoM: params.larguraOuEspacamento,
        instanteMudancaMin: instanteMudanca,
        coeficienteAcumuladoMmMinA: params.k,
        expoenteAcumulado: params.a,
      ).vazaoReduzidaLs;
      if (qReduzida + 1e-8 < demandaEspacialLs) {
        throw FormatException(
          'A vazão reduzida (${qReduzida.toStringAsFixed(3)} L/s) '
          'não cobre a demanda espacial no instante de mudança '
          '(${demandaEspacialLs.toStringAsFixed(3)} L/s, F24 p.96).',
        );
      }
    }

    // Com atraso zero, a redução começa assim que o avanço chega ao final.
    // Um atraso informado prolonga a vazão inicial durante a reposição.
    final tempoInicial = instanteMudanca;
    final tempoReduzido = applicationTimeMin - tempoInicial;
    final volumeTotal =
        (qOriginal * tempoInicial * 60) + (qReduzida * tempoReduzido * 60);
    final appliedDepthM =
        volumeTotal / (params.comprimento * params.larguraOuEspacamento) / 1000;

    // Cenário condicional: sem uma nova curva medida para qr, não se prevê
    // o novo avanço nem a recessão. O balanço rejeita oferta insuficiente.
    final profile = _calcularPerfil(params, advance, applicationTimeMin);

    return _montarResultado(
      params: params,
      advance: advance,
      profile: profile,
      requiredDepthM: requiredDepthM,
      appliedDepthM: appliedDepthM,
      maximumFlowLps: maximumFlowLps,
      tipo: tipo,
      applicationTimeMin: applicationTimeMin,
      opportunityMin: _oportunidadeFinal(
        params,
        opportunityMin,
        advanceTimeAtEndMin,
      ),
      advanceTimeAtEndMin: advanceTimeAtEndMin,
      metricasAdicionais: {
        'Vazão original': qOriginal,
        'Vazão reduzida': qReduzida,
        if (origem == OrigemVazaoReduzida.taxaFinalDaCurva)
          'Vazão reduzida estimada pela curva': qReduzida,
        if (origem == OrigemVazaoReduzida.vib) ...{
          'Vazão reduzida estimada por VIB': qReduzida,
          'Fator da estimativa VIB': params.fator11Vib ? 1.1 : 1.0,
          'VIB usada na redução': params.vib * 60000,
        },
        if (origem == OrigemVazaoReduzida.somatorioEspacial)
          'Vazão reduzida pelo somatório espacial': qReduzida,
        ...?demandaEspacialLs == null
            ? null
            : {'Demanda espacial no instante da troca': demandaEspacialLs},
        'Tempo com vazão inicial': tempoInicial,
        'Tempo com vazão reduzida': tempoReduzido,
      },
    );
  }

  /// Calcula o perfil longitudinal de infiltração (21 pontos).
  List<double> _calcularPerfil(
    IrrigationParameters params,
    AdvanceCurve advance,
    double applicationTimeMin,
  ) {
    final profile = <double>[];
    for (var i = 0; i <= 20; i++) {
      final distance = params.comprimento * i / 20;
      final advanceTime = advance.timeAt(distance);
      final localOpportunity =
          params.hipoteseRecessao == HipoteseRecessao.medidaPorEstaca
          ? _instanteRecessaoNaEstaca(params, distance) - advanceTime
          : applicationTimeMin - advanceTime;
      if (localOpportunity < 0) {
        throw FormatException(
          'Oportunidade negativa na posição ${distance.toStringAsFixed(2)} m.',
        );
      }
      if (localOpportunity <= 0) {
        profile.add(0.0);
      } else {
        profile.add(params.k / 1000 * pow(localOpportunity, params.a));
      }
    }
    return profile;
  }

  double _oportunidadeFinal(
    IrrigationParameters params,
    double opportunityWithoutRecessionMin,
    double advanceTimeAtEndMin,
  ) {
    if (params.hipoteseRecessao == HipoteseRecessao.desprezada) {
      return opportunityWithoutRecessionMin;
    }
    return _instanteRecessaoNaEstaca(params, params.comprimento) -
        advanceTimeAtEndMin;
  }

  double _distanciaReferenciaAvanco(IrrigationParameters params) =>
      params.distanciaReferenciaAvancoM ?? params.comprimento;

  double _instanteRecessaoNaEstaca(
    IrrigationParameters params,
    double distanciaM,
  ) {
    final points = params.medicoesRecessao;
    if (points.length < 2 ||
        points.first.distanciaM > 0 ||
        points.last.distanciaM < params.comprimento) {
      throw const FormatException(
        'A recessão medida deve cobrir o sulco desde 0 m até o comprimento total.',
      );
    }
    if (distanciaM <= points.first.distanciaM) {
      return points.first.instanteRecessaoMin;
    }
    for (var i = 1; i < points.length; i++) {
      final left = points[i - 1];
      final right = points[i];
      if (distanciaM <= right.distanciaM) {
        final fraction =
            (distanciaM - left.distanciaM) /
            (right.distanciaM - left.distanciaM);
        return left.instanteRecessaoMin +
            fraction * (right.instanteRecessaoMin - left.instanteRecessaoMin);
      }
    }
    return points.last.instanteRecessaoMin;
  }

  SimulationResult _montarResultado({
    required IrrigationParameters params,
    required AdvanceCurve advance,
    required List<double> profile,
    required double requiredDepthM,
    required double appliedDepthM,
    required double maximumFlowLps,
    required TipoSulco tipo,
    required double applicationTimeMin,
    required double opportunityMin,
    required Map<String, double> metricasAdicionais,
    required double advanceTimeAtEndMin,
  }) {
    final balance = SurfaceIrrigationMath.balance(
      profileM: profile,
      requiredDepthM: requiredDepthM,
      appliedDepthM: appliedDepthM,
    );
    final initialDepthM = profile.first;
    final finalDepthM = profile.last;
    // §35 and §37 use the final infiltrated depth and the mean infiltrated
    // depth directly; do not infer losses as the remainder of Ea.
    final applicationEfficiency = finalDepthM / appliedDepthM * 100;
    final distributionEfficiency =
        finalDepthM / ((initialDepthM + finalDepthM) / 2) * 100;
    final ppSlide =
        (balance.meanInfiltratedDepthM - requiredDepthM) / appliedDepthM * 100;
    final cuc = PerformanceIndicators.calcularCuc(profile).clamp(0, 100);
    final du = PerformanceIndicators.calcularDu(profile).clamp(0, 100);
    final conductionEfficiency = params.perdasConducaoLs == 0
        ? 100.0
        : params.vazao / (params.vazao + params.perdasConducaoLs) * 100;
    final adequacyDegree =
        SurfaceIrrigationMath.trapezoidalMean(
          profile.map((depth) => min(depth, requiredDepthM)).toList(),
        ) /
        requiredDepthM *
        100;
    final exceedsFlow = params.vazao > maximumFlowLps;
    final usefulDepthM = balance.usefulDepthM;
    final percolatedDepthM = balance.percolatedDepthM;
    final runoffDepthM = balance.runoffDepthM;
    final deficitMm = balance.deficitDepthM * 1000;
    final indicadores = IndicadoresBalancoSulco(
      eaSlide: applicationEfficiency,
      ppSlide: ppSlide < 0 ? null : ppSlide,
      eaIntegral: balance.applicationEfficiency,
      ppIntegral: balance.deepPercolationPercent,
      peIntegral: balance.runoffPercent,
      laminaInfiltradaMm: balance.meanInfiltratedDepthM * 1000,
      laminaUtilMm: usefulDepthM * 1000,
      laminaPercoladaMm: percolatedDepthM * 1000,
      laminaEscoadaMm: runoffDepthM * 1000,
      deficitMm: deficitMm,
    );
    final typedCurve = params.entradasProjetoSulco?.curvaInfiltracao;
    final alertaInfiltracao = typedCurve?.avisoParaOportunidade(
      params.hipoteseRecessao == HipoteseRecessao.desprezada
          ? applicationTimeMin
          : params.medicoesRecessao.first.instanteRecessaoMin,
      menorTempoMin: opportunityMin,
    );

    return SimulationResult(
      balancoSulco: indicadores,
      eficiencia: applicationEfficiency,
      eficienciaRequerimento: balance.requirementEfficiency,
      cuc: cuc.toDouble(),
      du: du.toDouble(),
      laminaMedia: balance.meanInfiltratedDepthM,
      laminaRequerida: requiredDepthM,
      tempoAvanco: advanceTimeAtEndMin,
      perdaPercolacao: balance.deepPercolationPercent,
      perdaEscoamento: balance.runoffPercent,
      curvaAvanco: advance.points,
      curvaOportunidade: List.generate(21, (index) {
        final distance = params.comprimento * index / 20;
        final advanceTime = advance.timeAt(distance);
        final opportunity =
            params.hipoteseRecessao == HipoteseRecessao.medidaPorEstaca
            ? _instanteRecessaoNaEstaca(params, distance) - advanceTime
            : applicationTimeMin - advanceTime;
        return PontoGrafico(distance, opportunity);
      }),
      perfilLongitudinal: profile,
      alertaVazaoExcedida: exceedsFlow
          ? 'A vazão adotada ultrapassa o limite não erosivo para a declividade informada.'
          : null,
      alertaInfiltracao: alertaInfiltracao,
      resumoTextual:
          'Cálculo conforme a planilha de referência: Ti = Ta + To, '
          'infiltração acumulada = aI·To^n e qmáx = C/S0^a (textura: ${params.texturaSolo.displayName}). '
          'Tipo: ${tipo.displayName}. '
          'Manejo: ${params.manejoSulco.displayName}. '
          '${params.manejoSulco == ManejoSulco.reduzida ? 'Cenário condicionado à manutenção da cobertura após a redução; não prevê novo avanço ou escoamento hidráulico. ' : ''}'
          'Recessão: ${params.hipoteseRecessao == HipoteseRecessao.desprezada ? 'desprezada' : 'medida por estaca'}.',
      metricas: {
        'Vazão por sulco': params.vazao,
        'Vazão máxima não erosiva': maximumFlowLps,
        'Tempo de avanco': advanceTimeAtEndMin,
        'Distância X de referência': _distanciaReferenciaAvanco(params),
        'Tempo Tx calculado em X': advance.timeAt(
          _distanciaReferenciaAvanco(params),
        ),
        'Tempo de oportunidade': opportunityMin,
        'Tempo de aplicação calculado': applicationTimeMin,
        'Coeficiente da curva de avanço': advance.coefficient,
        'Expoente da curva de avanço': advance.exponent,
        if (advance.rSquared != null)
          'R² log da curva de avanço': advance.rSquared!,
        'Lâmina aplicada': appliedDepthM * 1000,
        'Lâmina média infiltrada': balance.meanInfiltratedDepthM * 1000,
        'Eficiência de distribuição': distributionEfficiency,
        'Eficiência de condução': conductionEfficiency,
        'Grau de adequação': adequacyDegree,
        'Resíduo do balanço': balance.residualPercent,
        'Ea slide (Lf/Lm)': indicadores.eaSlide,
        if (indicadores.ppSlide != null)
          'Pp slide (Lmi−IRN)/Lm': indicadores.ppSlide!,
        'Ea integral (Lútil/Lm)': indicadores.eaIntegral,
        'Pp integral (Lpercolada/Lm)': indicadores.ppIntegral,
        'Pe integral (Lm−Lmi)/Lm': indicadores.peIntegral,
        'Declividade longitudinal': params.declividade,
        'Balanço - Aproveitado': balance.applicationEfficiency,
        'Balanço - Percolação': balance.deepPercolationPercent,
        'Balanço - Escoamento': balance.runoffPercent,
        'Lâmina útil': usefulDepthM * 1000,
        'Lâmina percolada': percolatedDepthM * 1000,
        'Lâmina escoada': runoffDepthM * 1000,
        'Déficit de lâmina': deficitMm,
        if (params.origemCurvaInfiltracao ==
            OrigemCurvaInfiltracao.ensaioEntradaSaida) ...{
          'Coeficiente VI ajustado': params.k * 60 * params.a,
          'Expoente VI ajustado': params.a - 1,
          'Coeficiente acumulado ajustado': params.k,
          'Expoente acumulado ajustado': params.a,
        },
        if (typedCurve != null) ...{
          'Coeficiente acumulado convertido': params.k,
          'Expoente acumulado convertido': params.a,
          if (typedCurve.vibMmHora != null)
            'VIB opcional informada': typedCurve.vibMmHora!,
          if (typedCurve.espacamentoConversaoM != null)
            'E usado na conversão de infiltração':
                typedCurve.espacamentoConversaoM!,
          if (typedCurve.cruzamentoVibMin() != null)
            'VI cruza VIB em': typedCurve.cruzamentoVibMin()!,
        },
        ...metricasAdicionais,
      },
      unidadesMetricas: const {
        'Vazão por sulco': 'L/s',
        'Vazão máxima não erosiva': 'L/s',
        'Tempo de avanco': 'min',
        'Distância X de referência': 'm',
        'Tempo Tx calculado em X': 'min',
        'Tempo de oportunidade': 'min',
        'Tempo de aplicação calculado': 'min',
        'Coeficiente da curva de avanço': 'min/mᵇ',
        'Expoente da curva de avanço': '',
        'R² log da curva de avanço': '',
        'Lâmina aplicada': 'mm',
        'Lâmina média infiltrada': 'mm',
        'Eficiência de distribuição': '%',
        'Eficiência de condução': '%',
        'Grau de adequação': '%',
        'Resíduo do balanço': '%',
        'Ea slide (Lf/Lm)': '%',
        'Pp slide (Lmi−IRN)/Lm': '%',
        'Ea integral (Lútil/Lm)': '%',
        'Pp integral (Lpercolada/Lm)': '%',
        'Pe integral (Lm−Lmi)/Lm': '%',
        'Declividade longitudinal': 'm/m',
        'Balanço - Aproveitado': '%',
        'Balanço - Percolação': '%',
        'Balanço - Escoamento': '%',
        'Lâmina útil': 'mm',
        'Lâmina percolada': 'mm',
        'Lâmina escoada': 'mm',
        'Déficit de lâmina': 'mm',
        'Coeficiente VI ajustado': 'mm/h·min⁻ⁿ',
        'Expoente VI ajustado': '',
        'Coeficiente acumulado ajustado': 'mm/minⁿ',
        'Coeficiente acumulado convertido': 'mm/minᵃ',
        'Expoente acumulado convertido': '',
        'VIB opcional informada': 'mm/h',
        'E usado na conversão de infiltração': 'm',
        'VI cruza VIB em': 'min',
        'Expoente acumulado ajustado': '',
        'Vazão original': 'L/s',
        'Vazão reduzida': 'L/s',
        'Vazão reduzida estimada pela curva': 'L/s',
        'Vazão reduzida estimada por VIB': 'L/s',
        'Vazão reduzida pelo somatório espacial': 'L/s',
        'Demanda espacial no instante da troca': 'L/s',
        'VIB usada na redução': 'mm/h',
        'Fator da estimativa VIB': '',
        'Tempo com vazão inicial': 'min',
        'Tempo com vazão reduzida': 'min',
        'Ciclo de surtirção': 'min',
        'Pausa entre ciclos': 'min',
        'Número de ciclos': '',
        'Fator de redução surtir': '',
      },
      tempoOportunidadeFinalMin: opportunityMin,
      tempoFornecimentoMin: applicationTimeMin,
      laminainfiltradaInicioMm: initialDepthM * 1000,
      laminainfiltradaFinalMm: finalDepthM * 1000,
      laminainfiltradaMediaMm: balance.meanInfiltratedDepthM * 1000,
      laminaAplicadaMediaMm: appliedDepthM * 1000,
      eficienciaDistribuicaoEd: distributionEfficiency,
      adequacaoUtilGa: adequacyDegree,
      origemCurvaAvanco: !params.usarEnsaioAvanco ? 'estimativa' : 'ensaio',
      metodoCurvaAvanco: params.metodoCurvaAvanco.name,
      origemCurvaInfiltracao: params.origemCurvaInfiltracao.name,
      hipoteseRecessao: params.hipoteseRecessao.name,
      extrapolouAvanco:
          params.usarEnsaioAvanco &&
          params.medicoesAvanco.last.distanciaM < params.comprimento,
    );
  }

  double _calcularVazaoMaxima(
    TipoSulco tipo,
    double slopePercent,
    TexturaSolo textura,
  ) {
    final resultado = FlowManagement.calcularVazaoMaxima(
      declividadePercent: slopePercent,
      textura: textura,
    );
    return resultado.qmaxLs;
  }

  void _validate(IrrigationParameters params) {
    final values = <String, double>{
      'comprimento': params.comprimento,
      'espaçamento': params.larguraOuEspacamento,
      'declividade': params.declividade,
      'vazão': params.vazao,
      'IRN': params.laminaRequerida,
      'coeficiente de infiltração': params.k,
      'expoente de infiltração': params.a,
      'VIB': params.vib,
      'tempo de aplicação': params.tempoAplicacao,
      'vazão reduzida': params.vazaoReduzidaLs,
      'atraso da redução': params.tempoMudancaMin,
      'perdas de condução': params.perdasConducaoLs,
      'vazão disponível': params.vazaoDisponivelLps,
      'tempo de avanço intermediário': params.tempoAvancoMetadeMin,
      'tempo de avanço final': params.tempoAvancoFinalMin,
      'distância do ensaio de infiltração': params.distanciaEnsaioInfiltracaoM,
      'espaçamento do ensaio de infiltração':
          params.espacamentoEnsaioInfiltracaoM,
      if (params.coeficienteAvancoK != null)
        'coeficiente de avanço': params.coeficienteAvancoK!,
      if (params.expoenteAvancoB != null)
        'expoente de avanço': params.expoenteAvancoB!,
    };
    for (final entry in values.entries) {
      if (!entry.value.isFinite) {
        throw FormatException('${entry.key} deve ser finito.');
      }
    }
    if (params.comprimento <= 0 ||
        params.larguraOuEspacamento <= 0 ||
        params.vazao <= 0 ||
        params.declividade <= 0 ||
        params.laminaRequerida <= 0 ||
        params.k <= 0 ||
        params.a <= 0 ||
        params.perdasConducaoLs < 0 ||
        params.vazaoDisponivelLps < 0) {
      throw const FormatException(
        'Revise geometria, declividade, vazão, infiltração e lâmina requerida.',
      );
    }
    if (params.distanciaReferenciaAvancoM != null &&
        (!params.distanciaReferenciaAvancoM!.isFinite ||
            params.distanciaReferenciaAvancoM! <= 0)) {
      throw const FormatException(
        'A distância X de referência do avanço deve ser positiva.',
      );
    }
    if (params.usarEnsaioAvanco) {
      if (params.medicoesAvanco.isEmpty) {
        throw const FormatException(
          'Ensaio de avanço ativo sem medições; informe estacas ou desative o ensaio.',
        );
      }
      if (params.vazaoEnsaioAvancoLs == null ||
          !params.vazaoEnsaioAvancoLs!.isFinite ||
          params.vazaoEnsaioAvancoLs! <= 0 ||
          params.condicoesEnsaioAvanco?.trim().isEmpty != false) {
        throw const FormatException(
          'Ensaio de avanço medido exige vazão e condições de solo, seção e orientação informadas.',
        );
      }
      if ((params.vazaoEnsaioAvancoLs! - params.vazao).abs() > 1e-8) {
        throw const FormatException(
          'A vazão do ensaio de avanço difere da vazão de projeto; a curva não pode ser reutilizada sem novo ensaio.',
        );
      }
      final errors = AdvanceCurveModel.validarPontos(
        params.medicoesAvanco
            .map(
              (p) =>
                  PontoEnsaio(distanciaM: p.distanciaM, tempoMin: p.tempoMin),
            )
            .toList(),
      );
      if (errors.isNotEmpty) {
        throw FormatException('Ensaio de avanço: ${errors.join('; ')}');
      }
    }
    final erosion = params.ensaioErosao;
    if (erosion != null) {
      if (!erosion.vazaoLs.isFinite ||
          erosion.vazaoLs <= 0 ||
          erosion.condicoes.trim().isEmpty) {
        throw const FormatException(
          'Ensaio de erosão exige vazão positiva e condições do ensaio informadas.',
        );
      }
      if (erosion.erosaoObservada && params.vazao >= erosion.vazaoLs - 1e-8) {
        throw FormatException(
          'Erosão observada em campo a ${erosion.vazaoLs} L/s '
          '(${erosion.condicoes}). A vazão de projeto não pode igualar ou superar '
          'essa vazão nas condições do ensaio, mesmo que qmax empírico permita.',
        );
      }
    }
    if (params.tempoAplicacao < 0 ||
        (!params.usarEnsaioAvanco &&
            params.coeficienteAvancoK == null &&
            (params.tempoAvancoMetadeMin <= 0 ||
                params.tempoAvancoFinalMin <= 0 ||
                params.tempoAvancoMetadeMin >= params.tempoAvancoFinalMin))) {
      throw const FormatException('Revise os tempos de avanço e oportunidade.');
    }
    if (params.manejoSulco == ManejoSulco.reduzida &&
        (params.vazaoReduzidaLs < 0 ||
            ((params.origemVazaoReduzida == OrigemVazaoReduzida.informada ||
                    params.origemVazaoReduzida ==
                        OrigemVazaoReduzida.taxaFinalDaCurva) &&
                params.vazaoReduzidaLs > 0 &&
                params.vazaoReduzidaLs > params.vazao) ||
            params.tempoMudancaMin < 0 ||
            params.tempoMudancaMin >= params.tempoAplicacao)) {
      throw const FormatException(
        'Revise a vazão reduzida e o atraso após o avanço.',
      );
    }
    if (params.manejoSulco == ManejoSulco.reduzida &&
        params.origemVazaoReduzida == OrigemVazaoReduzida.informada &&
        params.vazaoReduzidaLs <= 0) {
      throw const FormatException(
        'Informe uma vazão reduzida positiva ou selecione outra origem.',
      );
    }
    if (params.manejoSulco == ManejoSulco.reduzida &&
        params.origemVazaoReduzida == OrigemVazaoReduzida.somatorioEspacial &&
        !params.usarEnsaioAvanco) {
      throw const FormatException(
        'O somatório espacial (F24, p.96) exige estacas de avanço medidas até o comprimento do sulco.',
      );
    }
    if (params.origemCurvaInfiltracao ==
        OrigemCurvaInfiltracao.ensaioEntradaSaida) {
      if (params.medicoesEntradaSaida.length < 2) {
        throw const FormatException(
          'Ensaio de entrada/saída requer pelo menos duas medições.',
        );
      }
      var previous = -1.0;
      for (final point in params.medicoesEntradaSaida) {
        if (!point.tempoMin.isFinite ||
            point.tempoMin <= previous ||
            point.tempoMin <= 0 ||
            !point.vazaoEntradaLs.isFinite ||
            !point.vazaoSaidaLs.isFinite ||
            point.vazaoEntradaLs <= 0 ||
            point.vazaoSaidaLs < 0 ||
            point.vazaoSaidaLs >= point.vazaoEntradaLs) {
          throw const FormatException(
            'Ensaio de entrada/saída: tempos crescentes e vazões finitas com 0 ≤ Qsaída < Qentrada são obrigatórios.',
          );
        }
        previous = point.tempoMin;
      }
    }
    if (params.manejoSulco == ManejoSulco.surtir) {
      throw const FormatException(
        'Surtirção exige um modelo de infiltração calibrado e ainda não é calculada.',
      );
    }
    if (params.hipoteseRecessao == HipoteseRecessao.medidaPorEstaca) {
      final points = params.medicoesRecessao;
      if (points.length < 2 ||
          points.first.distanciaM != 0 ||
          points.last.distanciaM < params.comprimento) {
        throw const FormatException(
          'Informe recessão medida em estacas cobrindo o início e o final do sulco.',
        );
      }
      for (var i = 0; i < points.length; i++) {
        final point = points[i];
        if (!point.distanciaM.isFinite ||
            !point.instanteRecessaoMin.isFinite ||
            point.distanciaM < 0 ||
            point.instanteRecessaoMin < 0 ||
            (i > 0 &&
                (point.distanciaM <= points[i - 1].distanciaM ||
                    point.instanteRecessaoMin <
                        points[i - 1].instanteRecessaoMin))) {
          throw const FormatException(
            'As estacas de recessão devem ter distâncias únicas e tempos não decrescentes.',
          );
        }
      }
    }
  }
}
