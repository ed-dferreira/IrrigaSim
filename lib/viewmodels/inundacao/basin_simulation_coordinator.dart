import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/simulation_result.dart';
import 'package:irrigasim/services/simulation/inundacao/run_basin_simulation.dart';
import 'package:irrigasim/services/simulation/inundacao/run_permanent_basin_simulation.dart';

/// Coordena os regimes intermitente e permanente da irrigação por inundação.
class BasinSimulationCoordinator {
  const BasinSimulationCoordinator();

  SimulationResult executar(IrrigationParameters parametros) =>
      parametros.tipoInundacao == TipoInundacao.permanente
      ? RunPermanentBasinSimulation()(parametros)
      : RunBasinSimulation()(parametros);
}
