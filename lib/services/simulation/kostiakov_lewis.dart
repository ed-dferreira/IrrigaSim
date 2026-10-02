import 'dart:math';

import 'package:irrigasim/models/simulation_result.dart';

class KostiakovLewis {
  static double infiltracaoAcumulada(
    double tau,
    double k,
    double a,
    double vib,
  ) {
    if (tau <= 0) return 0;
    return k * pow(tau, a) + vib * tau;
  }

  static double taxaInfiltracao(double tau, double k, double a, double vib) {
    if (tau <= 0) return double.infinity;
    return k * a * pow(tau, a - 1) + vib;
  }

  static double tempoParaLamina(double lamina, double k, double a, double vib) {
    if (lamina <= 0) return 0;

    double f(double tau) => k * pow(tau, a) + vib * tau - lamina;
    double fPrime(double tau) => k * a * pow(tau, a - 1) + vib;

    double tau = lamina / (k + vib);
    if (tau < 0.001) tau = 0.001;

    double aLower = 0.001;
    double bUpper = lamina * 10;

    for (int i = 0; i < 100; i++) {
      double fx = f(tau);

      if (fx.abs() < 1e-10) break;

      double fp = fPrime(tau);
      double tauNew = tau - fx / fp;

      if (tauNew < aLower || tauNew > bUpper || tauNew.isNaN) {
        tauNew = (aLower + bUpper) / 2;
      }

      if ((tauNew - tau).abs() < 1e-10) break;

      if (f(tauNew).abs() < f(tau).abs()) {
        tau = tauNew;
      } else {
        double mid = (aLower + bUpper) / 2;
        tau = mid;
        if (f(mid) > 0) {
          bUpper = mid;
        } else {
          aLower = mid;
        }
      }
    }

    return tau;
  }

  static List<PontoGrafico> gerarPerfil(
    double tempoTotal,
    double k,
    double a,
    double vib,
  ) {
    List<PontoGrafico> pontos = [];
    int passos = tempoTotal.ceil().clamp(1, 300);
    for (int t = 0; t <= passos; t++) {
      pontos.add(
        PontoGrafico(
          t.toDouble(),
          infiltracaoAcumulada(t.toDouble(), k, a, vib),
        ),
      );
    }
    return pontos;
  }
}
