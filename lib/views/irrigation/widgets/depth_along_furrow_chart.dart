import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:irrigasim/models/simulation_result.dart';

class DepthAlongFurrowChart extends StatelessWidget {
  const DepthAlongFurrowChart({super.key, required this.resultado});

  final SimulationResult resultado;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (resultado.perfilLongitudinal.isEmpty) {
      return const Center(child: Text('Sem dados de perfil longitudinal'));
    }

    final requiredDepth = resultado.laminaRequerida * 1000;
    final depths =
        resultado.perfilLongitudinal.map((d) => d * 1000).toList();
    final maxY = math.max(
          depths.fold<double>(0, (m, d) => math.max(m, d)),
          requiredDepth,
        ) *
        1.15;
    final denominator = math.max(depths.length - 1, 1);

    final spots = [
      for (var i = 0; i < depths.length; i++)
        FlSpot(i / denominator * 100, depths[i]),
    ];

    return Semantics(
      label:
          'Lâmina infiltrada ao longo do sulco. Mínimo ${depths.reduce(math.min).toStringAsFixed(1)} mm, máximo ${depths.reduce(math.max).toStringAsFixed(1)} mm, requerida ${requiredDepth.toStringAsFixed(1)} mm.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Distribuição da lâmina infiltrada ao longo do terreno',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _StatChip(
                label: 'Mínimo',
                value: '${depths.reduce(math.min).toStringAsFixed(1)} mm',
                color: depths.reduce(math.min) < requiredDepth
                    ? colors.error
                    : colors.primary,
              ),
              _StatChip(
                label: 'Máximo',
                value: '${depths.reduce(math.max).toStringAsFixed(1)} mm',
                color: colors.primary,
              ),
              _StatChip(
                label: 'LN requerida',
                value: '${requiredDepth.toStringAsFixed(1)} mm',
                color: colors.tertiary,
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
                            '${value.toInt()}%',
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
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
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
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
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
