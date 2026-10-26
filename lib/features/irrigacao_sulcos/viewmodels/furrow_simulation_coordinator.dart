import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/shared/irrigacao/services/operational_planning.dart';
import 'package:irrigasim/features/irrigacao_sulcos/services/advance_curve_model.dart';
import 'package:irrigasim/features/irrigacao_sulcos/services/run_furrow_simulation.dart';

/// Coordena simulação hidráulica e planejamento operacional de sulcos.
class FurrowSimulationCoordinator {
  const FurrowSimulationCoordinator();

  SimulationResult simular(
    IrrigationParameters parametros, {
    AdvanceCurveResult? curvaAvanco,
  }) => RunFurrowSimulation()(parametros, advanceCurve: curvaAvanco);

  SimulationResult executar(
    IrrigationParameters parametros, {
    AdvanceCurveResult? curvaAvanco,
  }) {
    var resultado = simular(parametros, curvaAvanco: curvaAvanco);
    final tempoFornecimentoMin = resultado.tempoFornecimentoMin;
    if (tempoFornecimentoMin == null) {
      throw const FormatException(
        'O tempo de fornecimento não foi calculado; não é possível planejar a operação.',
      );
    }

    final planejamento = OperationalPlanning.calcular(
      areaTotalM2: parametros.areaHectares * 10000,
      comprimentoSulcoM: parametros.comprimento,
      espacamentoM: parametros.larguraOuEspacamento,
      periodoIrrigacaoDias: parametros.periodoIrrigacaoDias,
      tempoFornecimentoH: tempoFornecimentoMin / 60,
      tempoMudancaParcelaH: parametros.tempoMudancaParcelaMin / 60,
      jornadaDiariaH: parametros.jornadaDiariaH,
      vazaoInicialLs: parametros.vazao,
      perdasConducaoLs: parametros.perdasConducaoLs,
      vazaoDisponivelLs: parametros.vazaoDisponivelLps,
    );
    resultado = resultado.comPlanejamentoOperacional(planejamento);
    return resultado;
  }
}
