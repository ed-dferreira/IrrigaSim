import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:irrigasim/models/simulation_result.dart';

class AdvanceChart extends StatelessWidget {
  const AdvanceChart({super.key, required this.resultado});

  final SimulationResult resultado;

  @override
  Widget build(BuildContext context) {
    if (resultado.curvaAvanco.isEmpty) {
      return const Center(child: Text('Sem dados de avanço'));
    }

    final colors = Theme.of(context).colorScheme;
    final maxTime = resultado.curvaAvanco.fold<double>(
      0,
      (maximum, point) => math.max(maximum, point.x),
    );
    final maxDistance = resultado.curvaAvanco.fold<double>(
      0,
      (maximum, point) => math.max(maximum, point.y),
    );
    final chartMaxTime = math.max(maxTime, 1).toDouble();
    final chartMaxDistance = math.max(maxDistance, 1).toDouble();
    final spots = resultado.curvaAvanco
        .map((point) => FlSpot(point.x, point.y))
        .toList();

    return Semantics(
      label:
          'Curva de avanço da água. A frente alcançou ${maxDistance.toStringAsFixed(1)} metros em ${maxTime.toStringAsFixed(1)} minutos.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Avanço da frente de escoamento ao longo do terreno',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ExcludeSemantics(
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: chartMaxTime,
                  minY: 0,
                  maxY: chartMaxDistance,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    drawVerticalLine: true,
                    horizontalInterval: chartMaxDistance / 4,
                    verticalInterval: chartMaxTime / 4,
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
                      axisNameWidget: const Text('Tempo (min)'),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: chartMaxTime / 4,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value.toStringAsFixed(0),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text('Distância (m)'),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: chartMaxDistance / 4,
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
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => colors.inverseSurface,
                      getTooltipItems: (spots) => spots
                          .map(
                            (spot) => LineTooltipItem(
                              '${spot.x.toStringAsFixed(1)} min\n${spot.y.toStringAsFixed(1)} m',
                              TextStyle(color: colors.onInverseSurface),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: .25,
                      preventCurveOverShooting: true,
                      color: colors.primary,
                      barWidth: 3,
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
        ],
      ),
    );
  }
}
