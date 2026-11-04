import 'package:irrigasim/features/irrigacao_inundacao/models/anexos_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/projeto_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/planejamento_inundacao.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/contratos_metodo.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/irrigacao_comum.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';

/// Codec do método por inundação para o compartilhado.
class CodecInundacao extends CodecMetodo {
  const CodecInundacao();

  @override
  MetodoIrrigacao get metodo => MetodoIrrigacao.inundacao;

  @override
  Map<String, Object?>? codificarProjeto(IrrigationParameters base) =>
      (base.projetoInundacao ?? ProjetoInundacao.fromLegacy(base)).toMap();

  @override
  ProjetoMetodo? decodificarProjeto(Map<String, Object?> parametros) {
    final data = parametros['projetoInundacao'];
    if (data is Map) {
      return ProjetoInundacao.fromMap(Map<String, dynamic>.from(data));
    }
    return ProjetoInundacao.fromLegacy(
      IrrigationParameters(
        comprimento: (parametros['comprimento'] as num).toDouble(),
        declividade: (parametros['declividade'] as num).toDouble(),
        larguraOuEspacamento: (parametros['larguraOuEspacamento'] as num)
            .toDouble(),
        areaHectares: (parametros['areaHectares'] as num?)?.toDouble() ?? 2,
        tipoInundacao: TipoInundacaoExtension.fromString(
          parametros['tipoInundacao'] as String?,
        ),
        porosidade: (parametros['porosidade'] as num?)?.toDouble() ?? 0.5,
        profundidadeCamadaMm:
            (parametros['profundidadeCamadaMm'] as num?)?.toDouble() ?? 500,
        condutividadeHidraulicaMmDia:
            (parametros['condutividadeHidraulicaMmDia'] as num?)?.toDouble() ??
            7,
        dtaMmCm: (parametros['dtaMmCm'] as num?)?.toDouble() ?? 2,
        fatorDisponibilidade:
            (parametros['fatorDisponibilidade'] as num?)?.toDouble() ?? 0.5,
        evapotranspiracaoMmDia:
            (parametros['evapotranspiracaoMmDia'] as num?)?.toDouble() ?? 7.2,
        laminaSuperficialMm:
            (parametros['laminaSuperficialMm'] as num?)?.toDouble() ?? 150,
        vazaoDisponivelLps:
            (parametros['vazaoDisponivelLps'] as num?)?.toDouble() ?? 36,
        k: (parametros['k'] as num).toDouble(),
        a: (parametros['a'] as num).toDouble(),
        vib: (parametros['vib'] as num).toDouble(),
        vazao: (parametros['vazao'] as num?)?.toDouble() ?? 0,
        tempoAplicacao: (parametros['tempoAplicacao'] as num?)?.toDouble() ?? 60,
        laminaRequerida:
            (parametros['laminaRequerida'] as num?)?.toDouble() ?? 70,
      ),
    );
  }

  @override
  List<String> get chavesAnexosIniciais => const [];

  @override
  List<String> get chavesAnexosFinais => const [
    chaveAnexoParcelas,
    chaveAnexoSelecaoVazao,
    chaveAnexoVolumesArroz,
    chaveAnexoChecagemOperacional,
  ];

  @override
  Map<String, AnexoSimulacao> decodificarAnexos(
    Map<String, Object?> resultado,
  ) {
    final anexos = <String, AnexoSimulacao>{};
    if (resultado[chaveAnexoParcelas] is Map) {
      anexos[chaveAnexoParcelas] = AnexoParcelas.fromMap(
        resultado[chaveAnexoParcelas],
      );
    }
    if (resultado[chaveAnexoSelecaoVazao] is Map) {
      anexos[chaveAnexoSelecaoVazao] = AnexoSelecaoVazao.fromMap(
        resultado[chaveAnexoSelecaoVazao],
      );
    }
    if (resultado[chaveAnexoVolumesArroz] is Map) {
      anexos[chaveAnexoVolumesArroz] = AnexoVolumesArroz.fromMap(
        resultado[chaveAnexoVolumesArroz],
      );
    }
    if (resultado[chaveAnexoChecagemOperacional] is Map) {
      anexos[chaveAnexoChecagemOperacional] = ChecagemOperacional.fromMap(
        resultado[chaveAnexoChecagemOperacional],
      );
    }
    return anexos;
  }

  @override
  BaseIrrigacao baseComum(IrrigationParameters base) => BaseIrrigacao(
    identificacao: IdentificacaoIrrigacao.superficie(
      SistemaSuperficie.inundacao,
    ),
    area: CaracterizacaoArea(
      comprimentoM: base.comprimento,
      larguraM: base.larguraOuEspacamento,
      declividadePercentual: base.declividade * 100,
      texturaSolo: base.texturaSolo.name,
      cultura: base.nomeCultura.isEmpty ? null : base.nomeCultura,
      etcMmDia: base.evapotranspiracaoMmDia,
      precipitacaoEfetivaMmDia: base.precipitacaoEfetivaMmDia,
      vazaoDisponivelLs: base.vazaoDisponivelLps,
    ),
  );
}
