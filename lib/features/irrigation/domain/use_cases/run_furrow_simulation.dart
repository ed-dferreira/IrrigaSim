import 'dart:math';

import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/domain/entities/simulation_result.dart';
import 'package:irrigasim/features/irrigation/domain/services/kostiakov_lewis.dart';
import 'package:irrigasim/features/irrigation/domain/services/performance_indicators.dart';

class RunFurrowSimulation {
  SimulationResult call(IrrigationParameters params) {
    final base = params.larguraOuEspacamento;
    const inclinacao = 2.0;

    final profundidadeNormal = _calcularProfundidadeNormal(
      params.vazao,
      params.manningN,
      params.declividade,
      base,
      inclinacao,
    );

    final qmax = _calcularQmax(
      params.declividade,
      params.manningN,
      base,
      inclinacao,
    );

    String? alertaVazao;
    if (params.vazao > qmax) {
      alertaVazao =
          'Vazão excedida (Q=${params.vazao.toStringAsFixed(1)} L/s > Qmax=${qmax.toStringAsFixed(1)} L/s)';
    }

    final avanco = _calcularAvanco(params, base, inclinacao);
    final tempoTotal = avanco.tempoFinal;

    final perfil = _calcularPerfilLongitudinal(params, avanco.tempoFinal);

    final laminaMedia =
        perfil.isEmpty ? 0.0 : perfil.reduce((a, b) => a + b) / perfil.length;
    final laminaAplicada = params.vazao * tempoTotal * 60 /
        (params.comprimento * params.larguraOuEspacamento * 1000);

    final ea = PerformanceIndicators.calcularEa(laminaMedia, laminaAplicada);
    final er =
        PerformanceIndicators.calcularEr(perfil, params.laminaRequerida);
    final cuc = PerformanceIndicators.calcularCuc(perfil);
    final du = PerformanceIndicators.calcularDu(perfil);

    final perdaPercolacao = PerformanceIndicators.calcularPerdaPercolacao(
      laminaMedia,
      params.laminaRequerida,
      laminaAplicada,
    );
    final perdaEscoamento =
        PerformanceIndicators.calcularPerdaEscoamento(ea, perdaPercolacao);

    final resumo = _gerarResumo(
      params,
      ea,
      er,
      cuc,
      du,
      avanco.tempoFinal,
      laminaMedia,
      profundidadeNormal,
      qmax,
      base,
      inclinacao,
    );

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

  static double _calcularAreaSecao(double y, double base, double inclinacao) {
    return (base + inclinacao * y) * y;
  }

  static double _calcularPerimetroMolhado(double y, double base, double inclinacao) {
    return base + 2 * y * sqrt(1 + inclinacao * inclinacao);
  }

  static double _calcularHidraulicoRaio(double y, double base, double inclinacao) {
    final area = _calcularAreaSecao(y, base, inclinacao);
    final perimetro = _calcularPerimetroMolhado(y, base, inclinacao);
    if (perimetro <= 0) return 0;
    return area / perimetro;
  }

  static double _manningQ(
    double y,
    double manningN,
    double declividade,
    double base,
    double inclinacao,
  ) {
    final area = _calcularAreaSecao(y, base, inclinacao);
    final rh = _calcularHidraulicoRaio(y, base, inclinacao);
    return (1 / manningN) * area * pow(rh, 2.0 / 3.0) * sqrt(declividade);
  }

  static double _calcularProfundidadeNormal(
    double vazao,
    double manningN,
    double declividade,
    double base,
    double inclinacao,
  ) {
    double yMin = 0.001;
    double yMax = 1.0;

    for (int i = 0; i < 50; i++) {
      final yMid = (yMin + yMax) / 2;
      final qCalc = _manningQ(yMid, manningN, declividade, base, inclinacao);
      if (qCalc < vazao) {
        yMin = yMid;
      } else {
        yMax = yMid;
      }
    }
    return (yMin + yMax) / 2;
  }

  static double _calcularQmax(
    double declividade,
    double manningN,
    double base,
    double inclinacao,
  ) {
    const froudeLimite = 0.6;
    const g = 9.81;

    double yMin = 0.001;
    double yMax = 2.0;

    for (int i = 0; i < 50; i++) {
      final yMid = (yMin + yMax) / 2;
      final q = _manningQ(yMid, manningN, declividade, base, inclinacao);
      final area = _calcularAreaSecao(yMid, base, inclinacao);
      final hidraulico = area > 0 ? area / (base + 2 * yMid) : 0;
      final velocidade = area > 0 ? q / area : 0;
      final froude = hidraulico > 0 ? velocidade / sqrt(g * hidraulico) : 0;

      if (froude < froudeLimite) {
        yMin = yMid;
      } else {
        yMax = yMid;
      }
    }

    return _manningQ((yMin + yMax) / 2, manningN, declividade, base, inclinacao);
  }

  _AvancoResult _calcularAvanco(
    IrrigationParameters params,
    double base,
    double inclinacao,
  ) {
    double tempo = 0;
    double distancia = 0;
    List<PontoGrafico> curva = [];

    curva.add(PontoGrafico(0, 0));

    while (distancia < params.comprimento && tempo < 300) {
      tempo += 1;
      final volumeAplicado = params.vazao * tempo * 60;

      double volumeInfiltrado = 0;
      if (distancia > 0) {
        final tauMontante = tempo;
        final tauJusante = max(0.0, tempo - (distancia / params.comprimento) * tempo);
        final laminaMontante = KostiakovLewis.infiltracaoAcumulada(
            tauMontante, params.k, params.a, params.vib);
        final laminaJusante = KostiakovLewis.infiltracaoAcumulada(
            tauJusante, params.k, params.a, params.vib);
        final laminaMediaLocal = (laminaMontante + laminaJusante) / 2;
        volumeInfiltrado = params.larguraOuEspacamento * distancia * laminaMediaLocal;
      }

      final volumeDisponivel = volumeAplicado - volumeInfiltrado;
      final areaSecao = _calcularAreaSecao(
        _profundidadeNormal(params),
        base,
        inclinacao,
      );

      if (volumeDisponivel > 0 && areaSecao > 0) {
        distancia = volumeDisponivel / (params.sigmaZ * areaSecao);
      } else {
        distancia = 0;
      }

      curva.add(PontoGrafico(tempo.toDouble(), distancia));
    }

    return _AvancoResult(
      tempoFinal: tempo,
      distanciaFinal: distancia,
      curva: curva,
    );
  }

  double _profundidadeNormal(IrrigationParameters params) {
    return _calcularProfundidadeNormal(
      params.vazao,
      params.manningN,
      params.declividade,
      params.larguraOuEspacamento,
      2.0,
    );
  }

  List<double> _calcularPerfilLongitudinal(
    IrrigationParameters params,
    double tempoAvanco,
  ) {
    const int n = 20;
    final double dx = params.comprimento / n;
    List<double> laminas = [];

    for (int i = 0; i <= n; i++) {
      final double x = i * dx;
      final double fracao = x / params.comprimento;
      final double tau = tempoAvanco * (1 - fracao);
      laminas.add(KostiakovLewis.infiltracaoAcumulada(
          max(0.0, tau), params.k, params.a, params.vib));
    }

    return laminas;
  }

  String _gerarResumo(
    IrrigationParameters params,
    double ea,
    double er,
    double cuc,
    double du,
    double tempoAvanco,
    double laminaMedia,
    double profundidadeNormal,
    double qmax,
    double base,
    double inclinacao,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('=== Simulação de Sulco (Furrow) ===');
    buffer.writeln('Vazão: ${params.vazao.toStringAsFixed(2)} L/s');
    buffer.writeln('Qmax (Froude): ${qmax.toStringAsFixed(2)} L/s');
    buffer.writeln('Comprimento: ${params.comprimento.toStringAsFixed(1)} m');
    buffer.writeln('Base do sulco: ${base.toStringAsFixed(3)} m');
    buffer.writeln('Inclinação lateral: ${inclinacao.toStringAsFixed(1)}');
    buffer.writeln('Profundidade normal: ${(profundidadeNormal * 1000).toStringAsFixed(2)} mm');
    buffer.writeln('');
    buffer.writeln('Tempo de avanço: ${tempoAvanco.toStringAsFixed(0)} min');
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
