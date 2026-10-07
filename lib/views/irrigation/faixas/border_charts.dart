import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:irrigasim/models/faixas/border_result.dart';
import 'package:irrigasim/models/faixas/border_project.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/services/simulation/faixas/border_planning.dart';

class BorderCharts extends StatelessWidget {
  final BorderResult result;
  final double irnMm;
  final BorderProject project;
  final BorderAlternatives? alternatives;
  final BorderOperation? operation;
  final List<(String, BorderResult, BorderProject)>? scenarioProfiles;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  const BorderCharts({
    super.key,
    required this.result,
    required this.irnMm,
    required this.project,
    this.alternatives,
    this.operation,
    this.scenarioProfiles,
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
    const allLabels = [
      'Avanço',
      'Infiltração',
      'Volumes',
      'VI',
      'Métricas × q',
      'Operação',
    ];
    const allIcons = [
      AppIcons.curvaAvanco,
      AppIcons.perfilInfiltracao,
      AppIcons.balancoHidrico,
      AppIcons.perfilInfiltracao,
      AppIcons.indicadores,
      AppIcons.projetoOperacao,
    ];
    final availableTabs = <int>[
      0,
      1,
      2,
      3,
      if ((alternatives?.candidatos.isNotEmpty ?? false) ||
          project.alternativas.isNotEmpty)
        4,
      if (operation != null) 5,
    ];
    final selected = availableTabs.contains(selectedIndex) ? selectedIndex : 0;
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
                itemCount: availableTabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tab = availableTabs[index];
                  final active = tab == selected;
                  return Semantics(
                    button: true,
                    selected: active,
                    label: 'Gráfico de ${allLabels[tab]}',
                    child: InkWell(
                      onTap: () => onTabSelected(tab),
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
                              allIcons[tab],
                              size: 18,
                              color: active
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              allLabels[tab],
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
            else if (selected == 1)
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
              )
            else if (selected == 2)
              _chartSection(
                context,
                'Volumes calculados',
                AppIcons.balancoHidrico,
                [
                  Semantics(
                    label:
                        'Volumes totais da faixa em metros cúbicos: útil ${result.volumeUtilTotalM3.toStringAsFixed(1)}, percolado ${result.volumePercoladoTotalM3.toStringAsFixed(1)}, escoado ${result.volumeEscoadoTotalM3.toStringAsFixed(1)}. Déficit de requerimento ${(result.volumeDeficitM3M * result.larguraM).toStringAsFixed(1)} metros cúbicos, apresentado separadamente porque não compõe a água aplicada.',
                    child: SizedBox(
                      height: 230,
                      child: ExcludeSemantics(
                        child: BarChart(
                          BarChartData(
                            barGroups: [
                              _volumeBar(
                                0,
                                result.volumeUtilTotalM3,
                                scheme.primary,
                              ),
                              _volumeBar(
                                1,
                                result.volumePercoladoTotalM3,
                                scheme.tertiary,
                              ),
                              _volumeBar(
                                2,
                                result.volumeEscoadoTotalM3,
                                scheme.error,
                              ),
                              _volumeBar(
                                3,
                                result.volumeDeficitM3M * result.larguraM,
                                scheme.secondary,
                              ),
                            ],
                            titlesData: _barTitles([
                              'Útil',
                              'Pp',
                              'Pe',
                              'Déficit',
                            ], 'Volume (m³)'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'Déficit é uma diferença em relação à demanda; não é componente do balanço de água aplicada.',
                  ),
                ],
              )
            else if (selected == 3)
              scenarioProfiles == null
                  ? _infiltrationVelocityChart(
                      context,
                      result,
                      irnMm,
                      project,
                      scheme,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final scenario in scenarioProfiles!)
                          _infiltrationVelocityChart(
                            context,
                            scenario.$2,
                            irnMm,
                            scenario.$3,
                            scheme,
                            scenarioName: scenario.$1,
                          ),
                      ],
                    )
            else if (selected == 4)
              _efficiencyByFlowChart(
                context,
                alternatives,
                project.alternativas,
                scheme,
              )
            else
              _operationChart(context, operation, scheme),
          ],
        ),
      ),
    );
  }
}

/// Diagnóstico numérico disponível na área avançada de auditoria, não na
/// navegação principal de gráficos.
class BorderConvergenceDetails extends StatelessWidget {
  const BorderConvergenceDetails({super.key, required this.result});
  final BorderResult result;

  @override
  Widget build(BuildContext context) => _convergenceChart(
    context,
    result.convergencia,
    Theme.of(context).colorScheme,
  );
}

BarChartGroupData _volumeBar(int x, double value, Color color) =>
    BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: color,
          width: 24,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );

FlTitlesData _barTitles(List<String> labels, String yLabel) => FlTitlesData(
  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  bottomTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      getTitlesWidget: (value, meta) {
        final index = value.toInt();
        if (index < 0 || index >= labels.length) return const SizedBox.shrink();
        return SideTitleWidget(meta: meta, child: Text(labels[index]));
      },
    ),
  ),
  leftTitles: AxisTitles(
    axisNameWidget: Text(yLabel),
    sideTitles: const SideTitles(showTitles: true),
  ),
);

Widget _infiltrationVelocityChart(
  BuildContext context,
  BorderResult result,
  double irnMm,
  BorderProject project,
  ColorScheme scheme, {
  String scenarioName = '',
}) {
  final points = result.perfil
      .skip(1)
      .where(
        (point) => point.oportunidadeMin > 0 && point.oportunidadeMin.isFinite,
      )
      .toList();
  if (project.k == null || project.a == null || project.vibMMin == null) {
    return const Text(
      'Velocidade de infiltração pendente: informe k, a e VIB.',
    );
  }
  if (points.isEmpty) {
    return const Text(
      'VI não calculável: o perfil não contém oportunidade positiva fora da entrada.',
    );
  }
  final velocity = points
      .map(
        (point) =>
            project.k! *
                project.a! *
                math.pow(point.oportunidadeMin, project.a! - 1) +
            project.vibMMin!,
      )
      .toList();
  final maxAccumulated = result.perfil
      .map((point) => point.infiltracaoM * 1000)
      .reduce(math.max);
  final maxVelocity = velocity.map((value) => value * 60000).reduce(math.max);

  Widget chart(
    String title,
    String yLabel,
    double maximum,
    List<FlSpot> spots,
    Color tone, {
    List<FlSpot>? reference,
  }) {
    final lines = [
      LineChartBarData(
        spots: spots,
        color: tone,
        barWidth: 3,
        dotData: const FlDotData(show: false),
      ),
      if (reference != null)
        LineChartBarData(
          spots: reference,
          color: scheme.error,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
    ];
    final data = LineChartData(
      minX: 0,
      maxX: result.perfil.last.xM,
      minY: 0,
      maxY: maximum <= 0 ? 1 : maximum * 1.1,
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          axisNameWidget: const Text('Distância (m)'),
          sideTitles: const SideTitles(showTitles: true),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: Text(yLabel),
          sideTitles: const SideTitles(showTitles: true),
        ),
      ),
      lineBarsData: lines,
    );
    return _chartSection(context, title, AppIcons.perfilInfiltracao, [
      Semantics(
        label: '$title por distância ao longo da faixa.',
        child: SizedBox(
          height: 210,
          child: ExcludeSemantics(
            child: LineChart(
              data,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
            ),
          ),
        ),
      ),
    ]);
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      chart(
        '${scenarioName.isEmpty ? '' : '$scenarioName · '}Infiltração acumulada e IRN',
        'Infiltração (mm)',
        math.max(maxAccumulated, irnMm),
        [
          for (final point in result.perfil)
            FlSpot(point.xM, point.infiltracaoM * 1000),
        ],
        scheme.primary,
        reference: [FlSpot(0, irnMm), FlSpot(result.perfil.last.xM, irnMm)],
      ),
      chart(
        '${scenarioName.isEmpty ? '' : '$scenarioName · '}Velocidade de infiltração VI',
        'VI (mm/h)',
        maxVelocity,
        [
          for (var i = 0; i < points.length; i++)
            FlSpot(points[i].xM, velocity[i] * 60000),
        ],
        scheme.tertiary,
      ),
      Text(
        'VI = k·a·τᵃ⁻¹ + VIB; τ = oportunidade calculada. O ponto da entrada foi omitido porque τ=0 torna a derivada singular quando 0<a<1.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

Widget _efficiencyByFlowChart(
  BuildContext context,
  BorderAlternatives? alternatives,
  List<BorderAlternativeRecord> savedAlternatives,
  ColorScheme scheme,
) {
  final saved = savedAlternatives
      .where(
        (record) =>
            record.motivoRejeicao == null &&
            record.eficienciaPercentual != null &&
            record.erPercentual != null &&
            record.ppPercentual != null &&
            record.pePercentual != null,
      )
      .toList();
  if (alternatives == null && saved.isEmpty) {
    return const Text(
      'Configure e execute uma busca na grade para comparar Ea, Er, Pp e Pe por vazão.',
    );
  }
  final flows =
      (alternatives?.candidatos
                  .where((candidate) => candidate.resultado != null)
                  .map((candidate) => candidate.vazaoLsM) ??
              saved.map((record) => record.vazaoLsM))
          .toSet()
          .toList()
        ..sort();
  final selectedFlows = flows.length > 14
      ? [
          for (var i = 0; i < 14; i++)
            flows[(i * (flows.length - 1) / 13).round()],
        ]
      : flows;
  if (selectedFlows.isEmpty) {
    return const Text(
      'A grade não contém candidatas elegíveis para comparação.',
    );
  }
  final bars = <BarChartGroupData>[];
  final objective = alternatives?.objetivo ?? saved.first.objetivo ?? 'Ea';
  for (var i = 0; i < selectedFlows.length; i++) {
    final flow = selectedFlows[i];
    final activeCandidates = alternatives?.candidatos
        .where(
          (candidate) =>
              candidate.resultado != null && candidate.vazaoLsM == flow,
        )
        .toList();
    double ea, er, pp, pe;
    if (activeCandidates != null && activeCandidates.isNotEmpty) {
      activeCandidates.sort(
        (a, b) => objective == 'Ea'
            ? b.resultado!.ea.compareTo(a.resultado!.ea)
            : b.resultado!.er.compareTo(a.resultado!.er),
      );
      final result = activeCandidates.first.resultado!;
      ea = result.ea;
      er = result.er;
      pp = result.pp;
      pe = result.pe;
    } else {
      final records = saved.where((record) => record.vazaoLsM == flow).toList();
      records.sort(
        (a, b) => objective == 'Ea'
            ? b.eficienciaPercentual!.compareTo(a.eficienciaPercentual!)
            : b.erPercentual!.compareTo(a.erPercentual!),
      );
      final record = records.first;
      ea = record.eficienciaPercentual!;
      er = record.erPercentual!;
      pp = record.ppPercentual!;
      pe = record.pePercentual!;
    }
    bars.add(
      BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(toY: ea, color: scheme.primary, width: 9),
          BarChartRodData(toY: er, color: scheme.tertiary, width: 9),
          BarChartRodData(toY: pp, color: scheme.error, width: 9),
          BarChartRodData(toY: pe, color: scheme.secondary, width: 9),
        ],
      ),
    );
  }
  return _chartSection(
    context,
    'Eficiências e perdas por q0 (melhor L por objetivo em cada vazão)',
    AppIcons.indicadores,
    [
      SizedBox(
        height: 250,
        child: ExcludeSemantics(
          child: BarChart(
            BarChartData(
              barGroups: bars,
              maxY: 100,
              minY: 0,
              titlesData: _barTitles([
                for (final q in selectedFlows) q.toStringAsFixed(2),
              ], 'Percentual (%)'),
            ),
          ),
        ),
      ),
      Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          for (final entry in [
            (scheme.primary, 'Ea'),
            (scheme.tertiary, 'Er'),
            (scheme.error, 'Pp'),
            (scheme.secondary, 'Pe'),
          ])
            _Legend(color: entry.$1, label: entry.$2),
        ],
      ),
      Text(
        '${alternatives == null ? 'Alternativas restauradas do cenário' : 'Grade de ${alternatives.candidatos.length} candidatas'}; objetivo $objective. Para cada q0, exibe-se a candidata elegível de melhor objetivo.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

Widget _operationChart(
  BuildContext context,
  BorderOperation? operation,
  ColorScheme scheme,
) {
  if (operation == null) {
    return const Text(
      'Cronograma pendente: complete PI, jornada, mudança, NFP e janela/dias reais de fornecimento.',
    );
  }
  final groups = [
    for (var i = 0; i < operation.gruposPorDia.length; i++)
      BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: operation.gruposPorDia[i].toDouble(),
            color: scheme.primary,
            width: 14,
          ),
        ],
      ),
  ];
  return _chartSection(
    context,
    'Grupos de faixas programados por dia',
    AppIcons.projetoOperacao,
    [
      SizedBox(
        height: 220,
        child: ExcludeSemantics(
          child: BarChart(
            BarChartData(
              barGroups: groups,
              titlesData: _barTitles([
                for (var i = 0; i < operation.gruposPorDia.length; i++)
                  '${i + 1}',
              ], 'Grupos/dia'),
            ),
          ),
        ),
      ),
      Text(
        'Prazo: ${operation.atendePrazo ? 'atende' : 'não atende'} · Oferta Qt: ${operation.atendeOferta ? 'atende' : 'insuficiente ou pendente'}. Os dias sem fornecimento permanecem com zero grupos.',
      ),
    ],
  );
}

Widget _convergenceChart(
  BuildContext context,
  BorderConvergenceHistory history,
  ColorScheme scheme,
) {
  final series = <(String, List<double>, Color)>[
    ('t0', history.opportunityMin, scheme.primary),
    ('r', history.advanceExponent, scheme.tertiary),
    ('td', history.recessionEndMin, scheme.error),
  ].where((entry) => entry.$2.length > 1).toList();
  if (series.isEmpty) {
    return const Text(
      'Histórico de iterações não está disponível neste resultado salvo antigo.',
    );
  }
  final maxLength = series.map((s) => s.$2.length).reduce(math.max);
  final chartData = LineChartData(
    minX: 0,
    maxX: (maxLength - 1).toDouble(),
    minY: 0,
    titlesData: FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        axisNameWidget: const Text('Iteração'),
        sideTitles: const SideTitles(showTitles: true),
      ),
      leftTitles: AxisTitles(
        axisNameWidget: const Text('Desvio relativo (%)'),
        sideTitles: const SideTitles(showTitles: true),
      ),
    ),
    lineBarsData: [
      for (final entry in series)
        LineChartBarData(
          spots: [
            for (var i = 0; i < entry.$2.length; i++)
              FlSpot(
                i.toDouble(),
                entry.$2.last == 0
                    ? 0
                    : 100 *
                          (entry.$2[i] - entry.$2.last).abs() /
                          entry.$2.last.abs(),
              ),
          ],
          color: entry.$3,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
    ],
  );
  return _chartSection(
    context,
    'Convergência numérica (desvio relativo ao último iterado)',
    AppIcons.recomendacao,
    [
      Semantics(
        label:
            'Diagnóstico técnico de convergência. Histórico disponível para ${series.map((entry) => '${entry.$1}, ${entry.$2.length} iterações').join('; ')}. O eixo vertical é o desvio relativo percentual em relação ao último iterado.',
        child: SizedBox(
          height: 240,
          child: ExcludeSemantics(
            child: LineChart(
              chartData,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
            ),
          ),
        ),
      ),
      Wrap(
        spacing: 12,
        children: [
          for (final entry in series)
            _Legend(
              color: entry.$3,
              label: '${entry.$1} · ${entry.$2.length} iterações',
            ),
        ],
      ),
    ],
  );
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
