import 'dart:math';

import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/domain/entities/simulation_result.dart';
import 'package:irrigasim/features/irrigation/domain/services/kostiakov_lewis.dart';
import 'package:irrigasim/features/irrigation/domain/services/performance_indicators.dart';

class RunBasinSimulation {
  SimulationResult call(IrrigationParameters params) {
    final area = _calcularArea(params.comprimento, params.larguraOuEspacamento);
    final tempoEnchimento = _calcularTempoEnchimento(
      area,
      params.vazao,
      params.laminaRequerida,
    );
    final tempoCorte = _calcularTempoCorte(params);

    final tempoTotal = tempoEnchimento + tempoCorte;

    final perfil = _calcularPerfilLongitudinal(params, tempoEnchimento, tempoCorte);

    final laminaMedia =
        perfil.isEmpty ? 0.0 : perfil.reduce((a, b) => a + b) / perfil.length;
    final laminaAplicada = _calcularLaminaAplicada(
      params.vazao,
      tempoTotal,
      area,
    );

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

    final volumeAplicado = params.vazao * tempoTotal * 60;
    final volumeArmazenado = laminaMedia * area * 1000;

    final resumo = _gerarResumo(
      params,
      ea,
      er,
      cuc,
      du,
      tempoEnchimento,
      tempoCorte,
      laminaMedia,
      area,
      volumeAplicado,
      volumeArmazenado,
    );

    return SimulationResult(
      eficiencia: ea,
      eficienciaRequerimento: er,
      cuc: cuc,
      du: du,
      laminaMedia: laminaMedia,
      laminaRequerida: params.laminaRequerida,
      tempoAvanco: tempoEnchimento,
      perdaPercolacao: perdaPercolacao,
      perdaEscoamento: perdaEscoamento,
      curvaAvanco: _gerarCurvaEnchimento(params, tempoEnchimento, area),
      perfilLongitudinal: perfil,
      resumoTextual: resumo,
    );
  }

  static double _calcularArea(double comprimento, double largura) {
    return comprimento * largura;
  }

  static double _calcularTempoEnchimento(
    double area,
    double vazao,
    double laminaRequerida,
  ) {
    if (vazao <= 0 || area <= 0) return 0;
    final volumeNecessario = area * laminaRequerida / 1000;
    return volumeNecessario / (vazao / 1000);
  }

  static double _calcularTempoCorte(IrrigationParameters params) {
    return KostiakovLewis.tempoParaLamina(
      params.laminaRequerida,
      params.k,
      params.a,
      params.vib,
    );
  }

  static double _calcularLaminaAplicada(
    double vazao,
    double tempoTotal,
    double area,
  ) {
    if (area <= 0) return 0;
    final volumeAplicado = vazao * tempoTotal * 60;
    return volumeAplicado / (area * 1000);
  }

  List<double> _calcularPerfilLongitudinal(
    IrrigationParameters params,
    double tempoEnchimento,
    double tempoCorte,
  ) {
    const int n = 20;
    final double dx = params.comprimento / n;
    List<double> laminas = [];

    for (int i = 0; i <= n; i++) {
      final double x = i * dx;
      final double fracaoDistancia = x / params.comprimento;

      final double tauJusante =
          (tempoEnchimento + tempoCorte) * (1 - fracaoDistancia);
      final double tau = max(0.0, tauJusante);

      laminas.add(
          KostiakovLewis.infiltracaoAcumulada(tau, params.k, params.a, params.vib));
    }

    return laminas;
  }

  List<PontoGrafico> _gerarCurvaEnchimento(
    IrrigationParameters params,
    double tempoEnchimento,
    double area,
  ) {
    List<PontoGrafico> curva = [];
    int passos = max(1, tempoEnchimento.ceil());
    for (int t = 0; t <= passos; t++) {
      final tempo = t.toDouble();
      final volumeAplicado = params.vazao * tempo * 60;
      final profundidade = area > 0 ? volumeAplicado / (area * 1000) : 0.0;
      curva.add(PontoGrafico(tempo, profundidade * 1000));
    }
    return curva;
  }

  String _gerarResumo(
    IrrigationParameters params,
    double ea,
    double er,
    double cuc,
    double du,
    double tempoEnchimento,
    double tempoCorte,
    double laminaMedia,
    double area,
    double volumeAplicado,
    double volumeArmazenado,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('=== Simulação de Inundação (Basin) ===');
    buffer.writeln('Vazão: ${params.vazao.toStringAsFixed(2)} L/s');
    buffer.writeln('Comprimento: ${params.comprimento.toStringAsFixed(1)} m');
    buffer.writeln('Largura: ${params.larguraOuEspacamento.toStringAsFixed(1)} m');
    buffer.writeln('Área: ${area.toStringAsFixed(1)} m²');
    buffer.writeln('');
    buffer.writeln('Tempo de enchimento: ${tempoEnchimento.toStringAsFixed(1)} min');
    buffer.writeln('Tempo de corte: ${tempoCorte.toStringAsFixed(1)} min');
    buffer.writeln('Tempo total: ${(tempoEnchimento + tempoCorte).toStringAsFixed(1)} min');
    buffer.writeln('');
    buffer.writeln('Lâmina média: ${(laminaMedia * 1000).toStringAsFixed(2)} mm');
    buffer.writeln('Lâmina requerida: ${params.laminaRequerida.toStringAsFixed(2)} mm');
    buffer.writeln('Volume aplicado: ${volumeAplicado.toStringAsFixed(0)} L');
    buffer.writeln('Volume armazenado: ${volumeArmazenado.toStringAsFixed(0)} L');
    buffer.writeln('');
    buffer.writeln('Ea: ${ea.toStringAsFixed(1)}% (${PerformanceIndicators.classificarEa(ea)})');
    buffer.writeln('Er: ${er.toStringAsFixed(1)}%');
    buffer.writeln('CUC: ${cuc.toStringAsFixed(1)}% (${PerformanceIndicators.classificarCuc(cuc)})');
    buffer.writeln('DU: ${du.toStringAsFixed(1)}% (${PerformanceIndicators.classificarDu(du)})');
    return buffer.toString();
  }
}
