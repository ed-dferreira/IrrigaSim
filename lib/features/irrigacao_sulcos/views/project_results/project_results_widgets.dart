import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';
import 'package:irrigasim/shared/cenarios/providers/scenario_providers.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/advance_chart.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/infiltration_chart.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/water_balance_chart.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/opportunity_time_chart.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/performance_bars_chart.dart';
import 'package:irrigasim/features/irrigacao_sulcos/views/widgets/depth_along_furrow_chart.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/scenario_comparison_chart.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';

// ──────────────────────── Recommendation Banner ────────────────────────

class RecommendationBanner extends StatelessWidget {
  const RecommendationBanner({
    super.key,
    required this.state,
    required this.result,
  });
  final EstadoParametrosSulco state;
  final SimulationResult result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final good =
        result.alertaVazaoExcedida == null &&
        (result.balancoSulco?.eficienciaAplicacaoIntegralPercentual ??
                result.eficiencia) >=
            85 &&
        result.cuc >= 80 &&
        result.du >= 65;

    final title = good ? 'Desempenho satisfatório' : 'Otimização recomendada';
    final message =
        result.alertaVazaoExcedida ??
        (good
            ? 'O dimensionamento atende a bons critérios de eficiência e uniformidade.'
            : 'Revise os parâmetros para melhorar o desempenho.');
    final background = good
        ? colors.primaryContainer
        : colors.tertiaryContainer;
    final foreground = good
        ? colors.onPrimaryContainer
        : colors.onTertiaryContainer;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            good ? AppIcons.sucesso : AppIcons.atencao,
            color: foreground,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sulco: L = ${state.comprimento.toStringAsFixed(0)} m, '
                  'Q = ${state.vazao.toStringAsFixed(2)} L/s por ${(result.tempoFornecimentoMin ?? state.tempoAplicacao).toStringAsFixed(0)} min. '
                  '${result.balancoSulco == null ? 'Ea' : 'Ea integral'} = ${(result.balancoSulco?.eficienciaAplicacaoIntegralPercentual ?? result.eficiencia).toStringAsFixed(1)}%, CUC = ${result.cuc.toStringAsFixed(1)}%.\n$message',
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

// ──────────────────────── KPI Grid ────────────────────────

class KpiGrid extends StatelessWidget {
  const KpiGrid({super.key, required this.result});
  final SimulationResult result;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        result.balancoSulco == null ? 'Eficiência Ea' : 'Ea integral',
        '${(result.balancoSulco?.eficienciaAplicacaoIntegralPercentual ?? result.eficiencia).toStringAsFixed(1)}%',
        result.classificacaoEaIntegral,
      ),
      (
        'Uniformidade CUC',
        '${result.cuc.toStringAsFixed(1)}%',
        result.classificacaoCuc,
      ),
      (
        'Distribuição DU',
        '${result.du.toStringAsFixed(1)}%',
        result.classificacaoDu,
      ),
      (
        'Lâmina média',
        '${(result.laminaMedia * 1000).toStringAsFixed(1)} mm',
        'Infiltrada (Lmi)',
      ),
      (
        'Tempo de avanço',
        '${result.tempoAvanco.toStringAsFixed(0)} min',
        'Até o final',
      ),
      (
        'Er',
        '${result.eficienciaRequerimento.toStringAsFixed(1)}%',
        'Eficiência de requerimento',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 3 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$1,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.$2,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.$3,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

// ──────────────────────── Auditable Section ────────────────────────

class AuditableSection extends StatelessWidget {
  const AuditableSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IrrigationAuditSection(title: title, icon: icon, children: children);
  }
}

class AuditRow extends StatelessWidget {
  const AuditRow(
    this.label,
    this.value, {
    super.key,
    this.detail,
    this.isWarning = false,
  });
  final String label;
  final String value;
  final String? detail;
  final bool isWarning;

  @override
  Widget build(BuildContext context) =>
      IrrigationAuditRow(label, value, detail: detail, isWarning: isWarning);
}

// ──────────────────────── Formula Card ────────────────────────

class FormulaCard extends StatelessWidget {
  const FormulaCard({
    super.key,
    required this.formula,
    required this.description,
  });
  final String formula;
  final String description;

  @override
  Widget build(BuildContext context) =>
      IrrigationFormulaCard(formula: formula, description: description);
}

// ──────────────────────── Alert Banner ────────────────────────

class AlertBanner extends StatelessWidget {
  const AlertBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => IrrigationAlertBanner(message: message);
}

// ──────────────────────── Chart Section ────────────────────────

class ChartSection extends StatelessWidget {
  const ChartSection({
    super.key,
    required this.title,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.result,
  });
  final String title;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final SimulationResult result;

  static const _chartLabels = [
    'Balanço',
    'Avanço',
    'Infiltração',
    'Oportunidade',
    'Desempenho',
    'Lâmina',
    'Comparação',
  ];

  static const _chartIcons = [
    AppIcons.balancoHidrico,
    AppIcons.curvaAvanco,
    AppIcons.perfilInfiltracao,
    AppIcons.oportunidade,
    AppIcons.indicadores,
    AppIcons.lamina,
    AppIcons.comparar,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final clampedIndex = selectedIndex.clamp(0, _chartLabels.length - 1);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(AppIcons.chart, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _chartLabels.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = index == clampedIndex;
                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label: _chartLabels[index],
                    child: InkWell(
                      onTap: () => onTabSelected(index),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primaryContainer
                              : colors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? colors.primary
                                : colors.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _chartIcons[index],
                              size: 18,
                              color: isSelected
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _chartLabels[index],
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: isSelected
                                        ? colors.primary
                                        : colors.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 340,
              child: IndexedStack(
                index: clampedIndex,
                children: [
                  WaterBalanceChart(resultado: result),
                  AdvanceChart(resultado: result),
                  InfiltrationChart(resultado: result),
                  OpportunityTimeChart(resultado: result),
                  PerformanceBarsChart(resultado: result),
                  DepthAlongFurrowChart(resultado: result),
                  ScenarioComparison(resultadoAtual: result),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScenarioComparison extends ConsumerWidget {
  const ScenarioComparison({super.key, required this.resultadoAtual});

  final SimulationResult resultadoAtual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarios = ref.watch(cenariosProvider);
    return scenarios.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _comparisonMessage(
        context,
        'Não foi possível carregar os cenários salvos.',
      ),
      data: (items) {
        if (items.isEmpty) {
          return _comparisonMessage(
            context,
            'Salve outro cenário para compará-lo com este resultado.',
          );
        }
        final scenario = items.first;
        return ScenarioComparisonChart(
          resultadoA: resultadoAtual,
          resultadoB: scenario.resultado,
          labelA: 'Resultado atual',
          labelB: scenario.nome,
        );
      },
    );
  }

  Widget _comparisonMessage(BuildContext context, String message) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.comparar, size: 40, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
