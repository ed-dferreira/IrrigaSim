import 'package:irrigasim/shared/irrigacao/models/comum/irrigacao_comum.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';

/// Payload de projeto versionado de um método; opaco para o compartilhado.
abstract interface class ProjetoMetodo {
  Map<String, Object?> toMap();
}

/// Anexo de resultado de um método; opaco para o compartilhado.
abstract interface class AnexoSimulacao {
  Map<String, Object?> toMap();
}

/// Ponte que cada feature registra para o compartilhado (de)codificar sem
/// importar `features/`.
abstract class CodecMetodo {
  const CodecMetodo();

  MetodoIrrigacao get metodo;

  /// Payload do projeto a partir dos parâmetros; null grava null (sulco sem
  /// entradas). Faixas/inundação nunca retornam null (incluem o legado).
  Map<String, Object?>? codificarProjeto(IrrigationParameters base);

  /// Projeto tipado a partir do mapa plano de `parametros` (lê a própria
  /// chave e aplica o adaptador legado); null só quando não há projeto.
  ProjetoMetodo? decodificarProjeto(Map<String, Object?> parametros);

  /// Chaves de anexo escritas ANTES das métricas em `SimulationResultModel.toMap`.
  List<String> get chavesAnexosIniciais;

  /// Chaves de anexo escritas DEPOIS de `planejamentoOperacional`.
  List<String> get chavesAnexosFinais;

  /// Anexos deste método presentes no mapa do resultado.
  Map<String, AnexoSimulacao> decodificarAnexos(Map<String, Object?> resultado);

  /// Projeção comum de leitura (identificação, área e ensaio).
  BaseIrrigacao baseComum(IrrigationParameters base);

  /// Linhas do projeto no relatório textual; vazio fora dos métodos que
  /// detalham o projeto tipado.
  List<String> linhasRelatorioProjeto(IrrigationParameters base) => const [];

  /// Linhas do resultado no relatório textual; vazio fora dos métodos que
  /// detalham o resultado tipado.
  List<String> linhasRelatorioResultado(SimulationResult resultado) =>
      const [];
}
