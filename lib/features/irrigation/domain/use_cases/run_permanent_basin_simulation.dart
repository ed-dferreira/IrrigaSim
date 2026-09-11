import 'dart:math';

import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/domain/entities/simulation_result.dart';

class RunPermanentBasinSimulation {
  SimulationResult call(IrrigationParameters params) {
    _validate(params);

    final rootDepthCm = params.profundidadeCamadaMm / 10;
    final turnDays =
        params.dtaMmCm *
        params.fatorDisponibilidade *
        rootDepthCm /
        params.evapotranspiracaoMmDia;
    final adoptedTurnDays = max(1.0, turnDays).toDouble();
    final fillFlowLps =
        0.116 *
        (params.porosidade * params.profundidadeCamadaMm +
            params.laminaSuperficialMm +
            params.evapotranspiracaoMmDia * adoptedTurnDays +
            params.condutividadeHidraulicaMmDia * adoptedTurnDays) *
        params.areaHectares /
        adoptedTurnDays;
    final maintenanceFlowLps =
        0.116 *
        (params.evapotranspiracaoMmDia + params.condutividadeHidraulicaMmDia) *
        params.areaHectares;
    final conductionEfficiency =
        (maintenanceFlowLps / params.vazaoDisponivelLps * 100).clamp(0, 100);
    final areaM2 = params.areaHectares * 10000;
    final soilStorageM3 =
        params.porosidade *
        params.profundidadeCamadaMm *
        params.areaHectares *
        10;
    final surfaceStorageM3 =
        params.laminaSuperficialMm * params.areaHectares * 10;
    final evapotranspirationDuringFillM3 =
        params.evapotranspiracaoMmDia *
        adoptedTurnDays *
        params.areaHectares *
        10;
    final percolationDuringFillM3 =
        params.condutividadeHidraulicaMmDia *
        adoptedTurnDays *
        params.areaHectares *
        10;
    final fillVolumeM3 =
        soilStorageM3 +
        surfaceStorageM3 +
        evapotranspirationDuringFillM3 +
        percolationDuringFillM3;
    final fillTimeHours = fillVolumeM3 / (params.vazaoDisponivelLps * 3.6);
    final waterDepthM = params.laminaSuperficialMm / 1000;

    final curve = <PontoGrafico>[];
    for (var i = 0; i <= 12; i++) {
      final fraction = i / 12;
      curve.add(
        PontoGrafico(
          fillTimeHours * 60 * fraction,
          params.comprimento * fraction,
        ),
      );
    }

    return SimulationResult(
      eficiencia: conductionEfficiency.toDouble(),
      eficienciaRequerimento: 100,
      cuc: 0,
      du: 0,
      laminaMedia: waterDepthM,
      laminaRequerida: waterDepthM,
      tempoAvanco: fillTimeHours * 60,
      perdaPercolacao: 0,
      perdaEscoamento: 0,
      curvaAvanco: curve,
      perfilLongitudinal: List.filled(21, waterDepthM),
      alertaVazaoExcedida: fillFlowLps > params.vazaoDisponivelLps
          ? 'A fonte não atende à vazão de enchimento recomendada.'
          : maintenanceFlowLps > params.vazaoDisponivelLps
          ? 'A fonte não atende à vazão de manutenção.'
          : null,
      metricas: {
        'Turno de rega': adoptedTurnDays,
        'Área irrigada': params.areaHectares,
        'Vazão de enchimento': fillFlowLps,
        'Vazão de manutenção': maintenanceFlowLps,
        'Vazão disponível': params.vazaoDisponivelLps,
        'Tempo de enchimento': fillTimeHours,
        'Volume de enchimento': fillVolumeM3,
        'Armazenamento no solo': soilStorageM3,
        'Armazenamento superficial': surfaceStorageM3,
        'ET durante enchimento': evapotranspirationDuringFillM3,
        'Percolação durante enchimento': percolationDuringFillM3,
        'Lâmina superficial': params.laminaSuperficialMm,
        'Eficiência de condução': conductionEfficiency.toDouble(),
        'Área do tabuleiro': areaM2,
      },
      unidadesMetricas: const {
        'Turno de rega': 'dias',
        'Área irrigada': 'ha',
        'Vazão de enchimento': 'L/s',
        'Vazão de manutenção': 'L/s',
        'Vazão disponível': 'L/s',
        'Tempo de enchimento': 'h',
        'Volume de enchimento': 'm³',
        'Armazenamento no solo': 'm³',
        'Armazenamento superficial': 'm³',
        'ET durante enchimento': 'm³',
        'Percolação durante enchimento': 'm³',
        'Lâmina superficial': 'mm',
        'Eficiência de condução': '%',
        'Área do tabuleiro': 'm²',
      },
      resumoTextual:
          'A vazão de enchimento forma a lâmina inicial. '
          'Depois, a vazão de manutenção repõe evapotranspiração e percolação.',
    );
  }

  void _validate(IrrigationParameters params) {
    if (params.areaHectares <= 0 ||
        params.profundidadeCamadaMm <= 0 ||
        params.evapotranspiracaoMmDia <= 0 ||
        params.vazaoDisponivelLps <= 0) {
      throw const FormatException(
        'Revise área, profundidade, evapotranspiração e vazão disponível.',
      );
    }
    if (params.porosidade <= 0 || params.porosidade > 1) {
      throw const FormatException('A porosidade deve estar entre 0 e 1.');
    }
  }
}
