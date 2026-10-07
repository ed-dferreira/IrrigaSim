import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/inundacao/basin_project.dart';
import 'package:irrigasim/models/simulation_result.dart';
import 'package:irrigasim/services/simulation/inundacao/run_basin_simulation.dart';
import 'package:irrigasim/services/simulation/inundacao/run_permanent_basin_simulation.dart';

/// Coordena os regimes intermitente e permanente da irrigação por inundação.
class BasinSimulationCoordinator {
  const BasinSimulationCoordinator();

  SimulationResult executar(IrrigationParameters parametros) =>
      executarProjeto(BasinProject.fromParameters(parametros));

  SimulationResult executarProjeto(BasinProject projeto) =>
      projeto.tipo == TipoInundacao.permanente
      ? RunPermanentBasinSimulation()(projeto.parametros)
      : RunBasinSimulation()(projeto.parametros);
}
