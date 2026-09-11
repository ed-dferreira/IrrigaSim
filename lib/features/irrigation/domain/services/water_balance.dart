import 'dart:math';

import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';

class WaterBalance {
  static double calcularAvanco({
    required double volumeAplicado,
    required double volumeInfiltrado,
    required double area,
  }) {
    if (area <= 0) return 0;
    return (volumeAplicado - volumeInfiltrado) / area;
  }

  static double calcularVolumeInfiltrado({
    required double tempo,
    required double distancia,
    required double largura,
    required IrrigationParameters params,
  }) {
    if (tempo <= 0 || distancia <= 0) return 0;

    return largura *
        distancia *
        (params.k * pow(tempo, params.a) / (params.a + 1) +
            params.vib * tempo / 2);
  }

  static double calcularVolumeSuperficie({
    required double distancia,
    required double largura,
    required double profundidadeMedia,
  }) {
    if (distancia <= 0 || largura <= 0) return 0;
    return distancia * largura * profundidadeMedia;
  }
}
