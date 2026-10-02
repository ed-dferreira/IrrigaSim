import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/faixas/border_result.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/simulation_result.dart';
import 'package:irrigasim/services/simulation/faixas/border_hydraulics.dart';
import 'package:irrigasim/services/simulation/performance_indicators.dart';

/// Adapter de compatibilidade para telas e cenários rápidos existentes.
class RunBorderSimulation {
  const RunBorderSimulation();

  SimulationResult call(IrrigationParameters params) {
    final project = params.projetoFaixa ?? BorderProject.fromLegacy(params);
    final result = const BorderHydraulics().dimensionar(project);
    return toSimulationResult(result, project);
  }

  static SimulationResult toSimulationResult(BorderResult r, BorderProject p) {
    final depths = r.perfil.map((point) => point.infiltracaoM).toList();
    final mean = depths.reduce((a, b) => a + b) / depths.length;
    return SimulationResult(
      borderResult: r,
      eficiencia: r.ea,
      eficienciaRequerimento: r.er,
      cuc: PerformanceIndicators.calcularCuc(depths).toDouble(),
      du: PerformanceIndicators.calcularDu(depths).toDouble(),
      laminaMedia: mean,
      laminaRequerida: p.irnEfetivaMm! / 1000,
      tempoAvanco: r.taFinalMin,
      perdaPercolacao: r.pp,
      perdaEscoamento: r.pe,
      curvaAvanco: r.perfil
          .where(
            (point) => (point.xM / p.comprimentoM! * 400).round() % 20 == 0,
          )
          .map((point) => PontoGrafico(point.avancoMin, point.xM))
          .toList(),
      perfilLongitudinal: depths,
      resumoTextual:
          'Faixa aberta em declive; ${BorderResult.versaoEquacoes} · '
          '${r.status.codigo}. '
          '${r.avisos.map((notice) => notice.mensagem).join(' ')}',
      alertaVazaoExcedida: r.avisos.isEmpty
          ? null
          : r.avisos.map((notice) => notice.mensagem).join(' '),
      metricas: {
        'Vazão unitária adotada': p.vazaoUnitariaLsM!,
        'Vazão total da faixa': p.vazaoFaixaLs!,
        'Tempo de oportunidade': r.t0Min,
        'Tempo de avanço': r.taFinalMin,
        'Tempo de depleção': r.tdMin,
        'Tempo de irrigação': r.tiMin,
        'Profundidade na entrada': r.y0M,
        'Expoente do avanço': r.r,
        'Lâmina média infiltrada': mean * 1000,
        'Balanço - Aproveitado': r.ea,
        'Balanço - Percolação': r.pp,
        'Balanço - Escoamento': r.pe,
        'Lâmina aplicada': r.volumeEntradaM3M / p.comprimentoM! * 1000,
        'Lâmina útil': r.volumeUtilM3M / p.comprimentoM! * 1000,
        'Lâmina percolada': r.volumePercoladoM3M / p.comprimentoM! * 1000,
        'Lâmina escoada': r.volumeEscoadoM3M / p.comprimentoM! * 1000,
        'Déficit de lâmina': r.volumeDeficitM3M / p.comprimentoM! * 1000,
      },
      unidadesMetricas: const {
        'Vazão unitária adotada': 'L/s/m',
        'Vazão total da faixa': 'L/s',
        'Tempo de oportunidade': 'min',
        'Tempo de avanço': 'min',
        'Tempo de depleção': 'min',
        'Tempo de irrigação': 'min',
        'Profundidade na entrada': 'm',
        'Expoente do avanço': '',
        'Lâmina média infiltrada': 'mm',
        'Balanço - Aproveitado': '%',
        'Balanço - Percolação': '%',
        'Balanço - Escoamento': '%',
        'Lâmina aplicada': 'mm',
        'Lâmina útil': 'mm',
        'Lâmina percolada': 'mm',
        'Lâmina escoada': 'mm',
        'Déficit de lâmina': 'mm',
      },
    );
  }
}
