import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/models/faixas/border_result.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/models/simulation_result.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/services/simulation/faixas/border_planning.dart';
import 'package:irrigasim/services/simulation/faixas/border_hydraulics.dart';
import 'package:irrigasim/services/simulation/faixas/border_csv.dart';
import 'package:irrigasim/views/irrigation/sulcos/widgets/terrain_view.dart';
import 'package:irrigasim/views/irrigation/widgets/auditable_widgets.dart';

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
    final buscando = ref.watch(borderAlternativesLoadingProvider);
    Widget row(
      String label,
      String value, {
      String? detail,
      bool warning = false,
    }) => IrrigationAuditRow(label, value, detail: detail, isWarning: warning);
    Widget section(String title, List<Widget> children) =>
        IrrigationAuditSection(
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
          children: children,
        );
    String f(double v) => v.toStringAsFixed(2);
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
                project.copyWith(alternativas: alternatives?.toRecords()),
                r,
              ),
            ),
            icon: const Icon(AppIcons.exportarDados),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BorderRecommendation(
                    status: r.status,
                    project: project,
                    result: r,
                  ),
                  const SizedBox(height: 20),
                  BorderCharts(
                    result: r,
                    irnMm: project.irnEfetivaMm!,
                    selectedIndex: save.abaAtual,
                    onTabSelected: ref.read(resultsProvider.notifier).setAba,
                  ),
                  const SizedBox(height: 20),
                  TerrainView(
                    comprimentoM:
                        project.comprimentoAreaM ?? project.comprimentoM!,
                    larguraM: project.larguraAreaM ?? project.larguraM!,
                    espacamentoSulcosM: project.larguraM!,
                    declividadePercentual:
                        (project.declividadeLongitudinal ?? 0) * 100,
                    distributionName: 'faixas',
                  ),
                  const SizedBox(height: 20),
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
                            'Tempo de avanço',
                            '${f(r.taFinalMin)} min',
                            'Até o final da faixa',
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
                          spacing: 12,
                          runSpacing: 12,
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
                    row('q0', '${f(project.vazaoUnitariaLsM!)} L/s/m'),
                    row('Qfaixa', '${f(project.vazaoFaixaLs!)} L/s'),
                    row(
                      'IRN (${project.origemIrn.name})',
                      '${f(project.irnEfetivaMm!)} mm',
                    ),
                    row(
                      'Cenário de infiltração',
                      project.cenarioInfiltracao.name,
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
                      'y0 · r · σz · qf',
                      '${f(r.y0M)} m · ${f(r.r)} · ${f(r.sigmaZ)} · ${f(r.qfM3MinM)} m³/min/m',
                    ),
                  ]),
                  section('Fórmulas e critérios', [
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
                  ]),
                  section('Perfil e balanço', [
                    row(
                      'Entrada · útil',
                      '${f(r.volumeEntradaTotalM3)} · ${f(r.volumeUtilTotalM3)} m³',
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
                      'Volume deficitário Vd',
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
                    row(
                      'Dmáx = 0,4 hn',
                      geo.limiteDesnivelM == null
                          ? 'Pendente: hn não informada'
                          : '${f(geo.limiteDesnivelM!)} m',
                    ),
                    row(
                      'Wmáx',
                      geo.limiteDesnivelM == null
                          ? 'Pendente'
                          : geo.larguraMaximaM == null
                          ? 'Sem restrição por St = 0'
                          : '${f(geo.larguraMaximaM!)} m',
                    ),
                    row(
                      'Altura real do dique',
                      geo.diqueSuficiente == null
                          ? 'Pendente'
                          : geo.diqueSuficiente!
                          ? 'Suficiente para y0'
                          : 'Insuficiente para y0',
                    ),
                    row(
                      'Resíduo F07 · F09 · F19',
                      '${r.residualOportunidadeM.toStringAsExponential(2)} m · ${r.residualAvancoM3M.toStringAsExponential(2)} m³/m · ${r.residualRecessaoMin.toStringAsExponential(2)} min',
                    ),
                    row(
                      'qmin F03 (sugestão)',
                      '${f(BorderHydraulics.vazaoMinimaM3MinM(project.comprimentoM!, project.declividadeLongitudinal!, project.rugosidadeN!) / .06)} L/s/m',
                    ),
                    row(
                      'Hart F01 (literal, unidade empírica não confirmada)',
                      '${f(BorderHydraulics.hartLiteral(project.declividadeLongitudinal!, coberturaTotal: project.cobertura == CoberturaFaixa.coberturaTotal))} m³/min/m conforme leitura do slide',
                    ),
                    row(
                      'F04 · L ≤ qmax/VIB',
                      project.vibMMin! == 0
                          ? 'Sem restrição por VIB = 0 neste critério'
                          : 'Se qmax for Hart literal: L ≤ ${f(BorderHydraulics.hartLiteral(project.declividadeLongitudinal!, coberturaTotal: project.cobertura == CoberturaFaixa.coberturaTotal) / project.vibMMin!)} m (não usado para aprovação)',
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
                    if (r.avisos.isEmpty) const Text('Sem avisos do modelo.'),
                    for (final notice in r.avisos)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: IrrigationAlertBanner(
                          message:
                              '[${notice.codigo}] ${notice.mensagem}'
                              '${notice.pagina == null ? '' : ' (${notice.pagina})'}',
                        ),
                      ),
                    for (final bloco in BorderResult.blocosFonte.entries)
                      row(bloco.key, bloco.value),
                    for (final fonte in BorderResult.proveniencia)
                      row(
                        '${fonte.id} · ${fonte.pagina}',
                        '${fonte.descricao} · ${fonte.versao} · origem ${fonte.origem.name}',
                      ),
                    if (project.periodoDias == null ||
                        project.jornadaHoras == null ||
                        project.mudancaMin == null ||
                        project.faixasSimultaneas == null ||
                        project.janelaFornecimentoHorasDia == null ||
                        project.inicioFornecimentoH == null ||
                        project.diasFornecimento.isEmpty)
                      const Text(
                        'Cronograma pendente: informe PI, TDF, tmu, NFP, início, duração e dias reais de fornecimento.',
                      )
                    else
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
                              try {
                                final found = await buscarAlternativas(project);
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
                            : 'Comparar vazões (passo 0,05 L/s/m)',
                      ),
                    ),
                    if (alternatives != null)
                      section('Alternativas testadas', [
                        row(
                          'Melhor entre candidatas viáveis',
                          alternatives.melhor == null
                              ? 'Nenhuma'
                              : 'L=${f(alternatives.melhor!.comprimentoM)} m · q0=${f(alternatives.melhor!.vazaoLsM)} L/s/m · Ea=${f(alternatives.melhor!.resultado!.ea)}%',
                        ),
                        for (final c in alternatives.candidatos)
                          row(
                            'L=${f(c.comprimentoM)} m · q0=${f(c.vazaoLsM)} L/s/m',
                            c.motivoRejeicao == null
                                ? 'Ea=${f(c.resultado!.ea)}%'
                                : '[${c.status?.codigo ?? BorderStatus.entradaInvalida.codigo}] ${c.motivoRejeicao}',
                          ),
                      ]),
                    if (alternatives == null && project.alternativas.isNotEmpty)
                      section('Alternativas salvas', [
                        for (final c in project.alternativas)
                          row(
                            'L=${f(c.comprimentoM)} m · q0=${f(c.vazaoLsM)} L/s/m',
                            c.motivoRejeicao == null
                                ? 'Ea=${f(c.eficienciaPercentual!)}%'
                                : '[${c.status?.codigo ?? BorderStatus.entradaInvalida.codigo}] ${c.motivoRejeicao}',
                          ),
                      ]),
                  ],
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
                                          alternativas: alternatives
                                              ?.toRecords(),
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
