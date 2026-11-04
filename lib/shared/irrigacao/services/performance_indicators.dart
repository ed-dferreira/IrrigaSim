import 'dart:math';

import 'kostiakov_lewis.dart';

class PerformanceIndicators {
  static double calcularEa(double laminaArmazenada, double laminaAplicada) {
    if (laminaAplicada <= 0) return 0;
    return (laminaArmazenada / laminaAplicada) * 100;
  }

  static double calcularEr(List<double> laminas, double laminaNecessaria) {
    if (laminas.isEmpty || laminaNecessaria <= 0) return 0;
    double soma = 0;
    for (final z in laminas) {
      soma += z < laminaNecessaria ? z : laminaNecessaria;
    }
    return (soma / (laminaNecessaria * laminas.length)) * 100;
  }

  static double calcularCuc(List<double> laminas) {
    if (laminas.isEmpty) return 0;
    final media = laminas.reduce((a, b) => a + b) / laminas.length;
    if (media <= 0) return 0;
    double somaAbs = 0;
    for (final z in laminas) {
      somaAbs += (z - media).abs();
    }
    return (1 - somaAbs / (laminas.length * media)) * 100;
  }

  static double calcularDu(List<double> laminas) {
    if (laminas.isEmpty) return 0;
    final sorted = List<double>.from(laminas)..sort();
    final n = sorted.length;
    final limite = max(1, n ~/ 3);
    final tercoInferior = sorted.sublist(0, limite);
    final mediaGeral = laminas.reduce((a, b) => a + b) / n;
    if (mediaGeral <= 0) return 0;
    final mediaInferior =
        tercoInferior.reduce((a, b) => a + b) / tercoInferior.length;
    return (mediaInferior / mediaGeral) * 100;
  }

  static double calcularPerdaPercolacao(
    double laminaMedia,
    double laminaNecessaria,
    double laminaAplicada,
  ) {
    if (laminaAplicada <= 0) return 0;
    final excesso = laminaMedia - laminaNecessaria;
    if (excesso <= 0) return 0;
    return (excesso / laminaAplicada) * 100;
  }

  static double calcularPerdaEscoamento(double ea, double perdaPercolacao) {
    return 100 - ea - perdaPercolacao;
  }

  static String classificarEa(double ea) {
    if (ea >= 85) return 'Excelente';
    if (ea >= 75) return 'Bom';
    if (ea >= 65) return 'Regular';
    return 'Ruim';
  }

  static String classificarCuc(double cuc) {
    if (cuc >= 90) return 'Excelente';
    if (cuc >= 80) return 'Bom';
    if (cuc >= 70) return 'Regular';
    return 'Ruim';
  }

  static String classificarDu(double du) {
    if (du >= 85) return 'Excelente';
    if (du >= 75) return 'Bom';
    if (du >= 65) return 'Regular';
    return 'Ruim';
  }

  static List<double> perfilLongitudinal({
    required double comprimento,
    required double tempoTotal,
    required double tempoAvanco,
    required double k,
    required double a,
    required double vib,
    int pontos = 20,
  }) {
    if (comprimento <= 0 || pontos <= 0) return [];

    List<double> laminas = [];
    double dx = comprimento / pontos;

    for (int i = 0; i <= pontos; i++) {
      double x = i * dx;
      double fracao = x / comprimento;
      double tau = tempoTotal - tempoAvanco * fracao;
      tau = max(0.0, tau);
      laminas.add(KostiakovLewis.infiltracaoAcumulada(tau, k, a, vib));
    }

    return laminas;
  }
}
