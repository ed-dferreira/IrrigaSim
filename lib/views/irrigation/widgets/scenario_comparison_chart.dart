import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/models/simulation_result.dart';

class ScenarioComparisonChart extends StatelessWidget {
  const ScenarioComparisonChart({
    super.key,
    required this.resultadoA,
    required this.resultadoB,
    this.labelA = 'Cenário A',
    this.labelB = 'Cenário B',
  });

  final SimulationResult resultadoA;
  final SimulationResult resultadoB;
  final String labelA;
  final String labelB;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final indicators = ['Ea', 'CUC', 'DU', 'Er'];
    final valuesA = [
      resultadoA.eficiencia.clamp(0.0, 100.0).toDouble(),
      resultadoA.cuc.clamp(0.0, 100.0).toDouble(),
      resultadoA.du.clamp(0.0, 100.0).toDouble(),
      resultadoA.eficienciaRequerimento.clamp(0.0, 100.0).toDouble(),
    ];
    final valuesB = [
      resultadoB.eficiencia.clamp(0.0, 100.0).toDouble(),
      resultadoB.cuc.clamp(0.0, 100.0).toDouble(),
      resultadoB.du.clamp(0.0, 100.0).toDouble(),
      resultadoB.eficienciaRequerimento.clamp(0.0, 100.0).toDouble(),
    ];

    return Semantics(
      label:
          'Comparação de cenários em percentual. $labelA: Ea ${valuesA[0].toStringAsFixed(1)}, CUC ${valuesA[1].toStringAsFixed(1)}, DU ${valuesA[2].toStringAsFixed(1)}, Er ${valuesA[3].toStringAsFixed(1)}. $labelB: Ea ${valuesB[0].toStringAsFixed(1)}, CUC ${valuesB[1].toStringAsFixed(1)}, DU ${valuesB[2].toStringAsFixed(1)}, Er ${valuesB[3].toStringAsFixed(1)}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Comparação entre cenários',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _ScenarioBadge(label: labelA, color: colors.primary),
              _ScenarioBadge(label: labelB, color: colors.tertiary),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ExcludeSemantics(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  minY: 0,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => colors.inverseSurface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final name = rodIndex == 0 ? labelA : labelB;
                        return BarTooltipItem(
                          '$name\n${rod.toY.toStringAsFixed(1)}%',
                          TextStyle(color: colors.onInverseSurface),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= indicators.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              indicators[idx],
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text('%'),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 25,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '${value.toInt()}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: colors.outlineVariant, strokeWidth: 1),
                    getDrawingVerticalLine: (_) =>
                        FlLine(color: colors.outlineVariant, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  barGroups: [
                    for (var i = 0; i < indicators.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: valuesA[i],
                            color: colors.primary,
                            width: 14,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                          BarChartRodData(
                            toY: valuesB[i],
                            color: colors.tertiary,
                            width: 14,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 350),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ComparisonSummary(
            resultadoA: resultadoA,
            resultadoB: resultadoB,
            labelA: labelA,
            labelB: labelB,
          ),
        ],
      ),
    );
  }
}

class _ScenarioBadge extends StatelessWidget {
  const _ScenarioBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _ComparisonSummary extends StatelessWidget {
  const _ComparisonSummary({
    required this.resultadoA,
    required this.resultadoB,
    required this.labelA,
    required this.labelB,
  });
  final SimulationResult resultadoA;
  final SimulationResult resultadoB;
  final String labelA;
  final String labelB;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final eaDiff = resultadoB.eficiencia - resultadoA.eficiencia;
    final cucDiff = resultadoB.cuc - resultadoA.cuc;
    final duDiff = resultadoB.du - resultadoA.du;

    String formatDiff(double value) {
      final sign = value >= 0 ? '+' : '';
      return '$sign${value.toStringAsFixed(1)}%';
    }

    Color diffColor(double value) {
      if (value > 0) return AppColors.success;
      if (value < 0) return AppColors.bad;
      return colors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 8,
        children: [
          _DiffChip(
            label: 'ΔEa',
            value: formatDiff(eaDiff),
            color: diffColor(eaDiff),
          ),
          _DiffChip(
            label: 'ΔCUC',
            value: formatDiff(cucDiff),
            color: diffColor(cucDiff),
          ),
          _DiffChip(
            label: 'ΔDU',
            value: formatDiff(duDiff),
            color: diffColor(duDiff),
          ),
        ],
      ),
    );
  }
}

class _DiffChip extends StatelessWidget {
  const _DiffChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: Theme.of(context).textTheme.labelMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
