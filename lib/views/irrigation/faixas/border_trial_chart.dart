import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/services/simulation/faixas/border_field_trial.dart';
import 'package:irrigasim/models/faixas/border_result.dart';

class BorderTrialChart extends StatelessWidget {
  const BorderTrialChart({super.key, required this.trial, this.simulated});

  final BorderTrialResult trial;
  final BorderResult? simulated;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxX = trial.advance.stakes.last.xM;
    final maxY = <double>[
      ...trial.profile.map((point) => point.avancoMin),
      ...trial.profile.map((point) => point.recessaoMin),
      for (var i = 0; i <= 100; i++) trial.advance.arrival(maxX * i / 100),
      if (simulated != null)
        ...simulated!.perfil.map((point) => point.avancoMin),
    ].fold<double>(0, (a, b) => a > b ? a : b);
    final measured = trial.advance.stakes;
    final residuals = measured
        .skip(1)
        .map((stake) => trial.advance.arrival(stake.xM) - stake.avancoMin)
        .toList();
    final hasMeasuredRecession =
        trial.profile.isNotEmpty &&
        measured.any((stake) => stake.recessaoMin != null);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(AppIcons.projetoEnsaio, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Ensaio medido × ajuste',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'RMSE do avanço: ${trial.advance.rmseMin.toStringAsFixed(2)} min',
            ),
            SizedBox(
              height: 240,
              child: Semantics(
                label:
                    'Gráfico de estacas medidas e curva ajustada de avanço. RMSE ${trial.advance.rmseMin.toStringAsFixed(2)} minutos.',
                child: ExcludeSemantics(
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: maxX,
                      minY: 0,
                      maxY: maxY <= 0 ? 1 : maxY * 1.15,
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameWidget: const Text('Distância (m)'),
                          sideTitles: const SideTitles(showTitles: true),
                        ),
                        leftTitles: AxisTitles(
                          axisNameWidget: const Text('Tempo (min)'),
                          sideTitles: const SideTitles(showTitles: true),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i <= 100; i++)
                              FlSpot(
                                maxX * i / 100,
                                trial.advance.arrival(maxX * i / 100),
                              ),
                          ],
                          color: colors.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                        if (hasMeasuredRecession)
                          LineChartBarData(
                            spots: [
                              for (final point in trial.profile)
                                FlSpot(point.xM, point.recessaoMin),
                            ],
                            color: colors.error,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                          ),
                        if (hasMeasuredRecession)
                          LineChartBarData(
                            spots: [
                              for (final stake in measured.where(
                                (s) => s.recessaoMin != null,
                              ))
                                FlSpot(stake.xM, stake.recessaoMin!),
                            ],
                            color: colors.error,
                            barWidth: 0,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, index) =>
                                  FlDotCirclePainter(
                                    radius: 4,
                                    color: colors.error,
                                    strokeWidth: 1,
                                    strokeColor: colors.surface,
                                  ),
                            ),
                          ),
                        if (simulated != null)
                          LineChartBarData(
                            spots: [
                              for (final point in simulated!.perfil)
                                FlSpot(point.xM, point.avancoMin),
                            ],
                            color: colors.secondary,
                            barWidth: 2,
                            dashArray: [5, 4],
                            dotData: const FlDotData(show: false),
                          ),
                        LineChartBarData(
                          spots: [
                            for (final stake in measured)
                              FlSpot(stake.xM, stake.avancoMin),
                          ],
                          color: colors.tertiary,
                          barWidth: 0,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(
                                  radius: 4,
                                  color: colors.tertiary,
                                  strokeWidth: 1,
                                  strokeColor: colors.surface,
                                ),
                          ),
                        ),
                      ],
                    ),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 250),
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: 16,
              children: [
                _Legend(color: colors.primary, label: 'Curva ajustada'),
                _Legend(color: colors.tertiary, label: 'Estacas medidas'),
                if (hasMeasuredRecession)
                  _Legend(
                    color: colors.error,
                    label: 'Recessão medida/interpolada',
                  ),
                if (simulated != null)
                  _Legend(color: colors.secondary, label: 'Avanço simulado'),
              ],
            ),
            if (residuals.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Resíduos por estaca (ajustado − medido), RMSE ${trial.advance.rmseMin.toStringAsFixed(2)} min',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              SizedBox(
                height: 135,
                child: BarChart(
                  BarChartData(
                    barGroups: [
                      for (var i = 0; i < residuals.length; i++)
                        BarChartGroupData(
                          x: i + 1,
                          barRods: [
                            BarChartRodData(
                              toY: residuals[i],
                              color: colors.tertiary,
                              width: 12,
                            ),
                          ],
                        ),
                    ],
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text('Estaca'),
                        sideTitles: const SideTitles(showTitles: true),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: const Text('Resíduo (min)'),
                        sideTitles: const SideTitles(showTitles: true),
                      ),
                    ),
                  ),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                ),
              ),
            ],
            if (trial.avisos.isNotEmpty)
              for (final notice in trial.avisos)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('[${notice.codigo}] ${notice.mensagem}'),
                ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label),
    ],
  );
}
