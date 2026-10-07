import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:irrigasim/models/simulation_result.dart';

/// Gráfico do tempo de oportunidade ao longo do sulco:
/// To(x) = Ta_final + To_final − Tx(x), com Tx(v) lida da curva de avanço.
///
/// Os eixos são derivados dos pontos reais (sem faixa fixa): no início do
/// sulco To pode chegar a Ta + To, bem acima de To_final.
class OpportunityTimeChart extends StatelessWidget {
  const OpportunityTimeChart({super.key, required this.resultado});

  final SimulationResult resultado;

  @override
  Widget build(BuildContext context) {
    if (resultado.curvaAvanco.isEmpty) {
      return const Center(child: Text('Sem dados de avanço'));
    }

    final colors = Theme.of(context).colorScheme;
    final tempoAvanco = resultado.tempoAvanco;
    final toFinal =
        resultado.tempoOportunidadeFinalMin ??
        resultado.metricas['Tempo de oportunidade'] ??
        0.0;
    final tempoCorte =
        resultado.metricas['Tempo de aplicação calculado'] ??
        tempoAvanco + toFinal;

    final rawSpots = <FlSpot>[];
    if (resultado.curvaOportunidade.isNotEmpty) {
      for (final point in resultado.curvaOportunidade) {
        if (!point.x.isFinite || !point.y.isFinite || point.y < 0) continue;
        rawSpots.add(FlSpot(point.x, point.y));
      }
    } else {
      for (final point in resultado.curvaAvanco) {
        if (!point.x.isFinite || !point.y.isFinite || point.y < 0) continue;
        final to = tempoCorte - point.x;
        if (!to.isFinite || to < 0) continue;
        rawSpots.add(FlSpot(point.y, to));
      }
    }
    if (rawSpots.isEmpty) {
      return const Center(child: Text('Sem dados de oportunidade'));
    }
    rawSpots.sort((a, b) => a.x.compareTo(b.x));

    var minX = rawSpots.first.x;
    var maxX = rawSpots.first.x;
    var minY = rawSpots.first.y;
    var maxY = rawSpots.first.y;
    for (final spot in rawSpots) {
      minX = math.min(minX, spot.x);
      maxX = math.max(maxX, spot.x);
      minY = math.min(minY, spot.y);
      maxY = math.max(maxY, spot.y);
    }
    maxY = math.max(maxY, toFinal);
    minY = math.min(minY, 0.0);

    final xSpan = maxX - minX;
    final ySpan = maxY - minY;
    final padX = xSpan > 0 ? xSpan * 0.02 : 1.0;
    final padY = ySpan > 0 ? ySpan * 0.08 : math.max(1.0, maxY * 0.1);
    final chartMinX = (minX - padX).clamp(double.negativeInfinity, maxX);
    final chartMaxX = maxX + padX;
    final chartMinY = math.min(0.0, minY - padY * 0.25);
    final chartMaxY = maxY + padY;
    final safeX = math.max(chartMaxX - chartMinX, 1e-6);
    final safeY = math.max(chartMaxY - chartMinY, 1e-6);

    final xInterval = _niceInterval(safeX);
    final yInterval = _niceInterval(safeY);

    return Semantics(
      label:
          'Tempo de oportunidade ao longo do terreno. '
          'Mínimo ${minY.toStringAsFixed(0)} minutos, máximo ${maxY.toStringAsFixed(0)} minutos. '
          'No final: ${toFinal.toStringAsFixed(0)} minutos.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            resultado.hipoteseRecessao == 'medidaPorEstaca'
                ? 'To(x) = instante de recessão medido − Tx(x)'
                : 'Tempo de oportunidade To(x) = Tc − Tx(x)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ExcludeSemantics(
              child: LineChart(
                LineChartData(
                  minX: chartMinX,
                  maxX: chartMaxX,
                  minY: chartMinY,
                  maxY: chartMaxY,
                  clipData: const FlClipData.none(),
                  gridData: FlGridData(
                    drawVerticalLine: true,
                    horizontalInterval: yInterval,
                    verticalInterval: xInterval,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: colors.outlineVariant, strokeWidth: 1),
                    getDrawingVerticalLine: (_) =>
                        FlLine(color: colors.outlineVariant, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  extraLinesData: toFinal > chartMinY && toFinal < chartMaxY
                      ? ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: toFinal,
                              color: colors.tertiary,
                              strokeWidth: 1.5,
                              dashArray: [6, 4],
                              label: HorizontalLineLabel(
                                show: true,
                                labelResolver: (_) =>
                                    'To final ${toFinal.toStringAsFixed(0)} min',
                                style: TextStyle(
                                  color: colors.tertiary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                padding: const EdgeInsets.only(left: 8),
                              ),
                            ),
                          ],
                        )
                      : null,
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text('Distância (m)'),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: xInterval,
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
                      axisNameWidget: const Text('To (min)'),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: yInterval,
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
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => colors.inverseSurface,
                      getTooltipItems: (touchedSpots) => touchedSpots
                          .map(
                            (spot) => LineTooltipItem(
                              '${spot.x.toStringAsFixed(0)} m\n'
                              '${spot.y.toStringAsFixed(0)} min',
                              TextStyle(
                                color: colors.onInverseSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: rawSpots,
                      isCurved: false,
                      color: colors.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: rawSpots.length <= 30,
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
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 350),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Faixa: ${minY.toStringAsFixed(0)}–${maxY.toStringAsFixed(0)} min · '
            'To no final: ${toFinal.toStringAsFixed(0)} min · '
            'Corte (Ta + To): ${tempoCorte.toStringAsFixed(0)} min',
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// Intervalo “bonito” (1/2/5 × 10^n) para ~4–6 passos de grade.
  static double _niceInterval(double span) {
    if (!span.isFinite || span <= 0) return 1;
    final rough = span / 5;
    final exp = math.log(rough) / math.ln10;
    final pow10 = math.pow(10, exp.floorToDouble()).toDouble();
    final norm = rough / pow10;
    double nice;
    if (norm <= 1) {
      nice = 1;
    } else if (norm <= 2) {
      nice = 2;
    } else if (norm <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    final interval = nice * pow10;
    return interval > 0 && interval.isFinite ? interval : 1;
  }
}
