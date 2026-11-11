import 'package:irrigasim/features/irrigacao_sulcos/models/curva_infiltracao.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/entradas_projeto.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/indicadores_balanco.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/medicoes_campo.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/contratos_metodo.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/irrigacao_comum.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';

/// Codec do método por sulcos para o compartilhado.
class CodecSulco extends CodecMetodo {
  const CodecSulco();

  @override
  MetodoIrrigacao get metodo => MetodoIrrigacao.sulco;

  @override
  Map<String, Object?>? codificarProjeto(IrrigationParameters base) =>
      base.entradasProjeto?.toMap();

  @override
  ProjetoMetodo? decodificarProjeto(Map<String, Object?> parametros) {
    final data = parametros['entradasProjeto'];
    return data is Map
        ? EntradasProjeto.fromMap(Map<String, dynamic>.from(data))
        : null;
  }

  @override
  List<String> get chavesAnexosIniciais => const [chaveAnexoBalancoSulco];

  @override
  List<String> get chavesAnexosFinais => const [];

  @override
  Map<String, AnexoSimulacao> decodificarAnexos(
    Map<String, Object?> resultado,
  ) {
    final data = resultado[chaveAnexoBalancoSulco];
    return data is Map
        ? {
            chaveAnexoBalancoSulco: IndicadoresBalancoSulco.fromMap(
              Map<String, dynamic>.from(data),
            ),
          }
        : const {};
  }

  @override
  BaseIrrigacao baseComum(IrrigationParameters base) {
    final recessao = {
      for (final p in base.medicoesRecessaoResolvidas)
        p.distanciaM: p.instanteRecessaoMin,
    };
    return BaseIrrigacao(
      identificacao: IdentificacaoIrrigacao.superficie(SistemaSuperficie.sulcos),
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
      ensaio:
          base.medicoesAvancoResolvidas.isEmpty &&
              base.medicoesEntradaSaidaResolvidas.isEmpty &&
              base.medicoesRecessaoResolvidas.isEmpty
          ? null
          : EnsaioComum(
              estacas: base.medicoesAvancoResolvidas
                  .map(
                    (p) => EstacaEnsaio(
                      p.distanciaM,
                      p.tempoMin,
                      recessaoMin: recessao[p.distanciaM],
                    ),
                  )
                  .toList(),
              medicoesInfiltracao: base.medicoesEntradaSaidaResolvidas
                  .map(
                    (p) => MedicaoInfiltracaoComum(
                      tempoMin: p.tempoMin,
                      vazaoEntradaLs: p.vazaoEntradaLs,
                      vazaoSaidaLs: p.vazaoSaidaLs,
                    ),
                  )
                  .toList(),
              origemInfiltracao: base.origemCurvaInfiltracaoResolvida.name,
            ),
    );
  }

  @override
  List<String> linhasRelatorioProjeto(IrrigationParameters base) {
    final entradas = base.entradasProjeto;
    return [
      entradas == null
          ? 'Projeto legado: UCC, UPMP, Ds, raízes, f, ETo e origem da chuva ausentes.'
          : 'Entradas do projeto de sulcos v${entradas.versao}: '
                'UCC=${entradas.uccPercentual ?? 'ausente'}%; '
                'UPMP=${entradas.upmpPercentual ?? 'ausente'}%; '
                'Ds=${entradas.densidadeAparenteGcm3 ?? 'ausente'} g/cm³; '
                'raízes=${entradas.profundidadeRadicularCm ?? 'ausente'} cm; '
                'f=${entradas.fracaoDisponivel ?? 'ausente'}; '
                'ETc adotada=${entradas.etcAdotadaMmDia ?? 'ausente'} mm/dia; '
                'ETo=${entradas.etoMmDia ?? 'ausente'} mm/dia; '
                'chuva ${entradas.origemChuva.name}=${entradas.precipitacaoMmDia ?? 'ausente'} mm/dia.',
      if (entradas?.curvaInfiltracao case final CurvaInfiltracao curva)
        'Curva ${curva.tipo.name} (${curva.base.name}): '
            'K=${curva.coeficiente} ${curva.unidadeCoeficiente}; '
            'expoente=${curva.expoente}; E=${curva.espacamentoConversaoM ?? 'não aplicável'} m; '
            'VIB=${curva.vibMmHora ?? 'ausente'} mm/h; '
            'calibração=${curva.tempoMinCalibrado ?? 'ausente'}–'
            '${curva.tempoMaxCalibrado ?? 'ausente'} min.',
    ];
  }

  @override
  List<String> linhasRelatorioResultado(SimulationResult resultado) {
    if (resultado.balancoSulco case final balance?) {
      return [
        'Ea do slide (Lf/Lm): ${balance.eficienciaAplicacaoSlidePercentual.toStringAsFixed(2)}%',
        'Ea integral (Lútil/Lm, domínio 0–L): '
            '${balance.eficienciaAplicacaoIntegralPercentual.toStringAsFixed(2)}%',
        'Balanço integral: Pp=${balance.perdaPercolacaoIntegralPercentual.toStringAsFixed(2)}%; '
            'Pe=${balance.perdaEscoamentoIntegralPercentual.toStringAsFixed(2)}%; '
            'déficit=${balance.deficitMm.toStringAsFixed(2)} mm.',
      ];
    }
    return const [];
  }
}
