import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/features/irrigacao_faixas/services/executar_simulacao_faixa.dart';

/// Coordena a execução da simulação de irrigação por faixas.
class BorderSimulationCoordinator {
  const BorderSimulationCoordinator();

  SimulationResult executar(IrrigationParameters parametros) =>
      RunBorderSimulation()(parametros);
}
