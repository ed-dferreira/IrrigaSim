import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:irrigasim/features/irrigation/models/simulation_result.dart';

class WaterBalanceChart extends StatelessWidget {
  const WaterBalanceChart({super.key, required this.resultado});

  final SimulationResult resultado;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final items = [
      (
        label: 'Aproveitado',
        value: resultado.eficiencia,
        color: colors.primary,
      ),
      (
        label: 'Percolação profunda',
        value: resultado.perdaPercolacao,
        color: colors.tertiary,
      ),
      (
        label: 'Escoamento superficial',
        value: resultado.perdaEscoamento,
        color: colors.error,
      ),
    ];
    final total = items.fold<double>(0, (sum, item) => sum + item.value);

    return Semantics(
      label:
          'Balanço hídrico. ${items.map((item) => '${item.label}: ${item.value.toStringAsFixed(1)} por cento').join(', ')}.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 460;
          final chart = SizedBox.square(
            dimension: compact ? 150 : 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: compact ? 46 : 56,
                    sectionsSpace: 2,
                    startDegreeOffset: -90,
                    sections: total <= 0
                        ? [
                            PieChartSectionData(
                              value: 1,
                              color: colors.surfaceContainerHighest,
                              radius: 24,
                              showTitle: false,
                            ),
                          ]
                        : items
                              .map(
                                (item) => PieChartSectionData(
                                  value: item.value.clamp(0, double.infinity),
                                  color: item.color,
                                  radius: 24,
                                  showTitle: false,
                                ),
                              )
                              .toList(),
                  ),
                  duration: const Duration(milliseconds: 350),
                ),
                ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${resultado.eficiencia.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Aproveitado',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
          final legend = Column(
            mainAxisSize: MainAxisSize.min,
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _LegendItem(
                      color: item.color,
                      label: item.label,
                      value: '${item.value.toStringAsFixed(1)}%',
                    ),
                  ),
                )
                .toList(),
          );

          if (compact) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [chart, const SizedBox(height: 8), legend],
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              chart,
              const SizedBox(width: 20),
              Flexible(child: legend),
            ],
          );
        },
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(label)),
      const SizedBox(width: 8),
      Text(
        value,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
}
