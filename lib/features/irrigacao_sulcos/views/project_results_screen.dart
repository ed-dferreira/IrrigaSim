import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/features/irrigacao_sulcos/services/csv_sulco.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_chart_section.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_export.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_states.dart';
import 'package:irrigasim/core/widgets/loading_widget.dart';
import 'package:irrigasim/features/cenarios/controllers/salvar_cenario_controller.dart';
import 'package:irrigasim/features/irrigacao_sulcos/views/project_results/project_results_sections.dart';
import 'package:irrigasim/features/irrigacao_sulcos/views/project_results/project_results_widgets.dart';
import 'package:irrigasim/features/irrigacao_sulcos/views/project_results/save_card.dart';
import 'package:irrigasim/shared/irrigacao/widgets/terrain/terrain_view.dart';

/// Tela de resultados do projeto de sulcos: orquestra banner, gráficos,
/// seções auditáveis, exportação CSV e salvamento de cenário.
class ProjectResultsScreen extends ConsumerWidget {
  const ProjectResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provedorParametrosSulco);
    final result = state.resultado;
    if (state.executando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultados do projeto')),
        body: const LoadingWidget(message: 'Calculando resultados…'),
      );
    }
    if (result == null) {
      final error = state.erro;
      if (error == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Resultados do projeto')),
          body: IrrigationEmptyResult(
            icon: AppIcons.projetoRevisao,
            title: 'Execute o dimensionamento primeiro.',
            message:
                'Volte ao projeto para revisar os dados e calcular a irrigação.',
            actionLabel: 'Voltar ao projeto',
            onAction: () => Navigator.of(context).maybePop(),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Resultados do projeto')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppIcons.atencao,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Não foi possível calcular os resultados.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final resultsState = ref.watch(resultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados do projeto'),
        actions: [
          IconButton(
            tooltip: 'Exportar dados',
            onPressed: () => _showExport(context, state, result),
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
                  RecommendationBanner(state: state, result: result),
                  const SizedBox(height: 20),
                  IrrigationChartSection(
                    title: 'Gráficos',
                    tabs: sulcoChartTabs,
                    selectedIndex: resultsState.abaAtual.clamp(0, 6),
                    onTabSelected: ref.read(resultsProvider.notifier).setAba,
                    children: sulcoChartChildren(result),
                  ),
                  const SizedBox(height: 20),
                  TerrainView(
                    comprimentoM: state.comprimento,
                    larguraM: state.larguraOuEspacamento * 10,
                    espacamentoSulcosM: state.larguraOuEspacamento,
                    declividadePercentual: state.declividade * 100,
                    tipoSulco: state.tipoSulco,
                  ),
                  const SizedBox(height: 20),
                  KpiGrid(result: result),
                  const SizedBox(height: 20),
                  ...secoesAuditoriaSulco(state, result),
                  const SizedBox(height: 16),
                  SaveCard(
                    state: state,
                    saving: ref.watch(resultsProvider).salvando,
                    onNameChanged: ref.read(resultsProvider.notifier)
                        .setNomeCenario,
                    onSave: () =>
                        _saveScenario(context, ref, state, result),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExport(
    BuildContext context,
    EstadoParametrosSulco state,
    SimulationResult result,
  ) {
    showIrrigationExportSheet(
      context,
      title: 'Exportar dados em CSV',
      description:
          'O conteúdo inclui entradas, indicadores e séries dos gráficos.',
      csv: csvSulco(state, result),
    );
  }

  Future<void> _saveScenario(
    BuildContext context,
    WidgetRef ref,
    EstadoParametrosSulco state,
    SimulationResult result,
  ) async {
    final notifier = ref.read(resultsProvider.notifier);
    if (ref.read(resultsProvider).nomeCenario.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um nome para o cenário.')),
      );
      return;
    }
    await notifier.salvarCenario(
      metodo: MetodoIrrigacao.sulco,
      parametros: state.paraParametrosIrrigacao(),
      resultado: result,
    );
    if (!context.mounted) return;
    final error = ref.read(resultsProvider).erro;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Cenário salvo com sucesso!')),
    );
  }
}
