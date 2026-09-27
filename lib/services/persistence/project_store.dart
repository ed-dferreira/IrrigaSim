import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/cenario_salvo.dart';

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
        'declividade': 'm/m',
        'vazao': 'L/s',
        'tempo': 'min',
        'lamina': 'mm',
        'eficiencia': '%',
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
        'tempo_avanco_metade_min': p.tempoAvancoMetadeMin,
        'tempo_avanco_final_min': p.tempoAvancoFinalMin,
        'manejo_sulco': p.manejoSulco.name,
        'vazao_reduzida_l_s': p.vazaoReduzidaLs,
        'tempo_mudanca_min': p.tempoMudancaMin,
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
    buffer.writeln('Manejo: ${p.manejoSulco.displayName}');
    if (p.manejoSulco == ManejoSulco.reduzida) {
      buffer.writeln(
        'Vazão reduzida: ${p.vazaoReduzidaLs.toStringAsFixed(2)} L/s',
      );
      buffer.writeln(
        'Tempo de mudança: ${p.tempoMudancaMin.toStringAsFixed(0)} min',
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
    buffer.writeln(
      'Perda por percolação: ${r.perdaPercolacao.toStringAsFixed(2)}%',
    );
    buffer.writeln(
      'Perda por escoamento: ${r.perdaEscoamento.toStringAsFixed(2)}%',
    );
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
