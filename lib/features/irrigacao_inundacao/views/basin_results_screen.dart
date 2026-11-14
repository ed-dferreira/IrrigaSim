// Tela de resultado do projeto de inundação (Fase 6). Espelha
// lib/views/irrigation/faixas/border_results_screen.dart: banner de status,
// gráficos genéricos, seções auditáveis, exportação CSV e salvamento de
// cenário, com anexos exclusivos do regime (planejamento em parcelas,
// seleção de vazão e volumes do arroz).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/core/theme/app_icons.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/projeto_inundacao.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/shared/irrigacao/models/validacao_superficie.dart';
import 'package:irrigasim/features/irrigacao_inundacao/viewmodels/basin_project_controller.dart';
import 'package:irrigasim/features/cenarios/controllers/salvar_cenario_controller.dart';
import 'package:irrigasim/shared/irrigacao/widgets/terrain/terrain_view.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_project_components.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_feedback.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_states.dart';

import 'basin_results/basin_results_charts.dart';
import 'basin_results/basin_results_kpis.dart';
import 'basin_results/basin_results_sections.dart';

class BasinResultsScreen extends ConsumerWidget {
  const BasinResultsScreen({
    super.key,
    this.projectOverride,
    this.resultOverride,
  });

  final ProjetoInundacao? projectOverride;
  final SimulationResult? resultOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = resultOverride ?? ref.watch(basinProjectResultProvider);
    final ProjetoInundacao project =
        projectOverride ?? ref.watch(basinProjectProvider);
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultado de inundação')),
        body: IrrigationEmptyResult(
          icon: AppIcons.inundacao,
          title: 'Nenhum cálculo de inundação disponível',
          message:
              'Volte ao projeto para revisar os dados e calcular a irrigação.',
          actionLabel: 'Voltar ao projeto',
          onAction: () => Navigator.of(context).maybePop(),
        ),
      );
    }
    final r = result;
    final status = project.impedimento?.status ?? BorderStatus.validoNoModelo;
    final save = ref.watch(resultsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado de inundação'),
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
                  _BasinRecommendation(
                    status: status,
                    project: project,
                    result: r,
                  ),
                  const SizedBox(height: IrrigationSpacing.major),
                  BasinCharts(result: r),
                  const SizedBox(height: IrrigationSpacing.major),
                  TerrainView(
                    comprimentoM:
                        project.comprimentoAreaM ?? project.comprimentoM ?? 0,
                    larguraM: project.larguraAreaM ?? project.larguraM ?? 0,
                    espacamentoSulcosM: project.larguraM ?? 1,
                    declividadePercentual: (project.declividade ?? 0) * 100,
                    distributionName: 'tabuleiros',
                  ),
                  const SizedBox(height: IrrigationSpacing.major),
                  BasinKpis(project: project, result: r),
                  ...secoesResultadoBasin(project: project, r: r),
                  IrrigationAuditSection(
                    title: 'Salvar este projeto',
                    icon: AppIcons.salvarCenario,
                    children: [
                      TextField(
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Nome do cenário',
                          hintText:
                              'Inundação · ${project.regime.displayName} · '
                              'Ea ${f(r.eficiencia, casas: 1)}%',
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
                                      metodo: MetodoIrrigacao.inundacao,
                                      parametros: project.toCompatParameters(),
                                      resultado: r,
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

class _BasinRecommendation extends StatelessWidget {
  const _BasinRecommendation({
    required this.status,
    required this.project,
    required this.result,
  });

  final BorderStatus status;
  final ProjetoInundacao project;
  final SimulationResult result;

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
          '${project.regime.displayName} · '
          'Ea = ${result.eficiencia.toStringAsFixed(1)}% · '
          'ta = ${result.tempoAvanco.toStringAsFixed(1)} min · '
          'Perfil com ${result.perfilLongitudinal.length} pontos.\n'
          '${textoStatusBasin(status)}',
      icon: iconeStatusBasin(status),
      tone: blocked
          ? IrrigationBannerTone.error
          : advisory
          ? IrrigationBannerTone.warning
          : IrrigationBannerTone.success,
      semanticsLabel: title,
    );
  }
}
