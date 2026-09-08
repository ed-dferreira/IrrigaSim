import 'dart:math';

import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/domain/entities/simulation_result.dart';
import 'package:irrigasim/features/irrigation/domain/services/kostiakov_lewis.dart';
import 'package:irrigasim/features/irrigation/domain/services/performance_indicators.dart';

class RunBorderSimulation {
  SimulationResult call(IrrigationParameters params) {
    final qmax = calcularQmax(
      params.larguraOuEspacamento,
      params.declividade,
      params.manningN,
    );
    final qmin = calcularQmin(
      params.comprimento,
      params.larguraOuEspacamento,
      params.k,
      params.a,
      params.vib,
      params.laminaRequerida,
      params.tempoAplicacao,
    );

    String? alertaVazao;
    if (params.vazao > qmax) {
      alertaVazao = 'Vazão excedida (Q=${params.vazao.toStringAsFixed(1)} L/s > Qmax=${qmax.toStringAsFixed(1)} L/s)';
    } else if (params.vazao < qmin) {
      alertaVazao = 'Vazão insuficiente para atingir comprimento (Q=${params.vazao.toStringAsFixed(1)} L/s < Qmin=${qmin.toStringAsFixed(1)} L/s)';
    }

    final avanco = _calcularAvanco(params);
    final tempoRecessao = _calcularRecessao(params, avanco.tempoFinal);
    final tempoTotal = avanco.tempoFinal + tempoRecessao;

    final perfil = PerformanceIndicators.perfilLongitudinal(
      comprimento: params.comprimento,
      tempoTotal: tempoTotal,
      tempoAvanco: avanco.tempoFinal,
      k: params.k,
      a: params.a,
      vib: params.vib,
    );

    final laminaMedia = perfil.isEmpty
        ? 0.0
        : perfil.reduce((a, b) => a + b) / perfil.length;
    final laminaAplicada = params.vazao * tempoTotal * 60 /
        (params.comprimento * params.larguraOuEspacamento * 1000);

    final ea = PerformanceIndicators.calcularEa(laminaMedia, laminaAplicada);
    final er = PerformanceIndicators.calcularEr(perfil, params.laminaRequerida);
    final cuc = PerformanceIndicators.calcularCuc(perfil);
    final du = PerformanceIndicators.calcularDu(perfil);

    final perdaPercolacao = PerformanceIndicators.calcularPerdaPercolacao(
      laminaMedia,
      params.laminaRequerida,
      laminaAplicada,
    );
    final perdaEscoamento = PerformanceIndicators.calcularPerdaEscoamento(ea, perdaPercolacao);

    final resumo = _gerarResumo(params, ea, er, cuc, du, avanco.tempoFinal,
        tempoRecessao, laminaMedia, qmax, qmin);

    return SimulationResult(
      eficiencia: ea,
      eficienciaRequerimento: er,
      cuc: cuc,
      du: du,
      laminaMedia: laminaMedia,
      laminaRequerida: params.laminaRequerida,
      tempoAvanco: avanco.tempoFinal,
      perdaPercolacao: perdaPercolacao,
      perdaEscoamento: perdaEscoamento,
      curvaAvanco: avanco.curva,
      perfilLongitudinal: perfil,
      resumoTextual: resumo,
      alertaVazaoExcedida: alertaVazao,
    );
  }

  static double calcularQmax(double largura, double declividade, double manningN) {
    const profundidadeCritica = 0.05;
    return (1 / manningN) *
        (largura * profundidadeCritica) *
        pow(profundidadeCritica, 2.0 / 3.0) *
        sqrt(declividade);
  }

  static double calcularQmin(
    double comprimento,
    double largura,
    double k,
    double a,
    double vib,
    double laminaRequerida,
    double tempoAplicacao,
  ) {
    if (tempoAplicacao <= 0 || comprimento <= 0 || largura <= 0) return 0;
    final tempoHoras = tempoAplicacao / 60;
    final laminaEfetiva = laminaRequerida / 1000;
    return (comprimento * largura * laminaEfetiva) / (tempoHoras * 3600);
  }

  _AvancoResult _calcularAvanco(IrrigationParameters params) {
    double tempo = 0;
    double distancia = 0;
    List<PontoGrafico> curva = [];
    final largura = params.larguraOuEspacamento;

    curva.add(PontoGrafico(0, 0));

    while (distancia < params.comprimento && tempo < 300) {
      tempo += 1;
      final volumeAplicado = params.vazao * tempo * 60;

      double volumeInfiltrado = 0;
      if (distancia > 0) {
        final profundidadeMedia = _profundidadeMedia(tempo, params);
        volumeInfiltrado = largura * distancia * profundidadeMedia;
      }

      final volumeDisponivel = volumeAplicado - volumeInfiltrado;
      final profundidadeNova = _profundidadeMedia(tempo, params);
      if (profundidadeNova > 0) {
        distancia = volumeDisponivel / (largura * profundidadeNova);
      }
      if (distancia < 0) distancia = 0;

      curva.add(PontoGrafico(tempo.toDouble(), distancia));
    }

    return _AvancoResult(
      tempoFinal: tempo,
      distanciaFinal: distancia,
      curva: curva,
    );
  }

  double _profundidadeMedia(double tempo, IrrigationParameters params) {
    final lamina = KostiakovLewis.infiltracaoAcumulada(tempo, params.k, params.a, params.vib);
    return lamina * params.sigmaZ;
  }

  static double _calcularRecessao(IrrigationParameters params, double tempoAvanco) {
    final fator = 0.3 * pow(params.declividade, 0.2) *
        pow(params.manningN, 0.1);
    return tempoAvanco * fator.clamp(0.1, 0.5);
  }

  String _gerarResumo(
    IrrigationParameters params,
    double ea,
    double er,
    double cuc,
    double du,
    double tempoAvanco,
    double tempoRecessao,
    double laminaMedia,
    double qmax,
    double qmin,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('=== Simulação de Faixa (Border) ===');
    buffer.writeln('Vazão: ${params.vazao.toStringAsFixed(2)} L/s');
    buffer.writeln('Qmin: ${qmin.toStringAsFixed(2)} L/s | Qmax: ${qmax.toStringAsFixed(2)} L/s');
    buffer.writeln('Comprimento: ${params.comprimento.toStringAsFixed(1)} m');
    buffer.writeln('Largura: ${params.larguraOuEspacamento.toStringAsFixed(1)} m');
    buffer.writeln('');
    buffer.writeln('Tempo de avanço: ${tempoAvanco.toStringAsFixed(0)} min');
    buffer.writeln('Tempo de recessão: ${tempoRecessao.toStringAsFixed(1)} min');
    buffer.writeln('Lâmina média: ${(laminaMedia * 1000).toStringAsFixed(2)} mm');
    buffer.writeln('Lâmina requerida: ${params.laminaRequerida.toStringAsFixed(2)} mm');
    buffer.writeln('');
    buffer.writeln('Ea: ${ea.toStringAsFixed(1)}% (${PerformanceIndicators.classificarEa(ea)})');
    buffer.writeln('Er: ${er.toStringAsFixed(1)}%');
    buffer.writeln('CUC: ${cuc.toStringAsFixed(1)}% (${PerformanceIndicators.classificarCuc(cuc)})');
    buffer.writeln('DU: ${du.toStringAsFixed(1)}% (${PerformanceIndicators.classificarDu(du)})');
    return buffer.toString();
  }
}

class _AvancoResult {
  final double tempoFinal;
  final double distanciaFinal;
  final List<PontoGrafico> curva;

  const _AvancoResult({
    required this.tempoFinal,
    required this.distanciaFinal,
    required this.curva,
  });
}
