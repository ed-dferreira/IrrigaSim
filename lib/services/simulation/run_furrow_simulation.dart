import 'dart:math';

import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/simulation_result.dart';
import 'package:irrigasim/models/tipo_sulco_info.dart';

import 'flow_management.dart';
import 'performance_indicators.dart';
import 'surface_irrigation_math.dart';

class RunFurrowSimulation {
  SimulationResult call(IrrigationParameters params) {
    _validate(params);
    final tipo = params.tipoSulco ?? TipoSulco.sulcos_comuns;
    final slopePercent = params.declividade * 100;
    final maximumFlowLps = _calcularVazaoMaxima(
      tipo,
      slopePercent,
      params.texturaSolo,
    );
    final advance = SurfaceIrrigationMath.fitAdvanceCurve(
      lengthM: params.comprimento,
      halfTimeMin: params.tempoAvancoMetadeMin,
      endTimeMin: params.tempoAvancoFinalMin,
    );
    final requiredDepthM = params.laminaRequerida / 1000;

    // ---- Cálculo conforme o modo de manejo ----
    switch (params.manejoSulco) {
      case ManejoSulco.reduzida:
        return _simularVazaoReduzida(
          params,
          advance,
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
          params,
          advance,
          requiredDepthM,
          maximumFlowLps,
          tipo,
        );
    }
  }

  /// Vazão constante — comportamento original.
  SimulationResult _simularVazaoConstante(
    IrrigationParameters params,
    dynamic advance,
    double requiredDepthM,
    double maximumFlowLps,
    TipoSulco tipo,
  ) {
    final opportunityMin = params.tempoAplicacao;
    final applicationTimeMin = params.tempoAvancoFinalMin + opportunityMin;
    final profile = _calcularPerfil(params, advance, applicationTimeMin);
    final appliedDepthM =
        (params.vazao * applicationTimeMin * 60) /
        (params.comprimento * params.larguraOuEspacamento) /
        1000;
    return _montarResultado(
      params: params,
      profile: profile,
      requiredDepthM: requiredDepthM,
      appliedDepthM: appliedDepthM,
      maximumFlowLps: maximumFlowLps,
      tipo: tipo,
      applicationTimeMin: applicationTimeMin,
      opportunityMin: opportunityMin,
      metricasAdicionais: {},
    );
  }

  /// Vazão reduzida após avanço (§43).
  SimulationResult _simularVazaoReduzida(
    IrrigationParameters params,
    dynamic advance,
    double requiredDepthM,
    double maximumFlowLps,
    TipoSulco tipo,
  ) {
    final qOriginal = params.vazao;
    final qReduzida = params.vazaoReduzidaLs;
    final opportunityMin = params.tempoAplicacao;
    final applicationTimeMin = params.tempoAvancoFinalMin + opportunityMin;

    // Com atraso zero, a redução começa assim que o avanço chega ao final.
    // Um atraso informado prolonga a vazão inicial durante a reposição.
    final tempoInicial = (params.tempoAvancoFinalMin + params.tempoMudancaMin)
        .clamp(0, applicationTimeMin)
        .toDouble();
    final tempoReduzido = applicationTimeMin - tempoInicial;
    final volumeTotal =
        (qOriginal * tempoInicial * 60) + (qReduzida * tempoReduzido * 60);
    final appliedDepthM =
        volumeTotal / (params.comprimento * params.larguraOuEspacamento) / 1000;

    // Perfil de infiltração: oportunidade local varia com a posição.
    // Cada ponto infiltra por (applicationTime - tempoDeAvançoAteEle).
    final profile = _calcularPerfil(params, advance, applicationTimeMin);

    return _montarResultado(
      params: params,
      profile: profile,
      requiredDepthM: requiredDepthM,
      appliedDepthM: appliedDepthM,
      maximumFlowLps: maximumFlowLps,
      tipo: tipo,
      applicationTimeMin: applicationTimeMin,
      opportunityMin: opportunityMin,
      metricasAdicionais: {
        'Vazão original': qOriginal,
        'Vazão reduzida': qReduzida,
        'Tempo de mudança': tempoInicial,
      },
    );
  }

  /// Calcula o perfil longitudinal de infiltração (21 pontos).
  List<double> _calcularPerfil(
    IrrigationParameters params,
    dynamic advance,
    double applicationTimeMin,
  ) {
    final profile = <double>[];
    for (var i = 0; i <= 20; i++) {
      final distance = params.comprimento * i / 20;
      final advanceTime = i == 20
          ? params.tempoAvancoFinalMin
          : advance.timeAt(distance);
      final localOpportunity = applicationTimeMin - advanceTime;
      if (localOpportunity <= 0) {
        profile.add(0.0);
      } else {
        profile.add(params.k / 1000 * pow(localOpportunity, params.a));
      }
    }
    return profile;
  }

  SimulationResult _montarResultado({
    required IrrigationParameters params,
    required List<double> profile,
    required double requiredDepthM,
    required double appliedDepthM,
    required double maximumFlowLps,
    required TipoSulco tipo,
    required double applicationTimeMin,
    required double opportunityMin,
    required Map<String, double> metricasAdicionais,
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
    final percolationPercent =
        ((balance.meanInfiltratedDepthM - requiredDepthM) / appliedDepthM * 100)
            .clamp(0, double.infinity)
            .toDouble();
    final runoffPercent =
        ((appliedDepthM - balance.meanInfiltratedDepthM) / appliedDepthM * 100)
            .clamp(0, double.infinity)
            .toDouble();
    final cuc = PerformanceIndicators.calcularCuc(profile).clamp(0, 100);
    final du = PerformanceIndicators.calcularDu(profile).clamp(0, 100);
    final conductionEfficiency = params.perdasConducaoLs == 0
        ? 100.0
        : params.vazao / (params.vazao + params.perdasConducaoLs) * 100;
    final adequacyDegree =
        profile
            .map((depth) => min(depth, requiredDepthM) / requiredDepthM)
            .reduce((sum, value) => sum + value) /
        profile.length *
        100;
    final exceedsFlow = params.vazao > maximumFlowLps;
    final usefulDepthM =
        balance.applicationEfficiency / 100 * appliedDepthM;
    final percolatedDepthM =
        balance.deepPercolationPercent / 100 * appliedDepthM;
    final runoffDepthM = balance.runoffPercent / 100 * appliedDepthM;
    final deficitMm =
        max(0.0, requiredDepthM * 1000 - usefulDepthM * 1000);

    final advance = SurfaceIrrigationMath.fitAdvanceCurve(
      lengthM: params.comprimento,
      halfTimeMin: params.tempoAvancoMetadeMin,
      endTimeMin: params.tempoAvancoFinalMin,
    );

    return SimulationResult(
      eficiencia: applicationEfficiency,
      eficienciaRequerimento: balance.requirementEfficiency,
      cuc: cuc.toDouble(),
      du: du.toDouble(),
      laminaMedia: balance.meanInfiltratedDepthM,
      laminaRequerida: requiredDepthM,
      tempoAvanco: params.tempoAvancoFinalMin,
      perdaPercolacao: percolationPercent,
      perdaEscoamento: runoffPercent,
      curvaAvanco: advance.points,
      perfilLongitudinal: profile,
      alertaVazaoExcedida: exceedsFlow
          ? 'A vazão adotada ultrapassa o limite não erosivo para a declividade informada.'
          : null,
      resumoTextual:
          'Cálculo conforme a planilha de referência: Ti = Ta + To, '
          'infiltração acumulada = aI·To^n e qmáx = C/S0^a (textura: ${params.texturaSolo.displayName}). '
          'Tipo: ${tipo.displayName}. '
          'Manejo: ${params.manejoSulco.displayName}.',
      metricas: {
        'Vazão por sulco': params.vazao,
        'Vazão máxima não erosiva': maximumFlowLps,
        'Tempo de avanco': params.tempoAvancoFinalMin,
        'Tempo de oportunidade': opportunityMin,
        'Tempo de aplicação calculado': applicationTimeMin,
        'Expoente da curva de avanço': advance.exponent,
        'Lâmina aplicada': appliedDepthM * 1000,
        'Lâmina média infiltrada': balance.meanInfiltratedDepthM * 1000,
        'Eficiência de distribuição': distributionEfficiency,
        'Eficiência de condução': conductionEfficiency,
        'Grau de adequação': adequacyDegree,
        'Resíduo do balanço': balance.residualPercent,
        'Declividade longitudinal': params.declividade,
        'Balanço - Aproveitado': balance.applicationEfficiency,
        'Balanço - Percolação': balance.deepPercolationPercent,
        'Balanço - Escoamento': balance.runoffPercent,
        'Lâmina útil': usefulDepthM * 1000,
        'Lâmina percolada': percolatedDepthM * 1000,
        'Lâmina escoada': runoffDepthM * 1000,
        'Déficit de lâmina': deficitMm,
        ...metricasAdicionais,
      },
      unidadesMetricas: const {
        'Vazão por sulco': 'L/s',
        'Vazão máxima não erosiva': 'L/s',
        'Tempo de avanco': 'min',
        'Tempo de oportunidade': 'min',
        'Tempo de aplicação calculado': 'min',
        'Expoente da curva de avanço': '',
        'Lâmina aplicada': 'mm',
        'Lâmina média infiltrada': 'mm',
        'Eficiência de distribuição': '%',
        'Eficiência de condução': '%',
        'Grau de adequação': '%',
        'Resíduo do balanço': '%',
        'Declividade longitudinal': 'm/m',
        'Balanço - Aproveitado': '%',
        'Balanço - Percolação': '%',
        'Balanço - Escoamento': '%',
        'Lâmina útil': 'mm',
        'Lâmina percolada': 'mm',
        'Lâmina escoada': 'mm',
        'Déficit de lâmina': 'mm',
        'Vazão original': 'L/s',
        'Vazão reduzida': 'L/s',
        'Tempo de mudança': 'min',
        'Ciclo de surtirção': 'min',
        'Pausa entre ciclos': 'min',
        'Número de ciclos': '',
        'Fator de redução surtir': '',
      },
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
    if (params.comprimento <= 0 ||
        params.larguraOuEspacamento <= 0 ||
        params.vazao <= 0 ||
        params.declividade <= 0 ||
        params.laminaRequerida <= 0 ||
        params.k <= 0 ||
        params.a <= 0) {
      throw const FormatException(
        'Revise geometria, declividade, vazão, infiltração e lâmina requerida.',
      );
    }
    if (params.tempoAplicacao < 0 ||
        params.tempoAvancoMetadeMin <= 0 ||
        params.tempoAvancoFinalMin <= 0 ||
        params.tempoAvancoMetadeMin >= params.tempoAvancoFinalMin) {
      throw const FormatException('Revise os tempos de avanço e oportunidade.');
    }
    if (params.manejoSulco == ManejoSulco.reduzida &&
        (params.vazaoReduzidaLs <= 0 ||
            params.vazaoReduzidaLs > params.vazao ||
            params.tempoMudancaMin < 0 ||
            params.tempoMudancaMin > params.tempoAplicacao)) {
      throw const FormatException(
        'Revise a vazão reduzida e o atraso após o avanço.',
      );
    }
    if (params.manejoSulco == ManejoSulco.surtir) {
      throw const FormatException(
        'Surtirção exige um modelo de infiltração calibrado e ainda não é calculada.',
      );
    }
  }
}
