import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:irrigasim/models/faixas/border_result.dart';
import 'package:irrigasim/app/theme/app_icons.dart';

class BorderCharts extends StatelessWidget {
  final BorderResult result;
  final double irnMm;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  const BorderCharts({
    super.key,
    required this.result,
    required this.irnMm,
    this.selectedIndex = 0,
    this.onTabSelected = _ignoreTab,
  });

  static void _ignoreTab(int _) {}

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profile = result.perfil;
    final maxX = profile.last.xM;
    final maxTime = result.trFinalMin;
    final maxDepth = math.max(
      irnMm,
      profile.map((p) => p.infiltracaoM * 1000).reduce(math.max),
    );
    LineChartBarData line(List<FlSpot> points, Color tone) => LineChartBarData(
      spots: points,
      color: tone,
      barWidth: 3,
      isCurved: false,
      dotData: const FlDotData(show: false),
    );
    FlTitlesData titles(String x, String y) => FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        axisNameWidget: Text(x),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: maxX / 4,
          getTitlesWidget: (v, meta) => SideTitleWidget(
            meta: meta,
            child: Text(
              v.toStringAsFixed(0),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      ),
      leftTitles: AxisTitles(
        axisNameWidget: Text(y),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 42,
          getTitlesWidget: (v, meta) => SideTitleWidget(
            meta: meta,
            child: Text(
              v.toStringAsFixed(0),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      ),
    );
    final selected = selectedIndex.clamp(0, 1);
    const labels = ['Avanço', 'Infiltração'];
    const icons = [AppIcons.curvaAvanco, AppIcons.perfilInfiltracao];
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
                Icon(AppIcons.chart, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Gráficos',
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
                itemCount: labels.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final active = index == selected;
                  return Semantics(
                    button: true,
                    selected: active,
                    label: 'Gráfico de ${labels[index]}',
                    child: InkWell(
                      onTap: () => onTabSelected(index),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? scheme.primaryContainer
                              : scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: active
                                ? scheme.primary
                                : scheme.outlineVariant,
                            width: active ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icons[index],
                              size: 18,
                              color: active
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              labels[index],
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: active
                                        ? scheme.primary
                                        : scheme.onSurfaceVariant,
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
            if (selected == 0)
              _chartSection(
                context,
                'Avanço e recessão',
                AppIcons.curvaAvanco,
                [
                  Semantics(
                    label:
                        'Curvas de avanço e recessão simuladas. Chegada ao final em ${result.taFinalMin.toStringAsFixed(1)} minutos; recessão final em ${result.trFinalMin.toStringAsFixed(1)} minutos.',
                    child: SizedBox(
                      height: 260,
                      child: ExcludeSemantics(
                        child: LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: maxX,
                            minY: 0,
                            maxY: maxTime * 1.05,
                            titlesData: titles('Distância (m)', 'Tempo (min)'),
                            lineBarsData: [
                              line([
                                for (final p in profile)
                                  FlSpot(p.xM, p.avancoMin),
                              ], scheme.primary),
                              line([
                                for (final p in profile)
                                  FlSpot(p.xM, p.recessaoMin),
                              ], scheme.tertiary),
                            ],
                          ),
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 300),
                        ),
                      ),
                    ),
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(width: 14, height: 4, color: scheme.primary),
                      const SizedBox(width: 6),
                      const Text('Avanço'),
                      const SizedBox(width: 16),
                      Container(width: 14, height: 4, color: scheme.tertiary),
                      const SizedBox(width: 6),
                      const Text('Recessão'),
                    ],
                  ),
                ],
              )
            else
              _chartSection(
                context,
                'Infiltração e IRN',
                AppIcons.perfilInfiltracao,
                [
                  Semantics(
                    label:
                        'Perfil longitudinal de infiltração comparado à IRN de ${irnMm.toStringAsFixed(1)} milímetros. Infiltração mínima ${(profile.map((p) => p.infiltracaoM * 1000).reduce(math.min)).toStringAsFixed(1)} milímetros.',
                    child: SizedBox(
                      height: 260,
                      child: ExcludeSemantics(
                        child: LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: maxX,
                            minY: 0,
                            maxY: maxDepth * 1.1,
                            titlesData: titles(
                              'Distância (m)',
                              'Infiltração (mm)',
                            ),
                            lineBarsData: [
                              line([
                                for (final p in profile)
                                  FlSpot(p.xM, p.infiltracaoM * 1000),
                              ], scheme.primary),
                              line([
                                FlSpot(0, irnMm),
                                FlSpot(maxX, irnMm),
                              ], scheme.error),
                            ],
                          ),
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 300),
                        ),
                      ),
                    ),
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(width: 14, height: 4, color: scheme.primary),
                      const SizedBox(width: 6),
                      const Text('Infiltração'),
                      const SizedBox(width: 16),
                      Container(width: 14, height: 4, color: scheme.error),
                      const SizedBox(width: 6),
                      const Text('IRN'),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

Widget _chartSection(
  BuildContext context,
  String title,
  IconData icon,
  List<Widget> children,
) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
    const SizedBox(height: 12),
    ...children,
  ],
);
