import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/models/faixas/border_result.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/simulation_result.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/services/simulation/faixas/border_planning.dart';
import 'package:irrigasim/services/simulation/faixas/border_csv.dart';
import 'package:irrigasim/views/irrigation/sulcos/widgets/terrain_view.dart';
import 'package:irrigasim/views/irrigation/widgets/auditable_widgets.dart';
import 'package:irrigasim/views/irrigation/widgets/irrigation_project_components.dart';

import 'border_charts.dart';

import 'package:irrigasim/viewmodels/faixas/border_project_controller.dart';
import 'package:irrigasim/viewmodels/results_controller.dart';

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

class BorderResultsScreen extends ConsumerWidget {
  const BorderResultsScreen({
    super.key,
    this.projectOverride,
    this.resultOverride,
  });
  final BorderProject? projectOverride;
  final SimulationResult? resultOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = resultOverride ?? ref.watch(borderProjectResultProvider);
    final BorderProject project =
        projectOverride ?? ref.watch(borderProjectProvider);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (result?.borderResult == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultado de faixa')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.balancoHidrico,
                    size: 48,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum cálculo de faixa disponível',
                    style: text.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Volte ao projeto para revisar os dados e calcular a irrigação.',
                    style: text.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(AppIcons.etapasAnteriores),
                    label: const Text('Voltar ao projeto'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final r = result!.borderResult!;
    final geo = const BorderPlanning().geometry(project, r);
    final alternatives = projectOverride == null
        ? ref.watch(borderAlternativesProvider)
        : null;
    final selectedAlternative = projectOverride == null
        ? ref.watch(borderSelectedAlternativeProvider)
        : null;
    final chartOperation = _operationForCharts(project, r: r);
    final buscando = ref.watch(borderAlternativesLoadingProvider);
    final scenarioComparison = ref.watch(borderScenarioComparisonProvider);
    final scenarioProfiles = scenarioComparison == null
        ? null
        : [
            (
              'Primeira irrigação',
              scenarioComparison.primeira,
              project.copyWith(
                cenarioInfiltracao: CenarioInfiltracaoFaixa.primeira,
                k: project.dadosPrimeira!.k,
                a: project.dadosPrimeira!.a,
                vibMMin: project.dadosPrimeira!.vibMMin,
              ),
            ),
            (
              'Terceira irrigação',
              scenarioComparison.terceira,
              project.copyWith(
                cenarioInfiltracao: CenarioInfiltracaoFaixa.terceira,
                k: project.dadosTerceira!.k,
                a: project.dadosTerceira!.a,
                vibMMin: project.dadosTerceira!.vibMMin,
              ),
            ),
          ];
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
    String f(double? v) => v == null ? '—' : v.toStringAsFixed(2);
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
    final save = ref.watch(resultsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado de faixa'),
        actions: [
          IconButton(
            tooltip: 'Exportar CSV',
            onPressed: () => _mostrarExportacao(
              context,
              borderCsv(
                project.copyWith(
                  alternativas: alternatives?.toRecords(
                    selected: selectedAlternative,
                  ),
                ),
                r,
              ),
            ),
            icon: const Icon(AppIcons.exportarDados),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BorderRecommendation(
                    status: r.status,
                    project: project,
                    result: r,
                  ),
                  const SizedBox(height: IrrigationSpacing.major),
                  BorderCharts(
                    result: r,
                    irnMm: project.irnEfetivaMm!,
                    project: project,
                    alternatives: alternatives,
                    operation: chartOperation,
                    scenarioProfiles: scenarioProfiles,
                    selectedIndex: save.abaAtual,
                    onTabSelected: ref.read(resultsProvider.notifier).setAba,
                  ),
                  const SizedBox(height: IrrigationSpacing.major),
                  TerrainView(
                    comprimentoM:
                        project.comprimentoAreaM ?? project.comprimentoM!,
                    larguraM: project.larguraAreaM ?? project.larguraM!,
                    espacamentoSulcosM: project.larguraM!,
                    declividadePercentual:
                        (project.declividadeLongitudinal ?? 0) * 100,
                    distributionName: 'faixas',
                  ),
                  const SizedBox(height: IrrigationSpacing.major),
                  section('Indicadores principais', [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 720
                            ? 3
                            : constraints.maxWidth >= 480
                            ? 2
                            : 1;
                        final width =
                            (constraints.maxWidth - (columns - 1) * 12) /
                            columns;
                        final values = [
                          (
                            'Eficiência Ea',
                            '${f(r.ea)}%',
                            'Água aplicada aproveitada',
                          ),
                          (
                            'Eficiência Er',
                            '${f(r.er)}%',
                            'Atendimento da IRN',
                          ),
                          ('Percolação Pp', '${f(r.pp)}%', 'Perda profunda'),
                          ('Escoamento Pe', '${f(r.pe)}%', 'Perda superficial'),
                          (
                            'Volume aplicado',
                            '${f(r.volumeEntradaTotalM3)} m³',
                            'Volume total na faixa',
                          ),
                          (
                            'Volume percolado',
                            '${f(r.volumePercoladoTotalM3)} m³',
                            'Perda profunda total',
                          ),
                          (
                            'Volume escoado',
                            '${f(r.volumeEscoadoTotalM3)} m³',
                            'Perda superficial total',
                          ),
                          (
                            'Tempo de avanço',
                            '${f(r.taFinalMin)} min',
                            'Até o final da faixa',
                          ),
                          (
                            'Oportunidade alvo',
                            '${f(r.t0Min)} min',
                            'Tempo requerido pela IRN',
                          ),
                          (
                            'Tempo de corte',
                            '${f(r.tiMin)} min',
                            'Interrupção da aplicação',
                          ),
                          (
                            'Lâmina útil média',
                            '${f(r.volumeUtilM3M / project.comprimentoM! * 1000)} mm',
                            'Infiltrada e limitada à IRN',
                          ),
                          (
                            'Comprimento atendido Xa',
                            '${f(r.comprimentoAdequadoM)} m',
                            'Pode conter trechos separados',
                          ),
                        ];
                        return Wrap(
                          spacing: IrrigationSpacing.field,
                          runSpacing: IrrigationSpacing.field,
                          children: [
                            for (final item in values)
                              SizedBox(
                                width: width,
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.$1, style: text.labelMedium),
                                        const SizedBox(height: 6),
                                        Text(
                                          item.$2,
                                          style: text.headlineSmall?.copyWith(
                                            color: colors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(item.$3, style: text.bodySmall),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
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
                              (p.xM / project.comprimentoM! * 400).round() %
                                  40 ==
                              0,
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
                    for (final fonte
                        in BorderResult.provenienciaHidraulicaExecutada)
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
                            final op = const BorderPlanning().operation(
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
                                for (final item in op.agenda)
                                  row('Horário', item),
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
                  if (project.comprimentoAreaM != null &&
                      project.larguraAreaM != null) ...[
                    OutlinedButton.icon(
                      onPressed: buscando
                          ? null
                          : () async {
                              ref
                                      .read(
                                        borderAlternativesLoadingProvider
                                            .notifier,
                                      )
                                      .state =
                                  true;
                              final qAtual = project.vazaoUnitariaLsM!;
                              final menor = TextEditingController(
                                text: (qAtual * .75).toStringAsFixed(2),
                              );
                              final maior = TextEditingController(
                                text: (qAtual * 1.25).toStringAsFixed(2),
                              );
                              final passo = TextEditingController(text: '0.05');
                              var objetivo = 'Ea';
                              final grade = await showDialog<(double, double, double, String)>(
                                context: context,
                                builder: (dialogContext) => StatefulBuilder(
                                  builder: (dialogContext, setDialogState) => AlertDialog(
                                    title: const Text('Configurar comparação'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: menor,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: const InputDecoration(
                                            labelText: 'q0 mínimo (L/s/m)',
                                          ),
                                        ),
                                        TextField(
                                          controller: maior,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: const InputDecoration(
                                            labelText: 'q0 máximo (L/s/m)',
                                          ),
                                        ),
                                        TextField(
                                          controller: passo,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: const InputDecoration(
                                            labelText: 'Passo da grade (L/s/m)',
                                          ),
                                        ),
                                        DropdownButtonFormField<String>(
                                          initialValue: objetivo,
                                          decoration: const InputDecoration(
                                            labelText: 'Objetivo da busca',
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'Ea',
                                              child: Text('Maximizar Ea'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Er',
                                              child: Text('Maximizar Er'),
                                            ),
                                          ],
                                          onChanged: (value) => setDialogState(
                                            () => objetivo = value ?? 'Ea',
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext),
                                        child: const Text('Cancelar'),
                                      ),
                                      FilledButton(
                                        onPressed: () {
                                          double? parse(String text) =>
                                              double.tryParse(
                                                text.replaceAll(',', '.'),
                                              );
                                          final values = (
                                            parse(menor.text),
                                            parse(maior.text),
                                            parse(passo.text),
                                          );
                                          if (values.$1 == null ||
                                              values.$2 == null ||
                                              values.$3 == null ||
                                              values.$1! <= 0 ||
                                              values.$2! < values.$1! ||
                                              values.$3! <= 0) {
                                            return;
                                          }
                                          Navigator.pop(dialogContext, (
                                            values.$1!,
                                            values.$2!,
                                            values.$3!,
                                            objetivo,
                                          ));
                                        },
                                        child: const Text('Comparar'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                              menor.dispose();
                              maior.dispose();
                              passo.dispose();
                              if (grade == null) return;
                              try {
                                final found = await buscarAlternativas(
                                  project,
                                  menorLsM: grade.$1,
                                  maiorLsM: grade.$2,
                                  passoLsM: grade.$3,
                                  objetivo: grade.$4,
                                );
                                if (context.mounted) {
                                  ref
                                          .read(
                                            borderAlternativesProvider.notifier,
                                          )
                                          .state =
                                      found;
                                }
                              } on FormatException catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.message)),
                                  );
                                }
                              } finally {
                                if (context.mounted) {
                                  ref
                                          .read(
                                            borderAlternativesLoadingProvider
                                                .notifier,
                                          )
                                          .state =
                                      false;
                                }
                              }
                            },
                      icon: buscando
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(AppIcons.recomendacao),
                      label: Text(
                        buscando
                            ? 'Avaliando alternativas…'
                            : 'Configurar comparação de vazões',
                      ),
                    ),
                    if (alternatives != null)
                      section('Alternativas testadas', [
                        row(
                          'Melhor entre candidatas viáveis',
                          (selectedAlternative ?? alternatives.melhor) == null
                              ? 'Nenhuma'
                              : 'Melhor na grade por ${alternatives.objetivo} · L=${f((selectedAlternative ?? alternatives.melhor)!.comprimentoM)} m · q0=${f((selectedAlternative ?? alternatives.melhor)!.vazaoLsM)} L/s/m · Ea=${f((selectedAlternative ?? alternatives.melhor)!.resultado!.ea)}% · Er=${f((selectedAlternative ?? alternatives.melhor)!.resultado!.er)}%',
                        ),
                        for (final c in alternatives.candidatos)
                          Semantics(
                            button: true,
                            label:
                                'Selecionar alternativa L ${f(c.comprimentoM)} metros, q0 ${f(c.vazaoLsM)} litros por segundo por metro',
                            child: InkWell(
                              onTap: c.resultado == null
                                  ? null
                                  : () =>
                                        ref
                                                .read(
                                                  borderSelectedAlternativeProvider
                                                      .notifier,
                                                )
                                                .state =
                                            c,
                              child: row(
                                'L=${f(c.comprimentoM)} m · q0=${f(c.vazaoLsM)} L/s/m${identical(c, selectedAlternative ?? alternatives.melhor) ? ' · selecionada' : ''}',
                                c.motivoRejeicao == null
                                    ? 'Ea=${f(c.resultado!.ea)}% · Er=${f(c.resultado!.er)}% · Pp=${f(c.resultado!.pp)}% · Pe=${f(c.resultado!.pe)}% · demanda Q=${f(c.vazaoLsM * c.resultado!.larguraM)} L/s'
                                    : '[${c.status?.codigo ?? BorderStatus.entradaInvalida.codigo}] ${c.motivoRejeicao} · Qfaixa=${f(c.vazaoLsM * c.larguraM)} L/s',
                              ),
                            ),
                          ),
                        row(
                          'Grade e critério',
                          'q0 ${f(alternatives.menorLsM)}–${f(alternatives.maiorLsM)} L/s/m · passo ${f(alternatives.passoLsM)} · maximizar ${alternatives.objetivo}',
                        ),
                      ]),
                    if (alternatives == null && project.alternativas.isNotEmpty)
                      section('Alternativas salvas', [
                        for (final c in project.alternativas)
                          row(
                            'L=${f(c.comprimentoM)} m · q0=${f(c.vazaoLsM)} L/s/m',
                            c.motivoRejeicao == null
                                ? 'Ea=${f(c.eficienciaPercentual!)}% · Er=${f(c.erPercentual ?? 0)}% · Pp=${f(c.ppPercentual ?? 0)}% · Pe=${f(c.pePercentual ?? 0)}% · Q=${f(c.demandaLs ?? 0)} L/s${c.selecionada ? ' · selecionada' : ''} · objetivo ${c.objetivo ?? 'Ea'}'
                                : '[${c.status?.codigo ?? BorderStatus.entradaInvalida.codigo}] ${c.motivoRejeicao}',
                          ),
                      ]),
                  ],
                  if (project.dadosPrimeira != null ||
                      project.dadosTerceira != null)
                    section('Comparar cenários de infiltração', [
                      row(
                        'Primeira irrigação · k, a, VIB',
                        '${f(project.dadosPrimeira?.k ?? (project.cenarioInfiltracao == CenarioInfiltracaoFaixa.primeira ? project.k : null))} · ${f(project.dadosPrimeira?.a ?? (project.cenarioInfiltracao == CenarioInfiltracaoFaixa.primeira ? project.a : null))} · ${f(project.dadosPrimeira?.vibMMin ?? (project.cenarioInfiltracao == CenarioInfiltracaoFaixa.primeira ? project.vibMMin : null))}',
                      ),
                      row(
                        'Terceira irrigação · k, a, VIB',
                        '${f(project.dadosTerceira?.k ?? (project.cenarioInfiltracao == CenarioInfiltracaoFaixa.terceira ? project.k : null))} · ${f(project.dadosTerceira?.a ?? (project.cenarioInfiltracao == CenarioInfiltracaoFaixa.terceira ? project.a : null))} · ${f(project.dadosTerceira?.vibMMin ?? (project.cenarioInfiltracao == CenarioInfiltracaoFaixa.terceira ? project.vibMMin : null))}',
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          try {
                            ref
                                .read(borderScenarioComparisonProvider.notifier)
                                .state = calcularComparacaoCenarios(
                              project,
                            );
                          } on FormatException catch (error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.message)),
                            );
                          }
                        },
                        icon: const Icon(AppIcons.comparar),
                        label: const Text('Calcular em paralelo'),
                      ),
                      if (scenarioComparison case final comparison?) ...[
                        row(
                          'Primeira · Ea / Er / Pp / Pe',
                          '${f(comparison.primeira.ea)}% · ${f(comparison.primeira.er)}% · ${f(comparison.primeira.pp)}% · ${f(comparison.primeira.pe)}%',
                        ),
                        row(
                          'Terceira · Ea / Er / Pp / Pe',
                          '${f(comparison.terceira.ea)}% · ${f(comparison.terceira.er)}% · ${f(comparison.terceira.pp)}% · ${f(comparison.terceira.pe)}%',
                        ),
                        row(
                          'Premissas mantidas',
                          'Mesma geometria, q0, IRN e rugosidade; cada cenário usa seus próprios k, a e VIB.',
                        ),
                      ],
                    ]),
                  section('Salvar este projeto', [
                    TextField(
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Nome do cenário',
                        hintText:
                            'Faixa · ${project.comprimentoM!.toStringAsFixed(0)} m · ${project.vazaoUnitariaLsM!.toStringAsFixed(2)} L/s/m',
                      ),
                      onChanged: ref
                          .read(resultsProvider.notifier)
                          .setNomeCenario,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed:
                          save.salvando || save.nomeCenario.trim().isEmpty
                          ? null
                          : () async {
                              await ref
                                  .read(resultsProvider.notifier)
                                  .salvarCenario(
                                    metodo: MetodoIrrigacao.faixa,
                                    parametros: project
                                        .copyWith(
                                          alternativas: alternatives?.toRecords(
                                            selected: selectedAlternative,
                                          ),
                                        )
                                        .toCompatParameters(),
                                    resultado: result,
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ref.read(resultsProvider).erro ??
                                          'Cenário salvo.',
                                    ),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(AppIcons.salvarCenario),
                      label: Text(
                        save.salvando ? 'Salvando…' : 'Salvar cenário',
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BorderOperation? _operationForCharts(
  BorderProject project, {
  required BorderResult r,
}) {
  if (project.periodoDias == null ||
      project.jornadaHoras == null ||
      project.mudancaMin == null ||
      project.faixasSimultaneas == null ||
      project.janelaFornecimentoHorasDia == null ||
      project.inicioFornecimentoH == null ||
      project.diasFornecimento.isEmpty) {
    return null;
  }
  try {
    return const BorderPlanning().operation(
      project,
      r,
      dias: project.periodoDias!,
      jornadaHoras: project.jornadaHoras!,
      mudancaMin: project.mudancaMin!,
      simultaneas: project.faixasSimultaneas!,
      janelaFornecimentoHorasDia: project.janelaFornecimentoHorasDia!,
    );
  } on FormatException {
    return null;
  }
}

class _BorderRecommendation extends StatelessWidget {
  const _BorderRecommendation({
    required this.status,
    required this.project,
    required this.result,
  });

  final BorderStatus status;
  final BorderProject project;
  final BorderResult result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final blocked = status.bloqueia;
    final advisory = status == BorderStatus.avisoOrientativo;
    final background = blocked
        ? colors.errorContainer
        : advisory
        ? colors.tertiaryContainer
        : colors.primaryContainer;
    final foreground = blocked
        ? colors.onErrorContainer
        : advisory
        ? colors.onTertiaryContainer
        : colors.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconeStatusBorder(status), color: foreground, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blocked
                      ? 'Revise as ressalvas do modelo'
                      : advisory
                      ? 'Resultado com recomendações orientativas'
                      : 'Simulação concluída',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Faixa aberta de ${project.comprimentoM!.toStringAsFixed(0)} m · '
                  'q0 = ${project.vazaoUnitariaLsM!.toStringAsFixed(2)} L/s/m · '
                  'Ea = ${result.ea.toStringAsFixed(1)}% · '
                  'Er = ${result.er.toStringAsFixed(1)}%.\n'
                  '${textoStatusBorder(status)}',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _mostrarExportacao(BuildContext context, String csv) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Prévia do CSV da faixa',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .5,
              ),
              child: SingleChildScrollView(child: SelectableText(csv)),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: csv));
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(AppIcons.exportarDados),
              label: const Text('Copiar CSV'),
            ),
          ],
        ),
      ),
    ),
  );
}
