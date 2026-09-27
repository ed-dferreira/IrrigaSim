import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/models/simulation_result.dart';

class PerformanceBarsChart extends StatelessWidget {
  const PerformanceBarsChart({super.key, required this.resultado});

  final SimulationResult resultado;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final items = [
      _Indicator('Eficiência Ea', resultado.eficiencia, resultado.classificacaoEa),
      _Indicator('Uniformidade CUC', resultado.cuc, resultado.classificacaoCuc),
      _Indicator('Distribuição DU', resultado.du, resultado.classificacaoDu),
      _Indicator('Adequação Er', resultado.eficienciaRequerimento, 'Adequação'),
    ];

    return Semantics(
      label:
          'Indicadores de desempenho. Eficiência ${resultado.eficiencia.toStringAsFixed(1)} por cento, CUC ${resultado.cuc.toStringAsFixed(1)} por cento, DU ${resultado.du.toStringAsFixed(1)} por cento.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Indicadores de desempenho',
            style: Theme.of(context).textTheme.bodySmall,
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
                        final item = items[groupIndex];
                        return BarTooltipItem(
                          '${item.label}: ${rod.toY.toStringAsFixed(1)}%\n${item.classificacao}',
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
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= items.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              items[idx].label.replaceAll('Eficiência ', '').replaceAll('Uniformidade ', '').replaceAll('Distribuição ', '').replaceAll('Adequação ', ''),
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
                    for (var i = 0; i < items.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: items[i].value.clamp(0, 100),
                            color: _indicatorColor(items[i].value, colors),
                            width: 32,
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ],
                      ),
                  ],
                ),
                duration: const Duration(milliseconds: 350),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: items
                .map(
                  (item) => _LegendItem(
                    color: _indicatorColor(item.value, colors),
                    label: '${item.label}: ${item.value.toStringAsFixed(1)}%',
                    sublabel: item.classificacao,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  static Color _indicatorColor(double value, ColorScheme colors) {
    if (value >= 80) return AppColors.success;
    if (value >= 65) return AppColors.good;
    if (value >= 50) return AppColors.regular;
    return AppColors.bad;
  }
}

class _Indicator {
  const _Indicator(this.label, this.value, this.classificacao);
  final String label;
  final double value;
  final String classificacao;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.sublabel,
  });
  final Color color;
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(width: 4),
        Text(
          '($sublabel)',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
