// Exportação CSV do projeto e do resultado de inundação (Fase 6). Segue o
// formato das faixas (lib/services/simulation/faixas/border_csv.dart):
// separador ponto-e-vírgula, bloco campo;valor;unidade, e para o regime
// intermitente o perfil hidráulico em 41 pontos (G7), com o mesmo cabeçalho
// x_m;tempo_avanco_min;lamina_mm do pacote de referência.
import 'package:irrigasim/features/irrigacao_inundacao/models/basin_project.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';

String _escaped(String text) =>
    text.contains(RegExp('[;"\n]')) ? '"${text.replaceAll('"', '""')}"' : text;

String basinCsv(BasinProject p, SimulationResult r) {
  final linhas = <String>[
    'campo;valor;unidade',
    'versao_entrada;${p.versao};',
    'documento_fonte;Aula 8 — Irrigação por Inundação (UNIPAMPA);',
    'paginas_fonte;16,17,20,34-35,38,45,54-62,64-84;',
    'regime;${p.regime.displayName};',
    'cenario_infiltracao;${p.cenarioInfiltracao.displayName};',
    'status_modelo;${p.impedimento?.status.codigo ?? 'valido_no_modelo'};',
    if (p.impedimento != null)
      'aviso_modelo;${_escaped(p.impedimento!.mensagem)};'
          '${p.impedimento!.pagina ?? ''}',
    // Geometria e taipa.
    'comprimento_area_m;${p.comprimentoAreaM ?? ''};m',
    'largura_area_m;${p.larguraAreaM ?? ''};m',
    'comprimento_tabuleiro_m;${p.comprimentoM ?? ''};m',
    'largura_tabuleiro_m;${p.larguraM ?? ''};m',
    'area_tabuleiro_m2;${p.areaTabuleiroM2 ?? ''};m²',
    'area_declarada_m2;${p.areaTotalM2 ?? ''};m²',
    'declividade;${p.declividade ?? ''};m/m',
    'lamina_media_planalto_m;${p.laminaMediaPlanaltoM ?? ''};m',
    'desnivel_admissivel_m;${p.desnivelAdmissivelM ?? ''};m',
    'desnivel_real_m;${p.desnivelRealM ?? ''};m',
    'comprimento_maximo_regra_2_3_m;${p.comprimentoMaximoDesnivelM ?? ''};m',
    'altura_dique_m;${p.alturaDiqueM ?? ''};m',
    'base_dique_m;${p.baseDiqueM ?? ''};m',
    'margem_livre_m;${p.margemLivreM ?? ''};m',
    // Solo e infiltração (ρ1/ρ2 apenas como auditoria, G6).
    'k;${p.k ?? ''};m/min^a',
    'a;${p.a ?? ''};—',
    'vib;${p.vibMMin ?? ''};m/min',
    'rugosidade_n;${p.rugosidadeN ?? ''};—',
    'rho1_auditoria_f02;${p.rho1F02 ?? ''};—',
    'rho2_auditoria_f02;${p.rho2F02 ?? ''};—',
    'vmax_auditoria_f02;${p.vmaxF02 ?? ''};m/min',
  ];
  if (p.regime == TipoInundacao.intermitente) {
    linhas.addAll([
      'lamina_requerida_mm;${p.laminaRequeridaMm ?? ''};mm',
      'vazao_total_aplicada_l_s;${p.vazaoAplicadaLs ?? ''};L/s',
      'vazao_nao_erosiva_total_l_s;${p.q0MaxLsTotal ?? ''};L/s',
      'vmax_m_min;${p.vmaxMMin};m/min',
      'et_intermitente_mm_dia;${p.etIntermitenteMmDia ?? ''};mm/dia',
      'intervalo_dias;${p.intervaloDias ?? ''};dias',
      if (p.candidatasVazaoLs.isNotEmpty)
        'candidatas_vazao_l_s;${p.candidatasVazaoLs.join(',')};L/s',
    ]);
  } else {
    linhas.addAll([
      'area_irrigada_ha;${p.areaHectares ?? ''};ha',
      'porosidade;${p.porosidade ?? ''};—',
      'profundidade_camada_mm;${p.profundidadeCamadaMm ?? ''};mm',
      'condutividade_k0_mm_dia;${p.condutividadeHidraulicaMmDia ?? ''};mm/dia',
      'dta_mm_cm;${p.dtaMmCm ?? ''};mm/cm',
      'fator_disponibilidade;${p.fatorDisponibilidade ?? ''};—',
      'evapotranspiracao_mm_dia;${p.evapotranspiracaoMmDia ?? ''};mm/dia',
      'lamina_superficial_mm;${p.laminaSuperficialMm ?? ''};mm',
    ]);
  }
  linhas.addAll([
    'vazao_disponivel_l_s;${p.vazaoDisponivelLps ?? ''};L/s',
    'jornada_h;${p.jornadaHoras};h',
    'mudanca_parcela_min;${p.mudancaParcelaMin};min',
    'periodo_dias;${p.periodoDias};dias',
    'tabuleiros_por_parcela;${p.tabuleirosPorParcela};un.',
    // Resultado.
    'Ea;${r.eficiencia};%',
    'eficiencia_requerimento;${r.eficienciaRequerimento};%',
    'cuc;${r.cuc};%',
    'du;${r.du};%',
    'lamina_media;${r.laminaMedia};m',
    'lamina_requerida;${r.laminaRequerida};m',
    'tempo_avanco_min;${r.tempoAvanco};min',
    'perda_percolacao;${r.perdaPercolacao};%',
    'perda_escoamento;${r.perdaEscoamento};%',
    if (r.alertaVazaoExcedida != null)
      'alerta_vazao;${_escaped(r.alertaVazaoExcedida!)};',
    if (r.alertaInfiltracao != null)
      'alerta_infiltracao;${_escaped(r.alertaInfiltracao!)};',
  ]);

  final metricasOrdenadas = r.metricas.keys.toList()..sort();
  for (final chave in metricasOrdenadas) {
    linhas.add(
      'metrica;${_escaped(chave)};${r.metricas[chave]};'
      '${_escaped(r.unidadesMetricas[chave] ?? '')}',
    );
  }

  final parcelas = r.planejamentoParcelas;
  if (parcelas != null) {
    linhas.addAll([
      'planejamento_tpp_min;${parcelas.tppMin};min',
      'planejamento_npd_teorico;${parcelas.npdTeorico};parcelas/dia',
      'planejamento_npd;${parcelas.npdInteiro};parcelas/dia',
      'planejamento_app_m2;${parcelas.appM2};m²',
      'planejamento_w0_m;${parcelas.larguraTabuleiroM};m',
      'planejamento_ntt;${parcelas.ntt};tabuleiros',
      'planejamento_q_total_l_s;${parcelas.qTotalLS};L/s',
    ]);
  }
  final selecao = r.selecaoVazao;
  if (selecao != null) {
    linhas.addAll([
      'selecao_vazao_l_s;${selecao.vazaoEscolhidaLs};L/s',
      'selecao_q0_m3_min_m;${selecao.q0M3MinM};m³/(min·m)',
      'selecao_ea_percent;${selecao.eficienciaPercent};%',
      'selecao_candidatas_avaliadas;${selecao.candidatasAvaliadas};un.',
      'selecao_candidatas_rejeitadas;${selecao.candidatasRejeitadas};un.',
    ]);
  }
  final volumes = r.volumesArroz?.volumes;
  if (volumes != null) {
    linhas.addAll([
      'arroz_pt;${volumes.pt};—',
      'arroz_us;${volumes.us};—',
      'arroz_v1_m3_ha;${volumes.v1M3Ha ?? ''};m³/ha',
      'arroz_v2_m3_ha;${volumes.v2M3Ha};m³/ha',
      'arroz_v3_m3_ha;${volumes.v3M3Ha};m³/ha',
      'arroz_v4_m3_ha;${volumes.v4M3Ha};m³/ha',
      'arroz_v5_m3_ha;${volumes.v5M3Ha ?? ''};m³/ha',
      'arroz_vt_m3_ha;${volumes.vtM3Ha ?? ''};m³/ha',
      'arroz_materia_seca_kg_ha;${volumes.materiaSecaTotalKgHa ?? ''};kg/ha',
      'arroz_q1_m3_s;${volumes.q1M3S ?? ''};m³/s',
      'arroz_q2_m3_s;${volumes.q2M3S ?? ''};m³/s',
      for (final ausente in volumes.dadosAusentes)
        'arroz_dado_ausente;${_escaped(ausente)};',
    ]);
  }

  // Perfil hidráulico do regime intermitente (G7): 41 pontos em L = 200 m.
  if (p.regime == TipoInundacao.intermitente &&
      r.curvaAvanco.isNotEmpty &&
      r.perfilLongitudinal.length == r.curvaAvanco.length) {
    linhas
      ..add('')
      ..add('x_m;tempo_avanco_min;lamina_mm');
    for (var i = 0; i < r.curvaAvanco.length; i++) {
      final ponto = r.curvaAvanco[i];
      linhas.add('${ponto.y};${ponto.x};${(r.perfilLongitudinal[i] * 1000)}');
    }
  }
  return linhas.join('\n');
}
