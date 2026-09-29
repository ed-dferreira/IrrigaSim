import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/simulation_result.dart';
import 'package:irrigasim/services/simulation/faixas/run_border_simulation.dart';

/// Coordena a execução da simulação de irrigação por faixas.
class BorderSimulationCoordinator {
  const BorderSimulationCoordinator();

  SimulationResult executar(IrrigationParameters parametros) =>
      RunBorderSimulation()(parametros);
}
