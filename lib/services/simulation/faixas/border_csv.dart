import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/faixas/border_result.dart';

import 'border_field_trial.dart';

String _escaped(String text) => text.contains(RegExp('[;"\n]'))
    ? '"${text.replaceAll('"', '""')}"'
    : text;

String borderTrialCsv(BorderProject p, BorderTrialResult r) => [
  'campo;valor;unidade',
  'modelo;ensaio medido p.45 F08;',
  'status;${r.status.codigo};',
  for (final notice in r.avisos)
    'aviso;${_escaped('[${notice.codigo}] ${notice.mensagem}')};'
        '${notice.pagina ?? ''}',
  'q0;${p.vazaoUnitariaLsM};L/s/m',
  'corte_medido;${p.corteEnsaioMin ?? ''};min',
  'p;${r.advance.p};m/min^r',
  'r;${r.advance.r};',
  'rmse;${r.advance.rmseMin};min',
  'entrada;${r.entradaM3M ?? ''};m3/m',
  'util;${r.utilM3M ?? ''};m3/m',
  'percolado;${r.percoladoM3M ?? ''};m3/m',
  'escoado;${r.escoadoM3M ?? ''};m3/m',
  'deficit;${r.deficitM3M ?? ''};m3/m',
  'Ea;${r.ea ?? ''};%',
  'Er;${r.utilM3M == null || p.irnEfetivaMm == null || p.comprimentoM == null ? '' : 100 * r.utilM3M! / (p.irnEfetivaMm! / 1000 * p.comprimentoM!)};%',
  'Pp;${r.percoladoM3M == null || r.entradaM3M == null ? '' : 100 * r.percoladoM3M! / r.entradaM3M!};%',
  'Pe;${r.escoadoM3M == null || r.entradaM3M == null ? '' : 100 * r.escoadoM3M! / r.entradaM3M!};%',
  '',
  'estaca_x_m;avanco_medido_min;recessao_medido_min',
  for (final s in r.advance.stakes)
    '${s.xM};${s.avancoMin};${s.recessaoMin ?? ''}',
  '',
  'x_m;avanco_ajustado_min;recessao_interpolada_min;infiltracao_m',
  for (final v in r.profile)
    '${v.xM};${v.avancoMin};${v.recessaoMin};${v.infiltracaoM}',
].join('\n');

String borderCsv(BorderProject p, BorderResult r) {
  final numerico = r.numerico;
  final lines = <String>[
    'campo;valor;unidade',
    'versao_entrada;${p.versao};',
    'versao_equacoes;${BorderResult.versaoEquacoes};',
    'documento_fonte;${BorderResult.documentoFonte};',
    'paginas_fonte;${BorderResult.paginasFonte};',
    'status;${r.status.codigo};',
    for (final notice in r.avisos)
      'aviso;${_escaped('[${notice.codigo}] ${notice.mensagem}')};'
          '${notice.pagina ?? ''}',
    // Proveniência por bloco e por fórmula executada (documento, página,
    // versão e origem medida/assumida/derivada).
    for (final bloco in BorderResult.blocosFonte.entries)
      'bloco;${_escaped(bloco.key)};${bloco.value}',
    for (final fonte in BorderResult.proveniencia)
      'formula_${fonte.id};${_escaped(fonte.descricao)};'
          '${fonte.pagina} · ${fonte.versao} · ${fonte.origem.name}',
    // Grupo numérico declarado e usado nesta execução.
    'num_tolerancia_passo;${numerico.toleranciaPasso};min',
    'num_tolerancia_residuo;${numerico.toleranciaResiduo};residuo',
    'num_max_iteracoes;${numerico.maxIteracoes};iteracoes',
    'num_n_segmentos;${numerico.nSegmentos};pontos',
    'num_versao_expoentes;${numerico.versaoExpoentesRecessao};',
    'num_metodo_integracao;${numerico.metodoIntegracao};',
    'jusante;${p.jusante.name};',
    'cobertura;${p.cobertura.name};',
    'manejo;${p.manejo.name};',
    'origem_irn;${p.origemIrn.name};',
    'metodo;faixa;',
    'cenario_infiltracao;${p.cenarioInfiltracao.name};',
    'comprimento;${p.comprimentoM};m',
    'largura;${p.larguraM};m',
    'declividade_longitudinal;${p.declividadeLongitudinal};m/m',
    'declividade_transversal;${p.declividadeTransversal};m/m',
    'k;${p.k};m/min^a',
    'a;${p.a};',
    'VIB;${p.vibMMin};m/min',
    'rugosidade_n;${p.rugosidadeN};',
    'IRN;${p.irnEfetivaMm};mm',
    'agronomia;${p.agronomia?.toMap() ?? 'não informada'};',
    'dias_fornecimento;${p.diasFornecimento.join(',')};dias no PI',
    'janela_fornecimento;${p.janelaFornecimentoHorasDia};h/dia',
    'inicio_fornecimento;${p.inicioFornecimentoH};h',
    'periodo;${p.periodoDias};dias',
    'jornada;${p.jornadaHoras};h/dia',
    'mudanca;${p.mudancaMin};min',
    'simultaneas;${p.faixasSimultaneas};faixas',
    'estacas;${p.estacas.map((s) => '${s.xM}:${s.avancoMin}:${s.recessaoMin ?? ''}').join('|')};m:min:min',
    'corte_ensaio;${p.corteEnsaioMin};min',
    for (final alt in p.alternativas)
      'alternativa;${_escaped('${alt.comprimentoM}|${alt.vazaoLsM}|${alt.eficienciaPercentual ?? ''}|${alt.motivoRejeicao ?? ''}|${alt.status?.codigo ?? ''}')};L m|q0 L/s/m|Ea %|rejeição|status',
    'q0;${p.vazaoUnitariaLsM};L/s/m',
    'Qfaixa;${p.vazaoFaixaLs};L/s',
    't0;${r.t0Min};min',
    'ta_L2;${r.taMetadeMin};min',
    'ta_L;${r.taFinalMin};min',
    'ti;${r.tiMin};min',
    'td;${r.tdMin};min',
    'tr_L;${r.trFinalMin};min',
    'r;${r.r};',
    'sigma_z;${r.sigmaZ};',
    'entrada;${r.volumeEntradaTotalM3};m3',
    'util;${r.volumeUtilTotalM3};m3',
    'percolado;${r.volumePercoladoTotalM3};m3',
    'escoado;${r.volumeEscoadoTotalM3};m3',
    'Ea;${r.ea};%',
    'Er;${r.er};%',
    'Pp;${r.pp};%',
    'Pe;${r.pe};%',
    'comprimento_adequadamente_irrigado;${r.comprimentoAdequadoM};m',
    'infiltracao_regiao_adequada;${r.volumeAdequadoM3M * r.larguraM};m3',
    'infiltracao_regiao_deficitaria;${r.volumeDeficitarioM3M * r.larguraM};m3',
    'infiltracao_final_F21;${r.infiltracaoFinalM};m',
    'residuo_oportunidade;${r.residualOportunidadeM};m',
    'residuo_avanco;${r.residualAvancoM3M};m3/m',
    'residuo_recessao;${r.residualRecessaoMin};min',
    '',
    'x_m;avanco_min;recessao_min;oportunidade_min;infiltracao_m',
    for (final point in r.perfil)
      '${point.xM};${point.avancoMin};${point.recessaoMin};${point.oportunidadeMin};${point.infiltracaoM}',
  ];
  return '${lines.join('\n')}\n';
}
