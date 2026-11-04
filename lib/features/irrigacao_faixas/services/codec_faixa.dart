import 'package:irrigasim/features/irrigacao_faixas/models/faixa_projeto.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_resultado.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/contratos_metodo.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/irrigacao_comum.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';

/// Codec do método por faixas para o compartilhado.
class CodecFaixa extends CodecMetodo {
  const CodecFaixa();

  @override
  MetodoIrrigacao get metodo => MetodoIrrigacao.faixa;

  @override
  Map<String, Object?>? codificarProjeto(IrrigationParameters base) =>
      (base.projetoFaixa ?? BorderProject.fromLegacy(base)).toMap();

  @override
  ProjetoMetodo? decodificarProjeto(Map<String, Object?> parametros) {
    final data = parametros['projetoFaixa'];
    if (data is Map) {
      return BorderProject.fromMap(Map<String, dynamic>.from(data));
    }
    return BorderProject.fromLegacy(
      IrrigationParameters(
        comprimento: (parametros['comprimento'] as num).toDouble(),
        declividade: (parametros['declividade'] as num).toDouble(),
        declividadeTransversal:
            (parametros['declividadeTransversal'] as num?)?.toDouble() ?? 0,
        larguraOuEspacamento: (parametros['larguraOuEspacamento'] as num)
            .toDouble(),
        k: (parametros['k'] as num).toDouble(),
        a: (parametros['a'] as num).toDouble(),
        vib: (parametros['vib'] as num).toDouble(),
        vazao: (parametros['vazao'] as num).toDouble(),
        tempoAplicacao: (parametros['tempoAplicacao'] as num).toDouble(),
        laminaRequerida: (parametros['laminaRequerida'] as num).toDouble(),
        manningN: (parametros['manningN'] as num?)?.toDouble() ?? 0.015,
        sigmaZ: (parametros['sigmaZ'] as num?)?.toDouble() ?? 0.4,
      ),
    );
  }

  @override
  List<String> get chavesAnexosIniciais => const [chaveAnexoResultadoFaixa];

  @override
  List<String> get chavesAnexosFinais => const [];

  @override
  Map<String, AnexoSimulacao> decodificarAnexos(
    Map<String, Object?> resultado,
  ) {
    final data = resultado[chaveAnexoResultadoFaixa];
    return data is Map
        ? {
            chaveAnexoResultadoFaixa: BorderResult.fromMap(
              Map<String, dynamic>.from(data),
            ),
          }
        : const {};
  }

  @override
  BaseIrrigacao baseComum(IrrigationParameters base) =>
      (base.projetoFaixa ?? BorderProject.fromLegacy(base)).baseComum;
}
