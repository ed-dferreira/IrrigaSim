import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/cenarios/cenario_salvo.dart';
import 'package:irrigasim/models/simulation_result_model.dart';
import 'package:irrigasim/models/sulcos/tipo_sulco_info.dart';

class ProjectStore {
  ProjectStore({
    required this.listar,
    required this.salvar,
    required this.buscarPorId,
    required this.excluir,
  });

  final Future<List<CenarioSalvo>> Function() listar;
  final Future<void> Function(CenarioSalvo) salvar;
  final Future<CenarioSalvo?> Function(String) buscarPorId;
  final Future<void> Function(String) excluir;

  Future<Map<String, dynamic>> exportarJson(CenarioSalvo cenario) async {
    final p = cenario.parametros;
    final r = cenario.resultado;
    return {
      'tipo_calculo': 'irrigacao_sulcos',
      'metodo': cenario.metodo.name,
      'unidades': {
        'comprimento': 'm',
        'largura_ou_espacamento': 'm',
        'area': 'ha',
        'declividade': 'm/m',
        'vazao': 'L/s',
        'tempo': 'min',
        'lamina': 'mm',
        'eficiencia': '%',
        'jornada': 'h/dia',
        'periodo_irrigacao': 'dias',
      },
      'parametros': {
        'comprimento': p.comprimento,
        'declividade': p.declividade,
        'largura_ou_espacamento': p.larguraOuEspacamento,
        'k': p.k,
        'a': p.a,
        'vib': p.vib,
        'vazao': p.vazao,
        'tempo_aplicacao': p.tempoAplicacao,
        'lamina_requerida': p.laminaRequerida,
        'manning_n': p.manningN,
        'sigma_z': p.sigmaZ,
        'textura_solo': p.texturaSolo.name,
        'tipo_sulco': p.tipoSulco?.name,
        'area_hectares': p.areaHectares,
        'vazao_disponivel_l_s': p.vazaoDisponivelLps,
        'desnivel_transversal_m': p.declividadeTransversal,
        'tempo_avanco_metade_min': p.tempoAvancoMetadeMin,
        'tempo_avanco_final_min': p.tempoAvancoFinalMin,
        'coeficiente_avanco_k': p.coeficienteAvancoK,
        'expoente_avanco_b': p.expoenteAvancoB,
        'distancia_referencia_avanco_m': p.distanciaReferenciaAvancoM,
        'usar_ensaio_avanco': p.usarEnsaioAvanco,
        'metodo_curva_avanco': p.metodoCurvaAvanco.name,
        'medicoes_avanco': p.medicoesAvanco
            .map((point) => point.toMap())
            .toList(),
        'origem_curva_infiltracao': p.origemCurvaInfiltracao.name,
        'distancia_ensaio_infiltracao_m': p.distanciaEnsaioInfiltracaoM,
        'espacamento_ensaio_infiltracao_m': p.espacamentoEnsaioInfiltracaoM,
        'medicoes_entrada_saida': p.medicoesEntradaSaida
            .map((point) => point.toMap())
            .toList(),
        'hipotese_recessao': p.hipoteseRecessao.name,
        'medicoes_recessao': p.medicoesRecessao
            .map((point) => point.toMap())
            .toList(),
        'manejo_sulco': p.manejoSulco.name,
        'vazao_reduzida_l_s': p.vazaoReduzidaLs,
        'tempo_mudanca_min': p.tempoMudancaMin,
        'tempo_mudanca_parcela_min': p.tempoMudancaParcelaMin,
        'periodo_irrigacao_dias': p.periodoIrrigacaoDias,
        'ciclo_surtir_min': p.cicloSurtirMin,
        'jornada_diaria_h': p.jornadaDiariaH,
        'perdas_conducao_l_s': p.perdasConducaoLs,
        'precipitacao_efetiva_mm_dia': p.precipitacaoEfetivaMmDia,
        'nome_cultura': p.nomeCultura,
        'kc': p.kc,
        'espacamento_fileiras_m': p.espacamentoFileirasM,
        'espacamento_plantas_m': p.espacamentoPlantasM,
        'largura_sulco_m': p.larguraSulcoM,
        'profundidade_sulco_m': p.profundidadeSulcoM,
      },
      'resultado': {
        'eficiencia': r.eficiencia,
        'eficiencia_requerimento': r.eficienciaRequerimento,
        'cuc': r.cuc,
        'du': r.du,
        'lamina_media': r.laminaMedia,
        'lamina_requerida': r.laminaRequerida,
        'tempo_avanco': r.tempoAvanco,
        'perda_percolacao': r.perdaPercolacao,
        'perda_escoamento': r.perdaEscoamento,
        'metricas': r.metricas,
        'unidades_metricas': r.unidadesMetricas,
        'alerta_vazao_excedida': r.alertaVazaoExcedida,
        'planejamento_operacional': r.planejamentoOperacional?.toMap(),
        'resultado_completo': SimulationResultModel.toMap(r),
      },
      'metadados': {
        'data_criacao': cenario.dataCriacao.toIso8601String(),
        'data_modificacao': cenario.dataModificacao.toIso8601String(),
        'versao_calculo': '1.0',
        'usuario_id': cenario.usuarioId,
      },
    };
  }

  Future<String> exportarRelatorio(CenarioSalvo cenario) async {
    final p = cenario.parametros;
    final r = cenario.resultado;
    final buffer = StringBuffer();

    buffer.writeln('RELATÓRIO DE DIMENSIONAMENTO DE IRRIGAÇÃO');
    buffer.writeln('=' * 50);
    buffer.writeln('');
    buffer.writeln('Cenário: ${cenario.nome}');
    buffer.writeln('Método: ${cenario.metodo.displayName}');
    buffer.writeln('Data: ${_formatDate(cenario.dataCriacao)}');
    buffer.writeln('Versão do cálculo: 1.0');
    buffer.writeln('');
    buffer.writeln('DADOS DE ENTRADA');
    buffer.writeln('-' * 30);
    buffer.writeln('Comprimento: ${p.comprimento.toStringAsFixed(0)} m');
    buffer.writeln(
      'Espaçamento/Largura: ${p.larguraOuEspacamento.toStringAsFixed(2)} m',
    );
    buffer.writeln('Vazão: ${p.vazao.toStringAsFixed(2)} L/s');
    buffer.writeln('Declividade longitudinal: ${p.declividade} m/m');
    buffer.writeln(
      'Tipo de sulco: ${p.tipoSulco?.displayName ?? 'Não informado'}',
    );
    buffer.writeln('Área efetiva: ${p.areaHectares.toStringAsFixed(2)} ha');
    buffer.writeln('Período de irrigação: ${p.periodoIrrigacaoDias} dias');
    buffer.writeln(
      'Tempo entre parcelas: ${p.tempoMudancaParcelaMin.toStringAsFixed(0)} min',
    );
    buffer.writeln('Manejo: ${p.manejoSulco.displayName}');
    if (p.manejoSulco == ManejoSulco.reduzida) {
      buffer.writeln(
        'Vazão reduzida: ${p.vazaoReduzidaLs.toStringAsFixed(2)} L/s',
      );
      buffer.writeln(
        'Atraso de redução após o avanço: ${p.tempoMudancaMin.toStringAsFixed(0)} min',
      );
    }
    buffer.writeln(
      'Tempo de aplicação: ${p.tempoAplicacao.toStringAsFixed(0)} min',
    );
    buffer.writeln(
      'Lâmina requerida: ${p.laminaRequerida.toStringAsFixed(0)} mm',
    );
    buffer.writeln('Coef. infiltração k: ${p.k}');
    buffer.writeln('Expoente a: ${p.a}');
    buffer.writeln('Textura do solo: ${p.texturaSolo.displayName}');
    buffer.writeln(
      'Origem do avanço: ${p.usarEnsaioAvanco ? 'ensaio' : 'estimativa'}',
    );
    buffer.writeln('Método de avanço: ${p.metodoCurvaAvanco.name}');
    buffer.writeln('Origem da infiltração: ${p.origemCurvaInfiltracao.name}');
    buffer.writeln('Hipótese de recessão: ${p.hipoteseRecessao.name}');
    buffer.writeln('');
    buffer.writeln('RESULTADOS');
    buffer.writeln('-' * 30);
    buffer.writeln(
      'Eficiência de aplicação (Ea): ${r.eficiencia.toStringAsFixed(2)}%',
    );
    buffer.writeln('Uniformidade CUC: ${r.cuc.toStringAsFixed(2)}%');
    buffer.writeln('Distribuição DU: ${r.du.toStringAsFixed(2)}%');
    buffer.writeln(
      'Lâmina média infiltrada: ${(r.laminaMedia * 1000).toStringAsFixed(2)} mm',
    );
    buffer.writeln('Tempo de avanço: ${r.tempoAvanco.toStringAsFixed(2)} min');
    if (r.tempoOportunidadeFinalMin != null) {
      buffer.writeln(
        'Oportunidade no final: ${r.tempoOportunidadeFinalMin!.toStringAsFixed(2)} min',
      );
    }
    if (r.tempoFornecimentoMin != null) {
      buffer.writeln(
        'Fornecimento Ti/Tt: ${r.tempoFornecimentoMin!.toStringAsFixed(2)} min',
      );
    }
    if (r.laminainfiltradaInicioMm != null) {
      buffer.writeln(
        'Lâmina infiltrada no início (Li): ${r.laminainfiltradaInicioMm!.toStringAsFixed(2)} mm',
      );
    }
    if (r.laminainfiltradaFinalMm != null) {
      buffer.writeln(
        'Lâmina infiltrada no final (Lf): ${r.laminainfiltradaFinalMm!.toStringAsFixed(2)} mm',
      );
    }
    if (r.laminaAplicadaMediaMm != null) {
      buffer.writeln(
        'Lâmina média aplicada (Lm): ${r.laminaAplicadaMediaMm!.toStringAsFixed(2)} mm',
      );
    }
    buffer.writeln(
      'Perda por percolação: ${r.perdaPercolacao.toStringAsFixed(2)}%',
    );
    buffer.writeln(
      'Perda por escoamento: ${r.perdaEscoamento.toStringAsFixed(2)}%',
    );
    if (r.planejamentoOperacional case final planning?) {
      buffer.writeln('');
      buffer.writeln('PLANEJAMENTO OPERACIONAL');
      buffer.writeln('-' * 30);
      buffer.writeln('NTS: ${planning.ntsOperacional} sulcos');
      buffer.writeln('NSD: ${planning.nsdOperacional} sulcos/dia');
      buffer.writeln('TIP: ${planning.tipH.toStringAsFixed(4)} h');
      buffer.writeln('NPD: ${planning.npdOperacional} parcelas/dia');
      buffer.writeln('NSP: ${planning.nspOperacional} sulcos simultâneos');
      buffer.writeln(
        'Qprojeto: ${planning.qProjetoOperacional.toStringAsFixed(2)} L/s',
      );
      buffer.writeln(
        'Agenda: ${planning.diasNecessariosOperacional} de ${planning.periodoIrrigacaoDias} dias',
      );
      buffer.writeln(
        planning.motivoInviabilidade ??
            'Operação viável na capacidade informada.',
      );
    }
    buffer.writeln('');
    buffer.writeln('CLASSIFICAÇÕES');
    buffer.writeln('-' * 30);
    buffer.writeln('Ea: ${r.classificacaoEa}');
    buffer.writeln('CUC: ${r.classificacaoCuc}');
    buffer.writeln('DU: ${r.classificacaoDu}');
    buffer.writeln('');
    if (r.alertaVazaoExcedida != null) {
      buffer.writeln('ALERTAS');
      buffer.writeln('-' * 30);
      buffer.writeln(r.alertaVazaoExcedida);
      buffer.writeln('');
    }
    buffer.writeln('Métricas adicionais');
    buffer.writeln('-' * 30);
    for (final entry in r.metricas.entries) {
      final unit = r.unidadesMetricas[entry.key] ?? '';
      buffer.writeln('${entry.key}: ${entry.value} $unit');
    }
    buffer.writeln('');
    buffer.writeln('=' * 50);
    buffer.writeln('Gerado por IrrigaSim v1.0');

    return buffer.toString();
  }

  Future<CenarioSalvo> duplicar(
    CenarioSalvo original, {
    String? novoNome,
  }) async {
    return CenarioSalvo(
      id: '',
      nome: novoNome ?? '${original.nome} (cópia)',
      metodo: original.metodo,
      parametros: original.parametros,
      resultado: original.resultado,
      dataCriacao: DateTime.now(),
      dataModificacao: DateTime.now(),
      usuarioId: original.usuarioId,
    );
  }

  Future<Map<String, dynamic>> comparar(CenarioSalvo a, CenarioSalvo b) async {
    return {
      'cenario_a': {'nome': a.nome},
      'cenario_b': {'nome': b.nome},
      'diferencas': {
        'eficiencia': b.resultado.eficiencia - a.resultado.eficiencia,
        'eficiencia_requerimento':
            b.resultado.eficienciaRequerimento -
            a.resultado.eficienciaRequerimento,
        'cuc': b.resultado.cuc - a.resultado.cuc,
        'du': b.resultado.du - a.resultado.du,
        'lamina_media':
            (b.resultado.laminaMedia - a.resultado.laminaMedia) * 1000,
        'tempo_avanco': b.resultado.tempoAvanco - a.resultado.tempoAvanco,
        'perda_percolacao':
            b.resultado.perdaPercolacao - a.resultado.perdaPercolacao,
        'perda_escoamento':
            b.resultado.perdaEscoamento - a.resultado.perdaEscoamento,
      },
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
