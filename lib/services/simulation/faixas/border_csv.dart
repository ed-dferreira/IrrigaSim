import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/faixas/border_result.dart';

import 'border_field_trial.dart';

String _escaped(String text) =>
    text.contains(RegExp('[;"\n]')) ? '"${text.replaceAll('"', '""')}"' : text;

String borderTrialCsv(
  BorderProject p,
  BorderTrialResult r, {
  BorderResult? simulacao,
}) => [
  'campo;valor;unidade',
  'modelo;ensaio medido p.45 F08;',
  'status;${r.status.codigo};',
  'data_ensaio;${p.dataEnsaioIso ?? 'não registrada'};AAAA-MM-DD',
  'referencia_relogio_ensaio;${_escaped(p.referenciaRelogioEnsaio ?? 'não registrada')};',
  'observacoes_ensaio;${_escaped(p.observacoesEnsaio ?? 'nenhuma')};',
  for (final notice in r.avisos)
    'aviso;${_escaped('[${notice.codigo}] ${notice.mensagem}')};'
        '${notice.pagina ?? ''}',
  'q0;${p.vazaoUnitariaLsM};L/s/m',
  'corte_medido;${p.corteEnsaioMin ?? ''};min',
  'data_ensaio;${p.dataEnsaioIso ?? 'não registrada'};AAAA-MM-DD',
  'referencia_relogio_ensaio;${_escaped(p.referenciaRelogioEnsaio ?? 'não registrada')};',
  'observacoes_ensaio;${_escaped(p.observacoesEnsaio ?? 'nenhuma')};',
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
  'residuo_avanco_por_estaca;x_m;avanco_medido_min;avanco_ajustado_min;residuo_min',
  for (final s in r.advance.stakes.skip(1))
    '${s.xM};${s.avancoMin};${r.advance.arrival(s.xM)};${r.advance.arrival(s.xM) - s.avancoMin}',
  '',
  'x_m;avanco_ajustado_min;recessao_interpolada_min;infiltracao_m',
  for (final v in r.profile)
    '${v.xM};${v.avancoMin};${v.recessaoMin};${v.infiltracaoM}',
  if (simulacao != null) ...[
    '',
    'x_simulado_m;avanco_simulado_min;recessao_simulada_min;infiltracao_simulada_m',
    for (final point in simulacao.perfil)
      '${point.xM};${point.avancoMin};${point.recessaoMin};${point.infiltracaoM}',
  ],
].join('\n');

String borderCsv(BorderProject p, BorderResult r) {
  final numerico = r.numerico;
  final geoPendente = p.alturaDiqueM == null || p.laminaSuperficialM == null;
  final geoInvalida =
      !geoPendente &&
      (!p.alturaDiqueM!.isFinite ||
          !p.laminaSuperficialM!.isFinite ||
          p.alturaDiqueM! <= 0 ||
          p.laminaSuperficialM! <= 0 ||
          r.y0M > p.alturaDiqueM! ||
          (p.declividadeTransversal?.abs() ?? 0) * p.larguraM! >
              .4 * p.laminaSuperficialM!);
  final geoStatus = geoPendente
      ? 'pendente'
      : geoInvalida
      ? 'inviável'
      : 'verificada';
  final areaDemandaM2 =
      p.areaUtilM2 ??
      (p.comprimentoAreaM != null && p.larguraAreaM != null
          ? p.comprimentoAreaM! * p.larguraAreaM!
          : null);
  final volumeIrnM3 = areaDemandaM2 == null || p.irnEfetivaMm == null
      ? null
      : areaDemandaM2 * p.irnEfetivaMm! / 1000;
  final demandaLiquidaMmDia =
      p.agronomia?.evapotranspiracaoMmDia == null ||
          p.agronomia?.precipitacaoEfetivaMmDia == null
      ? null
      : p.agronomia!.evapotranspiracaoMmDia! -
            p.agronomia!.precipitacaoEfetivaMmDia!;
  final lines = <String>[
    'campo;valor;unidade',
    'versao_entrada;${p.versao};',
    'versao_equacoes;${BorderResult.versaoEquacoes};',
    'documento_fonte;${BorderResult.documentoFonte};',
    'paginas_fonte;${BorderResult.paginasFonte};',
    'status;${r.status.codigo};',
    'correcao_E04;aplicada;Sy=yf/L conforme pp.63/65;divisão por L',
    'correcao_E09;aplicada;tr=t0+ta e ti calculado separadamente;pp.43/64',
    'correcao_E10;aplicada;expoentes de recessão da p.43;versão ${r.numerico.versaoExpoentesRecessao}',
    'hipotese_E16;aplicada;IRN interpretada como lâmina em m após conversão de mm;confirmar planilha da p.73 antes de tratar como gabarito',
    'veredicto_projeto;${r.status.bloqueia ? 'pendente_ou_inviavel' : 'hidraulica_calculada_sem_bloqueio_hidraulico'};',
    'etapa_hidraulica;executada;resultado hidráulico parcial disponível;',
    'etapa_geometria;$geoStatus;altura real do dique e hn',
    'etapa_ensaio;${p.estacas.isEmpty ? 'não_executada' : 'dados_medidos_presentes_avaliação_não_anexada'};F08 independente',
    'etapa_busca;${p.alternativas.isEmpty ? 'não_executada' : 'alternativas_persistidas'};F26 não inferida do resultado hidráulico',
    'etapa_cronograma;pendente_ou_não_anexado;oferta e prazos não declarados executáveis por este CSV hidráulico',
    for (final notice in r.avisos)
      'aviso;${_escaped('[${notice.codigo}] ${notice.mensagem}')};'
          '${notice.pagina ?? ''}',
    // Proveniência por bloco e por fórmula executada (documento, página,
    // versão e origem medida/assumida/derivada).
    for (final bloco in BorderResult.blocosFonte.entries.where(
      (entry) =>
          !entry.key.startsWith('F26') &&
          !entry.key.startsWith('F27') &&
          !entry.key.startsWith('Tabelas'),
    ))
      'bloco;${_escaped(bloco.key)};${bloco.value}',
    for (final fonte in BorderResult.provenienciaHidraulicaExecutada)
      'formula_${fonte.id};${_escaped(fonte.descricao)};'
          '${fonte.pagina} · ${fonte.versao} · ${fonte.origem.name}',
    // Grupo numérico declarado e usado nesta execução.
    'num_tolerancia_passo;${numerico.toleranciaPasso};min',
    'num_tolerancia_residuo;${numerico.toleranciaResiduo};residuo',
    'num_max_iteracoes;${numerico.maxIteracoes};iteracoes',
    'num_n_segmentos;${numerico.nSegmentos};pontos',
    'num_versao_expoentes;${numerico.versaoExpoentesRecessao};',
    'num_metodo_integracao;${numerico.metodoIntegracao};',
    for (final iteracao in <(String, List<double>)>[
      ('t0_min', r.convergencia.opportunityMin),
      ('r', r.convergencia.advanceExponent),
      ('td_min', r.convergencia.recessionEndMin),
    ])
      for (var i = 0; i < iteracao.$2.length; i++)
        'convergencia_${iteracao.$1};${iteracao.$2[i]};iteracao ${i + 1}',
    'jusante;${p.jusante.name};',
    'cobertura;${p.cobertura.name};',
    'tipo_dique;${p.tipoDique ?? 'não informado'};registro construtivo',
    'rho1_F02;${p.rho1F02 ?? ''};transcrito; fórmula não executada',
    'rho2_F02;${p.rho2F02 ?? ''};transcrito; fórmula não executada',
    'vmax_F02;${p.vmaxF02 ?? ''};${p.unidadeVmaxF02 ?? 'unidade não informada'}; fórmula bloqueada',
    'status_F02;modelo_nao_implementado;Vmax/unidade/convenção insuficientes na fonte',
    'formula_F02;[Vmax^rho2*n^2/(3600*S0*rho1)]^[1/(rho2-2)];bloqueada: Vmax e unidades/convenção não definidas',
    'orientacao_area;${p.orientacaoArea ?? 'não informada'};registro topográfico',
    'area_util;${p.areaUtilM2 ?? ''};m2',
    'data_ensaio;${p.dataEnsaioIso ?? 'não registrada'};AAAA-MM-DD',
    'referencia_relogio_ensaio;${_escaped(p.referenciaRelogioEnsaio ?? 'não registrada')};',
    'observacoes_ensaio;${_escaped(p.observacoesEnsaio ?? 'nenhuma')};',
    'perfil_longitudinal;${p.perfilLongitudinal.map((point) => '${point.xM}:${point.cotaM}').join('|')};x m:cota m',
    'proveniencia_entrada;perfilLongitudinal;${p.perfilLongitudinal.isEmpty ? 'não informado' : 'levantamento topográfico'};estações x:cota',
    'proveniencia_entrada;orientacaoArea;${p.orientacaoArea == null ? 'pendente' : 'informada'};descrição',
    'proveniencia_entrada;dataEnsaioIso;${p.dataEnsaioIso == null ? 'não registrada' : 'informada'};AAAA-MM-DD',
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
    'area_demanda;${areaDemandaM2 ?? ''};m2;área útil informada ou área bruta',
    'volume_liquido_IRN;${volumeIrnM3 ?? ''};m3;derivado IRN × área, sem perdas hidráulicas',
    'demanda_liquida_diaria;${demandaLiquidaMmDia ?? ''};mm/dia;ETc menos precipitação efetiva',
    'volume_demanda_diaria;${areaDemandaM2 == null || demandaLiquidaMmDia == null ? '' : areaDemandaM2 * demandaLiquidaMmDia / 1000};m3/dia;derivação simplificada',
    'intervalo_IRN_demanda;${demandaLiquidaMmDia == null || demandaLiquidaMmDia <= 0 || p.irnEfetivaMm == null ? '' : p.irnEfetivaMm! / demandaLiquidaMmDia};dias;derivado simplificado sem balanço diário completo',
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
    'corte_antecipado_referencia;${p.fracaoCortePlanejada?.toString() ?? 'não selecionado'};fração de L · motor não implementado quando selecionado',
    for (final alt in p.alternativas)
      'alternativa;${_escaped('${alt.comprimentoM}|${alt.vazaoLsM}|${alt.eficienciaPercentual ?? ''}|${alt.erPercentual ?? ''}|${alt.ppPercentual ?? ''}|${alt.pePercentual ?? ''}|${alt.demandaLs ?? ''}|${alt.motivoRejeicao ?? ''}|${alt.status?.codigo ?? ''}|selecionada=${alt.selecionada}|qmin=${alt.gradeMenorLsM ?? ''}|qmax=${alt.gradeMaiorLsM ?? ''}|passo=${alt.gradePassoLsM ?? ''}|objetivo=${alt.objetivo ?? ''}')};L m|q0 L/s/m|Ea %|Er %|Pp %|Pe %|Q L/s|rejeição|status|escolha|grade',
    'q0;${p.vazaoUnitariaLsM};L/s/m',
    'Qfaixa;${p.vazaoFaixaLs};L/s',
    'booher_diametro_selecionado;${p.dispositivoDiametroCm ?? ''};cm',
    'booher_carga_selecionada;${p.dispositivoCargaCm ?? ''};cm',
    for (final entrada in <(String, Object?, String, String)>[
      ('comprimentoM', p.comprimentoM, 'm', 'informada'),
      ('larguraM', p.larguraM, 'm', 'informada'),
      ('comprimentoAreaM', p.comprimentoAreaM, 'm', 'informada'),
      ('larguraAreaM', p.larguraAreaM, 'm', 'informada'),
      ('areaUtilM2', p.areaUtilM2, 'm2', 'informada'),
      (
        'fracaoCortePlanejada',
        p.fracaoCortePlanejada,
        'L/L',
        'regra de corte condicional; não calculada',
      ),
      (
        'baseLongitudinalM',
        p.baseLongitudinalM,
        'm',
        'informada no levantamento',
      ),
      (
        'desnivelLongitudinalM',
        p.desnivelLongitudinalM,
        'm',
        'informada no levantamento',
      ),
      (
        'baseTransversalM',
        p.baseTransversalM,
        'm',
        'informada no levantamento',
      ),
      (
        'desnivelTransversalM',
        p.desnivelTransversalM,
        'm',
        'informada no levantamento',
      ),
      (
        'declividadeLongitudinal',
        p.declividadeLongitudinal,
        'm/m',
        'derivada do levantamento',
      ),
      (
        'declividadeTransversal',
        p.declividadeTransversal,
        'm/m',
        'derivada do levantamento',
      ),
      ('alturaDiqueM', p.alturaDiqueM, 'm', 'informada'),
      ('laminaSuperficialM', p.laminaSuperficialM, 'm', 'informada'),
      ('k', p.k, 'm/min^a', 'informada'),
      ('a', p.a, 'adimensional', 'informada'),
      ('vibMMin', p.vibMMin, 'm/min', 'informada'),
      ('rugosidadeN', p.rugosidadeN, 'adimensional', 'informada'),
      ('vazaoUnitariaLsM', p.vazaoUnitariaLsM, 'L/s/m', 'informada'),
      (
        'irnMm',
        p.irnEfetivaMm,
        'mm',
        p.origemIrn == OrigemIrnFaixa.calculada
            ? 'derivada agronomicamente'
            : 'informada',
      ),
      ('vazaoDisponivelLs', p.vazaoDisponivelLs, 'L/s', 'informada'),
      (
        'rho1F02',
        p.rho1F02,
        'não confirmada',
        'informada apenas para auditoria F02',
      ),
      (
        'rho2F02',
        p.rho2F02,
        'não confirmada',
        'informada apenas para auditoria F02',
      ),
      (
        'vmaxF02',
        p.vmaxF02,
        p.unidadeVmaxF02 ?? 'unidade ausente',
        'não usada; F02 bloqueada',
      ),
      (
        'kPrimeira',
        p.dadosPrimeira?.k,
        'm/min^a',
        'informada para primeira irrigação',
      ),
      (
        'aPrimeira',
        p.dadosPrimeira?.a,
        'adimensional',
        'informada para primeira irrigação',
      ),
      (
        'vibPrimeira',
        p.dadosPrimeira?.vibMMin,
        'm/min',
        'informada para primeira irrigação',
      ),
      (
        'kTerceira',
        p.dadosTerceira?.k,
        'm/min^a',
        'informada para terceira irrigação',
      ),
      (
        'aTerceira',
        p.dadosTerceira?.a,
        'adimensional',
        'informada para terceira irrigação',
      ),
      (
        'vibTerceira',
        p.dadosTerceira?.vibMMin,
        'm/min',
        'informada para terceira irrigação',
      ),
      ('uccPercentual', p.agronomia?.uccPercentual, '%', 'informada'),
      ('upmpPercentual', p.agronomia?.upmpPercentual, '%', 'informada'),
      ('densidadeGcm3', p.agronomia?.densidadeGcm3, 'g/cm3', 'informada'),
      ('kc', p.agronomia?.kc, 'coeficiente', 'informada'),
      (
        'espacamentoFileirasM',
        p.agronomia?.espacamentoFileirasM,
        'm',
        'informada',
      ),
      (
        'espacamentoPlantasM',
        p.agronomia?.espacamentoPlantasM,
        'm',
        'informada',
      ),
      (
        'profundidadeRaizesCm',
        p.agronomia?.profundidadeRaizesCm,
        'cm',
        'informada',
      ),
      (
        'fracaoDisponivel',
        p.agronomia?.fracaoDisponivel,
        'fração',
        'informada',
      ),
      (
        'evapotranspiracaoMmDia',
        p.agronomia?.evapotranspiracaoMmDia,
        'mm/dia',
        'informada',
      ),
      (
        'precipitacaoEfetivaMmDia',
        p.agronomia?.precipitacaoEfetivaMmDia,
        'mm/dia',
        'informada',
      ),
      ('jornadaHoras', p.jornadaHoras, 'h/dia', 'informada'),
      (
        'janelaFornecimentoHorasDia',
        p.janelaFornecimentoHorasDia,
        'h/dia',
        'informada',
      ),
      ('inicioFornecimentoH', p.inicioFornecimentoH, 'h', 'informada'),
      ('mudancaMin', p.mudancaMin, 'min', 'informada'),
      ('periodoDias', p.periodoDias, 'dias', 'informado'),
      ('faixasSimultaneas', p.faixasSimultaneas, 'faixas', 'informado'),
      ('booherDiametroCm', p.dispositivoDiametroCm, 'cm', 'seleção de tabela'),
      ('booherCargaCm', p.dispositivoCargaCm, 'cm', 'seleção de tabela'),
    ])
      'proveniencia_entrada;${entrada.$1};${entrada.$2 == null ? 'pendente' : entrada.$4};${entrada.$3}',
    'proveniencia_entrada;estacas;${p.estacas.isEmpty ? 'pendente' : 'medida em campo'};x m|ta min|tr min',
    'contexto_entradas;cenario=${p.cenarioInfiltracao.name}|irn=${p.origemIrn.name}|cultura=${p.cultura ?? 'não informada'}|data= não registrada;',
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
    'infiltrado_total;${(r.volumeUtilM3M + r.volumePercoladoM3M) * r.larguraM};m3',
    'escoado;${r.volumeEscoadoTotalM3};m3',
    'Ea;${r.ea};%',
    'Er;${r.er};%',
    'Pp;${r.pp};%',
    'Pe;${r.pe};%',
    'comprimento_adequadamente_irrigado;${r.comprimentoAdequadoM};m',
    'Va_infiltrado_regiao_adequada;${r.volumeAdequadoM3M * r.larguraM};m3',
    'Vd_infiltrado_regiao_deficitaria;${r.volumeDeficitarioM3M * r.larguraM};m3',
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
