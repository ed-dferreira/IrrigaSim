import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/adaptadores_superficie.dart';
import 'package:irrigasim/shared/irrigacao/services/registro_codecs.dart';

import '../models/cenario_salvo.dart';

import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result_model.dart';
import 'package:irrigasim/shared/irrigacao/models/tipo_sulco.dart';

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
    final codec = registroCodecs.obrigatorio(cenario.metodo);
    return {
      'tipo_calculo': 'irrigacao_${cenario.metodo.name}',
      'metodo': cenario.metodo.name,
      'base_comum': p.baseComumPara(cenario.metodo).toMap(),
      if (cenario.metodo == MetodoIrrigacao.sulco)
        'entradas_projeto_sulco': codec.codificarProjeto(p),
      if (cenario.metodo == MetodoIrrigacao.faixa)
        'projeto_faixa': codec.codificarProjeto(p),
      if (cenario.metodo == MetodoIrrigacao.inundacao)
        'projeto_inundacao': codec.codificarProjeto(p),
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
        'vazao_ensaio_avanco_l_s': p.vazaoEnsaioAvancoLs,
        'condicoes_ensaio_avanco': p.condicoesEnsaioAvanco,
        'ensaio_erosao': p.ensaioErosao?.toMap(),
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
        'origem_vazao_reduzida': p.origemVazaoReduzida.name,
        'fator_1_1_vib': p.fator11Vib,
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
        if (r.anexos['balancoSulco'] != null)
          'indicadores_balanco_sulco': r.anexos['balancoSulco']!.toMap(),
        'alerta_vazao_excedida': r.alertaVazaoExcedida,
        'planejamento_operacional': r.planejamentoOperacional?.toMap(),
        'resultado_completo': SimulationResultModel.toMap(r),
      },
      'metadados': {
        'data_criacao': cenario.dataCriacao.toIso8601String(),
        'data_modificacao': cenario.dataModificacao.toIso8601String(),
        'versao_calculo': '1.0',
      },
    };
  }

  /// Resumo estruturado do cenário em seções de pares campo/valor.
  ///
  /// É a fonte única do CSV e do PDF, garantindo que os dois formatos
  /// tragam exatamente os mesmos dados.
  List<(String, List<MapEntry<String, String>>)> secoesResumo(
    CenarioSalvo cenario,
  ) {
    final p = cenario.parametros;
    final r = cenario.resultado;
    return [
      (
        'Cenário',
        [
          MapEntry('Nome', cenario.nome),
          MapEntry('Método', cenario.metodo.displayName),
          MapEntry('Criado em', _formatDate(cenario.dataCriacao)),
        ],
      ),
      (
        'Dados de entrada',
        [
          MapEntry('Comprimento (m)', _numPt(p.comprimento, 0)),
          MapEntry(
            'Espaçamento/largura (m)',
            _numPt(p.larguraOuEspacamento, 2),
          ),
          MapEntry('Vazão (L/s)', _numPt(p.vazao, 2)),
          MapEntry('Declividade (m/m)', _numPt(p.declividade, 3)),
          MapEntry('Área efetiva (ha)', _numPt(p.areaHectares, 2)),
          MapEntry('Tempo de aplicação (min)', _numPt(p.tempoAplicacao, 0)),
          MapEntry('Lâmina requerida (mm)', _numPt(p.laminaRequerida, 0)),
          MapEntry('Coeficiente de infiltração k', _numStr(p.k)),
          MapEntry('Expoente a', _numStr(p.a)),
          MapEntry('Textura do solo', p.texturaSolo.displayName),
          MapEntry('Manejo', p.manejoSulco.displayName),
          MapEntry(
            'Período de irrigação (dias)',
            p.periodoIrrigacaoDias.toString(),
          ),
        ],
      ),
      (
        'Resultados',
        _paresResultado(r),
      ),
      if (r.planejamentoOperacional case final planning?)
        (
          'Planejamento operacional',
          [
            MapEntry('NTS (sulcos)', planning.ntsOperacional.toString()),
            MapEntry('NSD (sulcos/dia)', planning.nsdOperacional.toString()),
            MapEntry('TIP (h)', _numPt(planning.tipH, 4)),
            MapEntry(
              'NPD (parcelas/dia)',
              planning.npdOperacional.toString(),
            ),
            MapEntry('NSP (sulcos simultâneos)', planning.nspOperacional.toString()),
            MapEntry('Qprojeto (L/s)', _numPt(planning.qProjetoOperacional, 2)),
            MapEntry(
              'Dias necessários',
              planning.diasNecessariosOperacional.toString(),
            ),
          ],
        ),
      (
        'Classificações',
        [
          MapEntry('Ea', r.classificacaoEa),
          MapEntry('CUC', r.classificacaoCuc),
          MapEntry('DU', r.classificacaoDu),
        ],
      ),
    ];
  }

  List<MapEntry<String, String>> _paresResultado(SimulationResult r) {
    final pares = <MapEntry<String, String>>[
      MapEntry('Eficiência de aplicação Ea (%)', _numPt(r.eficiencia, 2)),
      MapEntry(
        'Eficiência de requerimento (%)',
        _numPt(r.eficienciaRequerimento, 2),
      ),
      MapEntry('Uniformidade CUC (%)', _numPt(r.cuc, 2)),
      MapEntry('Distribuição DU (%)', _numPt(r.du, 2)),
      MapEntry('Lâmina média infiltrada (mm)', _numPt(r.laminaMedia * 1000, 2)),
      MapEntry('Tempo de avanço (min)', _numPt(r.tempoAvanco, 2)),
      if (r.tempoOportunidadeFinalMin case final valor?)
        MapEntry('Oportunidade no final (min)', _numPt(valor, 2)),
      if (r.tempoFornecimentoMin case final valor?)
        MapEntry('Fornecimento Ti/Tt (min)', _numPt(valor, 2)),
      if (r.laminainfiltradaInicioMm case final valor?)
        MapEntry('Lâmina infiltrada no início Li (mm)', _numPt(valor, 2)),
      if (r.laminainfiltradaFinalMm case final valor?)
        MapEntry('Lâmina infiltrada no final Lf (mm)', _numPt(valor, 2)),
      if (r.laminaAplicadaMediaMm case final valor?)
        MapEntry('Lâmina média aplicada Lm (mm)', _numPt(valor, 2)),
      MapEntry('Perda por percolação (%)', _numPt(r.perdaPercolacao, 2)),
      MapEntry('Perda por escoamento (%)', _numPt(r.perdaEscoamento, 2)),
      if (r.alertaVazaoExcedida case final alerta? when alerta.isNotEmpty)
        MapEntry('Alerta', alerta),
      for (final entry in r.metricas.entries)
        MapEntry(
          entry.key,
          '${_numStr(entry.value)} ${r.unidadesMetricas[entry.key] ?? ''}'
              .trim(),
        ),
    ];
    return pares;
  }

  /// Gera um CSV com seções do cenário.
  ///
  /// Usa `;` como separador e vírgula decimal, o padrão que planilhas em
  /// pt-BR abrem corretamente; campos com separadores, aspas ou quebra de
  /// linha são escapados.
  String exportarCsv(CenarioSalvo cenario) {
    final buffer = StringBuffer('Seção;Campo;Valor\n');
    for (final (secao, pares) in secoesResumo(cenario)) {
      for (final par in pares) {
        buffer
          ..write(_celulaCsv(secao))
          ..write(';')
          ..write(_celulaCsv(par.key))
          ..write(';')
          ..write(_celulaCsv(par.value))
          ..write('\n');
      }
    }
    return buffer.toString();
  }

  String _celulaCsv(String valor) {
    if (valor.contains(';') || valor.contains('"') || valor.contains('\n')) {
      return '"${valor.replaceAll('"', '""')}"';
    }
    return valor;
  }

  Future<String> exportarRelatorio(CenarioSalvo cenario) async {
    final p = cenario.parametros;
    final r = cenario.resultado;
    final codec = registroCodecs.obrigatorio(cenario.metodo);
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
    if (cenario.metodo == MetodoIrrigacao.sulco) {
      for (final linha in codec.linhasRelatorioProjeto(p)) {
        buffer.writeln(linha);
      }
    }
    if (p.manejoSulco == ManejoSulco.reduzida) {
      buffer.writeln(
        'Vazão reduzida (${p.origemVazaoReduzida.name}): '
        '${r.metricas['Vazão reduzida']?.toStringAsFixed(3) ?? 'não calculada'} L/s',
      );
      if (p.origemVazaoReduzida == OrigemVazaoReduzida.vib) {
        buffer.writeln(
          'VIB para F23: ${p.vib} m/min; fator ${p.fator11Vib ? 1.1 : 1.0}.',
        );
      }
      buffer.writeln(
        'Perfil condicionado à manutenção da cobertura após a redução; não prevê novo avanço ou escoamento hidráulico.',
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
    if (p.usarEnsaioAvanco) {
      buffer.writeln('Vazão do ensaio de avanço: ${p.vazaoEnsaioAvancoLs} L/s');
      buffer.writeln(
        'Condições do ensaio: ${p.condicoesEnsaioAvanco ?? 'não informadas'}',
      );
    }
    if (p.ensaioErosao case final ensaio?) {
      buffer.writeln(
        'Ensaio de erosão: ${ensaio.vazaoLs} L/s; '
        '${ensaio.erosaoObservada ? 'erosão observada' : 'erosão não observada'}; '
        '${ensaio.condicoes}.',
      );
    }
    buffer.writeln('Origem da infiltração: ${p.origemCurvaInfiltracao.name}');
    buffer.writeln('Hipótese de recessão: ${p.hipoteseRecessao.name}');
    buffer.writeln('');
    buffer.writeln('RESULTADOS');
    buffer.writeln('-' * 30);
    final linhasBalanco = codec.linhasRelatorioResultado(r);
    if (linhasBalanco.isEmpty) {
      buffer.writeln(
        'Eficiência de aplicação (Ea): ${r.eficiencia.toStringAsFixed(2)}%',
      );
    } else {
      for (final linha in linhasBalanco) {
        buffer.writeln(linha);
      }
    }
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

  String _numPt(double valor, int casas) =>
      valor.toStringAsFixed(casas).replaceFirst('.', ',');

  String _numStr(num valor) => '$valor'.replaceFirst('.', ',');

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
