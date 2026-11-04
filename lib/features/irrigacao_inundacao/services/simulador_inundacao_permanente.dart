import 'dart:math';

import 'package:irrigasim/features/irrigacao_inundacao/models/anexos_inundacao.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';

import 'planejamento_inundacao.dart';
import 'nucleo_referencia_inundacao.dart';

/// Inundação permanente pela referência da Aula 8 (pp. 64–73).
///
/// TR, Qe e Qm vêm do núcleo da referência (fator 0,116). Las e Ea seguem
/// a p. 72 com período semanal; Ec = 100 Qm/Qd. A declividade é validada
/// < 2% (G9) e a checagem operacional G3 compara a vazão de enchimento com
/// a disponível e a geometria do tabuleiro com a área declarada.
class SimuladorInundacaoPermanente {
  /// Período semanal da Ea (p. 72): Les e Las são lâminas semanais.
  static const double _horasSemana = 168;
  static const double _diasSemana = 7;

  SimulationResult call(IrrigationParameters params) {
    _validar(params);

    final profundidadeCamadaCm = params.profundidadeCamadaMm / 10;
    final turnoDias = _doNucleo(
      () => turnoRega(
        params.dtaMmCm,
        params.fatorDisponibilidade,
        profundidadeCamadaCm,
        params.evapotranspiracaoMmDia,
      ),
    );
    final adoptedTurnDays = max(1.0, turnoDias).toDouble();
    final fluxos = _doNucleo(
      () => continua(
        porosidade: params.porosidade,
        zMm: params.profundidadeCamadaMm,
        laminaMm: params.laminaSuperficialMm,
        etMmDia: params.evapotranspiracaoMmDia,
        kMmDia: params.condutividadeHidraulicaMmDia,
        areaHa: params.areaHectares,
        turnoDias: adoptedTurnDays,
      ),
    );
    final vazaoEnchimentoLs = fluxos.qeLS;
    final vazaoManutencaoLs = fluxos.qmLS;
    final areaM2 = params.areaHectares * 10000;
    final eficienciaConducao =
        (vazaoManutencaoLs / params.vazaoDisponivelLps * 100)
            .clamp(0, 100)
            .toDouble();
    final lasMm = _doNucleo(
      () => laminaAplicada(vazaoManutencaoLs, _horasSemana, areaM2),
    );
    final lesMm = params.evapotranspiracaoMmDia * _diasSemana;
    final applicationEfficiency = lasMm > 0
        ? _doNucleo(() => eficienciaRazao(min(lesMm, lasMm), lasMm))
        : 0.0;
    final checagem = const PlanejamentoInundacao().checarOperacao(
      vazaoPlanejadaLs: vazaoEnchimentoLs,
      vazaoDisponivelLs: params.vazaoDisponivelLps,
      areaTabuleiroM2: params.comprimento * params.larguraOuEspacamento,
      areaDeclaradaM2: areaM2,
    );

    final armazenamentoSoloM3 = _volumeM3(
      params.profundidadeCamadaMm * params.porosidade,
      params.areaHectares,
    );
    final armazenamentoSuperficialM3 = _volumeM3(
      params.laminaSuperficialMm,
      params.areaHectares,
    );
    final evapotranspirationDuringFillM3 = _volumeM3(
      params.evapotranspiracaoMmDia * adoptedTurnDays,
      params.areaHectares,
    );
    final percolationDuringFillM3 = _volumeM3(
      params.condutividadeHidraulicaMmDia * adoptedTurnDays,
      params.areaHectares,
    );
    final volumeEnchimentoM3 =
        armazenamentoSoloM3 +
        armazenamentoSuperficialM3 +
        evapotranspirationDuringFillM3 +
        percolationDuringFillM3;
    final tempoEnchimentoH = volumeEnchimentoM3 / (params.vazaoDisponivelLps * 3.6);
    final profundidadeAguaM = params.laminaSuperficialMm / 1000;
    final areaGeometriaM2 = params.comprimento * params.larguraOuEspacamento;

    final curve = <PontoGrafico>[];
    for (var i = 0; i <= 12; i++) {
      final fracao = i / 12;
      curve.add(
        PontoGrafico(
          tempoEnchimentoH * 60 * fracao,
          params.comprimento * fracao,
        ),
      );
    }

    final alertas = <String>[
      if (vazaoEnchimentoLs > params.vazaoDisponivelLps)
        'A fonte não atende à vazão de enchimento recomendada.'
      else if (vazaoManutencaoLs > params.vazaoDisponivelLps)
        'A fonte não atende à vazão de manutenção.',
      if (!checagem.geometriaCabeNaArea && checagem.motivo != null)
        checagem.motivo!,
    ];

    return SimulationResult(
      eficiencia: eficienciaConducao,
      eficienciaRequerimento: 100,
      cuc: 0,
      du: 0,
      laminaMedia: profundidadeAguaM,
      laminaRequerida: profundidadeAguaM,
      tempoAvanco: tempoEnchimentoH * 60,
      perdaPercolacao: 0,
      perdaEscoamento: 0,
      curvaAvanco: curve,
      perfilLongitudinal: List.filled(21, profundidadeAguaM),
      alertaVazaoExcedida: alertas.isEmpty ? null : alertas.join(' '),
      anexos: {chaveAnexoChecagemOperacional: checagem},
      metricas: {
        'Turno de rega': adoptedTurnDays,
        'Área irrigada': params.areaHectares,
        'Vazão de enchimento': vazaoEnchimentoLs,
        'Vazão de manutenção': vazaoManutencaoLs,
        'Vazão disponível': params.vazaoDisponivelLps,
        'Tempo de enchimento': tempoEnchimentoH,
        'Volume de enchimento': volumeEnchimentoM3,
        'Armazenamento no solo': armazenamentoSoloM3,
        'Armazenamento superficial': armazenamentoSuperficialM3,
        'ET durante enchimento': evapotranspirationDuringFillM3,
        'Percolação durante enchimento': percolationDuringFillM3,
        'Lâmina superficial': params.laminaSuperficialMm,
        'Eficiência de condução': eficienciaConducao,
        'Eficiência de aplicação Ea': applicationEfficiency,
        'Lâmina aplicada por semana Las': lasMm,
        'Lâmina evapotranspirada por semana Les': lesMm,
        'Tempo semanal de irrigação': _horasSemana,
        'Área do tabuleiro': areaM2,
        'Área da geometria do tabuleiro': areaGeometriaM2,
        'Checagem operacional - vazão': checagem.atendeVazao ? 1.0 : 0.0,
        'Checagem operacional - geometria': checagem.geometriaCabeNaArea
            ? 1.0
            : 0.0,
        'Balanço - Aproveitado': eficienciaConducao,
        'Balanço - Percolação': 0.0,
        'Balanço - Escoamento': (100 - eficienciaConducao)
            .clamp(0, 100)
            .toDouble(),
        'Lâmina aplicada': params.laminaSuperficialMm,
        'Lâmina útil': eficienciaConducao / 100 * params.laminaSuperficialMm,
        'Lâmina percolada': 0.0,
        'Lâmina escoada':
            (100 - eficienciaConducao).clamp(0, 100).toDouble() /
            100 *
            params.laminaSuperficialMm,
        'Déficit de lâmina': max(
          0.0,
          params.laminaSuperficialMm -
              eficienciaConducao / 100 * params.laminaSuperficialMm,
        ),
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
        'Eficiência de aplicação Ea': '%',
        'Lâmina aplicada por semana Las': 'mm',
        'Lâmina evapotranspirada por semana Les': 'mm',
        'Tempo semanal de irrigação': 'h',
        'Área do tabuleiro': 'm²',
        'Área da geometria do tabuleiro': 'm²',
        'Checagem operacional - vazão': 'flag (1 = sim)',
        'Checagem operacional - geometria': 'flag (1 = sim)',
        'Balanço - Aproveitado': '%',
        'Balanço - Percolação': '%',
        'Balanço - Escoamento': '%',
        'Lâmina aplicada': 'mm',
        'Lâmina útil': 'mm',
        'Lâmina percolada': 'mm',
        'Lâmina escoada': 'mm',
        'Déficit de lâmina': 'mm',
      },
      resumoTextual:
          'A vazão de enchimento (Qe) forma a lâmina inicial; depois, a '
          'vazão de manutenção (Qm) repõe evapotranspiração e percolação. '
          'Las e Ea são semanais (p. 72) e Ec = 100 Qm/Qd.',
    );
  }

  /// Executa fórmulas do núcleo e converte erros de domínio
  /// (ArgumentError/StateError) em [FormatException] amigável.
  T _doNucleo<T>(T Function() acao) {
    try {
      return acao();
    } on ArgumentError catch (e) {
      throw FormatException('Inundação permanente: ${e.message}');
    } on StateError catch (e) {
      throw FormatException('Inundação permanente: ${e.message}');
    }
  }

  void _validar(IrrigationParameters params) {
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
    // G9: a declividade é validada também no regime permanente.
    if (params.declividade >= 0.02) {
      throw const FormatException(
        'A inundação exige declividade longitudinal inferior a 2%.',
      );
    }
  }

  /// Converte lâmina (mm) sobre área (ha) em volume (m³): mm × ha × 10.
  double _volumeM3(double laminaMm, double areaHa) => laminaMm * areaHa * 10;
}
