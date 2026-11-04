import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_resultado.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_projeto.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigacao_faixas/services/faixa_planejamento.dart';
import 'package:irrigasim/features/irrigacao_faixas/services/faixa_csv.dart';
import 'package:irrigasim/shared/irrigacao/widgets/terrain/terrain_view.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_project_components.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_feedback.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_export.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_states.dart';

import 'border_charts.dart';
import 'border_results/border_results_actions.dart';
import 'border_results/border_results_sections.dart';

// Ícones e textos de status continuam expostos por esta tela para os testes.
export 'border_results/border_results_sections.dart'
    show iconeStatusBorder, textoStatusBorder;

import 'package:irrigasim/features/irrigacao_faixas/viewmodels/border_project_controller.dart';
import 'package:irrigasim/features/cenarios/controllers/salvar_cenario_controller.dart';

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
    if (result?.borderResult == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultado de faixa')),
        body: IrrigationEmptyResult(
          icon: AppIcons.balancoHidrico,
          title: 'Nenhum cálculo de faixa disponível',
          message:
              'Volte ao projeto para revisar os dados e calcular a irrigação.',
          actionLabel: 'Voltar ao projeto',
          onAction: () => Navigator.of(context).maybePop(),
        ),
      );
    }
    final r = result!.borderResult!;
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
    final save = ref.watch(resultsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado de faixa'),
        actions: [
          IconButton(
            tooltip: 'Exportar CSV',
            onPressed: () => showIrrigationExportSheet(
              context,
              title: 'Prévia do CSV da faixa',
              description: '',
              csv: borderCsv(
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
                  ...secoesResultadoFaixa(
                    context: context,
                    project: project,
                    r: r,
                  ),
                  ...secoesAlternativasFaixa(
                    context: context,
                    ref: ref,
                    project: project,
                    alternatives: alternatives,
                    selectedAlternative: selectedAlternative,
                    buscando: buscando,
                  ),
                  ...secaoComparacaoCenariosFaixa(
                    context: context,
                    ref: ref,
                    project: project,
                    scenarioComparison: scenarioComparison,
                  ),
                  IrrigationAuditSection(
                    title: 'Salvar este projeto',
                    icon: AppIcons.salvarCenario,
                    children: [
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
                                            alternativas:
                                                alternatives?.toRecords(
                                                  selected:
                                                      selectedAlternative,
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
                    ],
                  ),
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
    return const BorderPlanning().operacao(
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
    final blocked = status.bloqueia;
    final advisory = status == BorderStatus.avisoOrientativo;
    final title = blocked
        ? 'Revise as ressalvas do modelo'
        : advisory
        ? 'Resultado com recomendações orientativas'
        : 'Simulação concluída';
    return IrrigationBanner(
      title: title,
      message:
          'Faixa aberta de ${project.comprimentoM!.toStringAsFixed(0)} m · '
          'q0 = ${project.vazaoUnitariaLsM!.toStringAsFixed(2)} L/s/m · '
          'Ea = ${result.ea.toStringAsFixed(1)}% · '
          'Er = ${result.er.toStringAsFixed(1)}%.\n'
          '${textoStatusBorder(status)}',
      icon: iconeStatusBorder(status),
      tone: blocked
          ? IrrigationBannerTone.error
          : advisory
          ? IrrigationBannerTone.warning
          : IrrigationBannerTone.success,
      semanticsLabel: title,
    );
  }
}
