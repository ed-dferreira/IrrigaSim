import 'package:flutter/material.dart';
import 'package:irrigasim/core/theme/app_icons.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_projeto.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_resultado.dart';
import 'package:irrigasim/features/irrigacao_faixas/services/faixa_planejamento.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_kpi.dart';

import '../border_charts.dart';
import 'border_results_kpis.dart';

/// Ícone por status: sucesso, atenção ou bloqueio (§10.3).
IconData iconeStatusBorder(BorderStatus status) => switch (status) {
  BorderStatus.validoNoModelo => AppIcons.sucesso,
  BorderStatus.avisoOrientativo => AppIcons.atencao,
  _ => AppIcons.statusBloqueio,
};

/// Texto humano por status; o código canônico é exibido ao lado.
String textoStatusBorder(BorderStatus status) => switch (status) {
  BorderStatus.validoNoModelo =>
    'Cálculo concluído dentro do modelo; nenhuma ressalva registrada.',
  BorderStatus.avisoOrientativo =>
    'Cálculo concluído; recomendações de referência são orientativas.',
  BorderStatus.entradaInvalida =>
    'Hidráulica calculada; há entrada pendente ou inválida a completar.',
  BorderStatus.foraDoDominio => 'Hidráulica calculada; geometria ou regime fora do domínio aceito pelo modelo.',
  BorderStatus.balancoInconsistente =>
    'Balanço volumétrico inconsistente com a infiltração informada.',
  BorderStatus.semConvergencia =>
    'Há falha de convergência numérica; revise tolerâncias e entradas.',
  BorderStatus.dadoFonteSuspeito =>
    'Há valor de fonte sob revisão; trate o resultado como suspeito.',
  BorderStatus.modeloNaoImplementado =>
    'Há regime pedido que este motor ainda não implementa.',
};

/// Seções auditáveis do resultado de faixa: indicadores, dados e hipóteses,
/// avanço e recessão, fórmulas, perfil e balanço, auditoria e detalhes técnicos.
List<Widget> secoesResultadoFaixa({
  required BuildContext context,
  required BorderProject project,
  required BorderResult r,
}) {
  final geo = const BorderPlanning().geometria(project, r);
  final colors = Theme.of(context).colorScheme;
  final text = Theme.of(context).textTheme;
  Widget row(
    String label,
    String value, {
    String? detail,
    bool warning = false,
  }) => IrrigationAuditRow(label, value, detail: detail, isWarning: warning);
  Widget section(
    String title,
    List<Widget> children, {
    bool advanced = false,
  }) => IrrigationAuditSection(
    title: title,
    icon: switch (title) {
      'Dados e hipóteses' => AppIcons.projetoArea,
      'Indicadores principais' => AppIcons.indicadores,
      'Avanço e recessão' => AppIcons.curvaAvanco,
      'Perfil e balanço' => AppIcons.balancoHidrico,
      'Auditoria e operação' => AppIcons.projetoOperacao,
      'Salvar este projeto' => AppIcons.salvarCenario,
      _ => AppIcons.relatorio,
    },
    initiallyExpanded: !advanced,
    children: children,
  );
  final areaParaDemandaM2 =
      project.areaUtilM2 ??
      (project.comprimentoAreaM != null && project.larguraAreaM != null
          ? project.comprimentoAreaM! * project.larguraAreaM!
          : null);
  final irnVolumeM3 = areaParaDemandaM2 == null
      ? null
      : areaParaDemandaM2 * project.irnEfetivaMm! / 1000;
  final demandaLiquidaDiariaMm =
      project.agronomia?.evapotranspiracaoMmDia == null ||
          project.agronomia?.precipitacaoEfetivaMmDia == null
      ? null
      : project.agronomia!.evapotranspiracaoMmDia! -
            project.agronomia!.precipitacaoEfetivaMmDia!;
  final demandaDiariaM3 =
      areaParaDemandaM2 == null || demandaLiquidaDiariaMm == null
      ? null
      : areaParaDemandaM2 * demandaLiquidaDiariaMm / 1000;
  final intervaloSimplificadoDias =
      demandaLiquidaDiariaMm == null || demandaLiquidaDiariaMm <= 0
      ? null
      : project.irnEfetivaMm! / demandaLiquidaDiariaMm;
  return [
    section('Indicadores principais', [
      IrrigationKpiGrid(
        items: kpisResultadoFaixa(r, project.comprimentoM!),
      ),
    ]),
    section('Dados e hipóteses', [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: r.status.bloqueia
              ? colors.errorContainer
              : r.status == BorderStatus.avisoOrientativo
              ? colors.tertiaryContainer
              : colors.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              iconeStatusBorder(r.status),
              color: r.status.bloqueia
                  ? colors.onErrorContainer
                  : r.status == BorderStatus.avisoOrientativo
                  ? colors.onTertiaryContainer
                  : colors.onPrimaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${textoStatusBorder(r.status)} (${r.status.codigo})',
                style: text.bodyLarge?.copyWith(
                  color: r.status.bloqueia
                      ? colors.onErrorContainer
                      : r.status == BorderStatus.avisoOrientativo
                      ? colors.onTertiaryContainer
                      : colors.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
      row(
        'Faixa aberta, vazão constante',
        '${f(project.comprimentoM!)} × ${f(project.larguraM!)} m',
      ),
      row(
        'Gleba bruta · área útil',
        '${f(project.comprimentoAreaM)} × ${f(project.larguraAreaM)} m · ${f(areaParaDemandaM2)} m²',
        detail: 'Área de demanda usa área útil informada ou produto das dimensões brutas quando área útil não foi cadastrada.',
      ),
      row(
        'Orientação · tipo de dique',
        '${project.orientacaoArea ?? 'não informada'} · ${project.tipoDique ?? 'não informado'}',
      ),
      row('q0', '${f(project.vazaoUnitariaLsM!)} L/s/m'),
      row('Qfaixa', '${f(project.vazaoFaixaLs!)} L/s'),
      row(
        'qmax F02',
        r.qmaxF02M3MinM == null
            ? 'Não informada (requer ρ1, ρ2 e Vmax)'
            : '${f(r.qmaxF02M3MinM!)} m³/min/m',
        detail: 'Vazão máxima não erosiva alternativa.',
      ),
      row(
        'IRN (${project.origemIrn.name})',
        '${f(project.irnEfetivaMm!)} mm',
      ),
      row(
        'Volume líquido IRN estimado',
        '${f(irnVolumeM3)} m³',
        detail: 'IRN × área considerada; não inclui perdas hidráulicas.',
      ),
      row(
        'Demanda líquida diária simplificada',
        '${f(demandaLiquidaDiariaMm)} mm/dia · ${f(demandaDiariaM3)} m³/dia',
      ),
      row(
        'Intervalo simplificado IRN/demanda',
        '${f(intervaloSimplificadoDias)} dias',
        detail: 'Derivação agronômica simplificada; não é balanço diário completo de chuva/armazenamento.',
      ),
      row(
        'Cenário de infiltração',
        project.cenarioInfiltracao.name,
      ),
      row(
        'Perfil longitudinal levantado',
        project.perfilLongitudinal.isEmpty
            ? 'Não informado; S0 único'
            : '${project.perfilLongitudinal.length} estações topográficas; S0 uniforme verificado',
      ),
      if (project.estacas.isNotEmpty)
        row(
          'Proveniência do ensaio',
          '${project.dataEnsaioIso ?? 'data não registrada'} · ${project.referenciaRelogioEnsaio ?? 'referência do relógio não registrada'} · ${project.observacoesEnsaio ?? 'sem observações'}',
        ),
      row(
        'Fonte e versão',
        '${BorderResult.documentoFonte} · ${BorderResult.versaoEquacoes} · ${BorderResult.paginasFonte}',
      ),
    ]),
    section('Avanço e recessão', [
      row('Oportunidade alvo t0', '${f(r.t0Min)} min'),
      row(
        'Avanço L/2 · L',
        '${f(r.taMetadeMin)} · ${f(r.taFinalMin)} min',
      ),
      row('Corte ti (calculado)', '${f(r.tiMin)} min'),
      row(
        'Depleção td · recessão final tr',
        '${f(r.tdMin)} · ${f(r.trFinalMin)} min',
      ),
      row(
        'Duração da depleção td−ti · da recessão tr−td',
        '${f(r.tdMin - r.tiMin)} · ${f(r.trFinalMin - r.tdMin)} min',
      ),
      row(
        'y0 · r · σz · qf',
        '${f(r.y0M)} m · ${f(r.r)} · ${f(r.sigmaZ)} · ${f(r.qfM3MinM)} m³/min/m',
      ),
    ]),
    section('Fórmulas e critérios', [
      const IrrigationFormulaCard(
        formula: 'Correções editoriais E04 · E09 · E10 · E16',
        description: 'Usa Sy=yf/L; separa tr=t0+ta de ti; fixa expoentes da p.43; e interpreta IRN como lâmina após conversão mm→m. E16 exige confirmação com a planilha original para reprodução oficial.',
      ),
      const IrrigationFormulaCard(
        formula: 'I(τ) = k·τᵃ + VIB·τ',
        description: 'Infiltração acumulada de Kostiakov–Lewis usada para obter a oportunidade alvo t0 (F06–F07).',
      ),
      const IrrigationFormulaCard(
        formula: 'Ea = 100·(IRN·Xa + Vd)/(q0·ti)',
        description: 'Verificação espacial do aproveitamento da água aplicada por metro de largura (F24).',
      ),
      const IrrigationFormulaCard(
        formula: 'Dmax = 0,4·hn  ·  Wmax = Dmax/|St|',
        description: 'Limite geométrico de desnível transversal e largura máxima quando há declividade transversal (pp. 13 e 19).',
      ),
    ], advanced: true),
    section('Perfil e balanço', [
      row(
        'Entrada · útil',
        '${f(r.volumeEntradaTotalM3)} · ${f(r.volumeUtilTotalM3)} m³',
      ),
      row(
        'Infiltrado total Vi = útil + percolado',
        '${f((r.volumeUtilM3M + r.volumePercoladoM3M) * r.larguraM)} m³',
      ),
      row(
        'Percolado · escoado · déficit',
        '${f(r.volumePercoladoTotalM3)} · ${f(r.volumeEscoadoTotalM3)} · ${f(r.volumeDeficitM3M * project.larguraM!)} m³',
      ),
      row(
        'Comprimento adequadamente irrigado Xa',
        '${f(r.comprimentoAdequadoM)} m',
      ),
      row(
        'Volume na região adequada Va',
        '${f(r.volumeAdequadoM3M * project.larguraM!)} m³',
      ),
      row(
        'Infiltração na região deficitária Vd',
        '${f(r.volumeDeficitarioM3M * project.larguraM!)} m³',
      ),
      row(
        'Infiltração final If (F21)',
        '${f(r.infiltracaoFinalM * 1000)} mm',
      ),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Perfil amostrado'),
        subtitle: const Text(
          'Distância · avanço · recessão · infiltração',
        ),
        children: [
          for (final point in r.perfil.where(
            (p) =>
                (p.xM / project.comprimentoM! * 400).round() % 40 == 0,
          ))
            row(
              '${f(point.xM)} m',
              '${f(point.avancoMin)} min · ${f(point.recessaoMin)} min · ${f(point.infiltracaoM * 1000)} mm',
            ),
        ],
      ),
    ]),
    section('Auditoria e operação', [
      row('Desnível transversal D', '${f(geo.desnivelM)} m'),
      if (geo.limiteDesnivelM != null)
        row('Dmáx = 0,4 hn', '${f(geo.limiteDesnivelM!)} m'),
      if (geo.larguraMaximaM != null)
        row('Wmáx = Dmáx/|St|', '${f(geo.larguraMaximaM!)} m'),
      if (geo.diqueSuficiente != null)
        row(
          'Verificação do dique em relação a y0',
          geo.diqueSuficiente! ? 'Suficiente' : 'Insuficiente',
        ),
      row(
        'Resíduo F07 · F09 · F19',
        '${r.residualOportunidadeM.toStringAsExponential(2)} m · ${r.residualAvancoM3M.toStringAsExponential(2)} m³/m · ${r.residualRecessaoMin.toStringAsExponential(2)} min',
      ),
      row(
        'Núcleo numérico: passo · resíduo · iterações',
        '${r.numerico.toleranciaPasso.toStringAsExponential(0)} · '
            '${r.numerico.toleranciaResiduo.toStringAsExponential(0)} · '
            '${r.numerico.maxIteracoes}',
      ),
      row(
        'Núcleo numérico: segmentos · expoentes · integração',
        '${r.numerico.nSegmentos} · ${r.numerico.versaoExpoentesRecessao} · ${r.numerico.metodoIntegracao}',
      ),
      for (final fonte in BorderResult.provenienciaHidraulicaExecutada)
        row(fonte.id, fonte.descricao),
      if (project.periodoDias != null &&
          project.jornadaHoras != null &&
          project.mudancaMin != null &&
          project.faixasSimultaneas != null &&
          project.janelaFornecimentoHorasDia != null &&
          project.inicioFornecimentoH != null &&
          project.diasFornecimento.isNotEmpty)
        Builder(
          builder: (context) {
            try {
              final op = const BorderPlanning().operacao(
                project,
                r,
                dias: project.periodoDias!,
                jornadaHoras: project.jornadaHoras!,
                mudancaMin: project.mudancaMin!,
                simultaneas: project.faixasSimultaneas!,
                janelaFornecimentoHorasDia:
                    project.janelaFornecimentoHorasDia!,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  row(
                    'TIP · NPD bruto · parcelas/dia',
                    '${f(op.tempoParcelaMin)} min · ${f(op.parcelasDiaBruto)} · ${op.parcelasCompletasDia}',
                  ),
                  row(
                    'APP · W0 teórica',
                    '${f(op.areaParcelaM2)} m² · ${f(op.larguraTeoricaM)} m',
                  ),
                  row(
                    'NTF · grupos · último lote',
                    '${op.faixasTotais} · ${op.grupos} · ${op.ultimoLote}',
                  ),
                  row(
                    'Qt simultânea',
                    '${f(op.vazaoSimultaneaLs)} L/s',
                  ),
                  row(
                    'Grupos programados por dia (1..PI)',
                    op.gruposPorDia.join(', '),
                  ),
                  for (final item in op.agenda) row('Horário', item),
                  row(
                    'Vazão por grupo (último lote parcial)',
                    op.vazoesPorGrupoLs
                        .map((q) => '${f(q)} L/s')
                        .join(' · '),
                  ),
                  row(
                    'Prazo · oferta',
                    '${op.atendePrazo ? 'Atende' : 'Não atende'} · ${op.atendeOferta ? 'Atende' : 'Não atende / pendente'}',
                  ),
                ],
              );
            } on FormatException catch (e) {
              return Text(e.message);
            }
          },
        ),
    ]),
    section('Detalhes técnicos', [
      BorderConvergenceDetails(result: r),
    ], advanced: true),
  ];
}
