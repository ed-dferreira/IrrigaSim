import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:irrigasim/features/irrigation/models/simulation_result.dart';

class InfiltrationChart extends StatelessWidget {
  const InfiltrationChart({super.key, required this.resultado});

  final SimulationResult resultado;

  @override
  Widget build(BuildContext context) {
    if (resultado.perfilLongitudinal.isEmpty) {
      return const Center(child: Text('Sem dados de perfil longitudinal'));
    }

    final colors = Theme.of(context).colorScheme;
    final requiredDepth = resultado.laminaRequerida * 1000;
    final depths = resultado.perfilLongitudinal
        .map((depth) => depth * 1000)
        .toList();
    final largestDepth = depths.fold<double>(
      requiredDepth,
      (maximum, depth) => math.max(maximum, depth),
    );
    final maxY = math.max(largestDepth * 1.15, 1).toDouble();
    final denominator = math.max(depths.length - 1, 1);
    final spots = [
      for (var index = 0; index < depths.length; index++)
        FlSpot(index / denominator * 100, depths[index]),
    ];

    return Semantics(
      label:
          'Perfil longitudinal da lâmina infiltrada. Uniformidade CUC de ${resultado.cuc.toStringAsFixed(1)} por cento, DU de ${resultado.du.toStringAsFixed(1)} por cento e lâmina requerida de ${requiredDepth.toStringAsFixed(1)} milímetros.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Distribuição da lâmina ao longo do terreno',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _Indicator(label: 'CUC', value: resultado.cuc, colors: colors),
              _Indicator(label: 'DU', value: resultado.du, colors: colors),
              Text(
                'LN ${requiredDepth.toStringAsFixed(1)} mm',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: colors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ExcludeSemantics(
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 100,
                  minY: 0,
                  maxY: maxY,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    horizontalInterval: maxY / 4,
                    verticalInterval: 25,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: colors.outlineVariant, strokeWidth: 1),
                    getDrawingVerticalLine: (_) =>
                        FlLine(color: colors.outlineVariant, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text('Posição no terreno (%)'),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 25,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '${value.toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text('Lâmina (mm)'),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: maxY / 4,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value.toStringAsFixed(0),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: requiredDepth,
                        color: colors.tertiary,
                        strokeWidth: 2,
                        dashArray: [6, 4],
                      ),
                    ],
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => colors.inverseSurface,
                      getTooltipItems: (spots) => spots
                          .map(
                            (spot) => LineTooltipItem(
                              '${spot.x.toStringAsFixed(0)}% do terreno\n${spot.y.toStringAsFixed(1)} mm',
                              TextStyle(color: colors.onInverseSurface),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      color: colors.primary,
                      barWidth: 3,
                      isCurved: false,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                          radius: 3,
                          color: colors.primary,
                          strokeColor: colors.surface,
                          strokeWidth: 1.5,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colors.primary.withValues(alpha: .14),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 350),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 20,
            runSpacing: 4,
            children: [
              _LegendLine(color: colors.primary, label: 'Lâmina infiltrada'),
              _LegendLine(
                color: colors.tertiary,
                label: 'LN requerida',
                dashed: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final double value;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final color = value >= 80
        ? colors.primary
        : value >= 65
        ? colors.tertiary
        : colors.error;
    return Text(
      '$label ${value.toStringAsFixed(1)}%',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
    );
  }
}

class _LegendLine extends StatelessWidget {
  const _LegendLine({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 24,
        child: Divider(
          color: color,
          thickness: 2,
          indent: dashed ? 4 : 0,
          endIndent: dashed ? 4 : 0,
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}
