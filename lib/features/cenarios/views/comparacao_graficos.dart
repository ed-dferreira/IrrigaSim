import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/features/cenarios/models/cenario_salvo.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_chart_section.dart';

/// Abas de gráficos comparativos: desempenho (barras agrupadas), balanço de
/// água (barras empilhadas) e as séries hidráulicas — avanço, perfil de
/// lâminas e oportunidade — sobrepostas por cenário.
class SecaoGraficosComparativos extends StatefulWidget {
  final List<CenarioSalvo> cenarios;

  const SecaoGraficosComparativos({super.key, required this.cenarios});

  @override
  State<SecaoGraficosComparativos> createState() => _SecaoGraficosState();
}

class _SecaoGraficosState extends State<SecaoGraficosComparativos> {
  int _abaSelecionada = 0;

  @override
  Widget build(BuildContext context) {
    final cenarios = widget.cenarios;
    final cores = _coresParaCenarios(Theme.of(context).colorScheme);
    final abas = <IrrigationChartTab>[];
    final filhos = <Widget>[];

    void incluir(
      String label,
      IconData icone,
      Widget filho, {
      bool comDados = true,
    }) {
      if (!comDados) return;
      abas.add(IrrigationChartTab(label: label, icon: icone));
      filhos.add(filho);
    }

    incluir(
      'Desempenho',
      AppIcons.indicadores,
      _BarrasDeDesempenho(cenarios: cenarios, cores: cores),
    );
    incluir(
      'Balanço de água',
      AppIcons.balancoHidrico,
      _BarrasDeBalanco(cenarios: cenarios, cores: cores),
    );
    incluir(
      'Avanço',
      AppIcons.curvaAvanco,
      _CurvasComparadas(
        series: [
          for (var i = 0; i < cenarios.length; i++)
            (
              cenarios[i].nome,
              cenarios[i].resultado.curvaAvanco,
              cores[i % cores.length],
            ),
        ],
        tituloEixoX: 'Tempo (min)',
        tituloEixoY: 'Distância (m)',
        rotuloX: 'min',
        rotuloY: 'm',
      ),
      comDados: cenarios.any(
        (cenario) => cenario.resultado.curvaAvanco.isNotEmpty,
      ),
    );
    incluir(
      'Perfil de lâminas',
      AppIcons.perfilInfiltracao,
      _CurvasComparadas(
        series: [
          for (var i = 0; i < cenarios.length; i++)
            (
              cenarios[i].nome,
              <PontoGrafico>[
                for (var j = 0;
                    j < cenarios[i].resultado.perfilLongitudinal.length;
                    j++)
                  PontoGrafico(
                    j /
                        math.max(
                          cenarios[i].resultado.perfilLongitudinal.length - 1,
                          1,
                        ) *
                        100,
                    cenarios[i].resultado.perfilLongitudinal[j] * 1000,
                  ),
              ],
              cores[i % cores.length],
            ),
        ],
        tituloEixoX: 'Posição ao longo do terreno (%)',
        tituloEixoY: 'Lâmina (mm)',
        rotuloX: '%',
        rotuloY: 'mm',
      ),
      comDados: cenarios.any(
        (cenario) => cenario.resultado.perfilLongitudinal.isNotEmpty,
      ),
    );
    incluir(
      'Oportunidade',
      AppIcons.oportunidade,
      _CurvasComparadas(
        series: [
          for (var i = 0; i < cenarios.length; i++)
            if (cenarios[i].resultado.curvaOportunidade.isNotEmpty)
              (
                cenarios[i].nome,
                cenarios[i].resultado.curvaOportunidade,
                cores[i % cores.length],
              ),
        ],
        tituloEixoX: 'Tempo (min)',
        tituloEixoY: 'Lâmina (mm)',
        rotuloX: 'min',
        rotuloY: 'mm',
      ),
      comDados: cenarios.any(
        (cenario) => cenario.resultado.curvaOportunidade.isNotEmpty,
      ),
    );

    if (_abaSelecionada >= abas.length) _abaSelecionada = 0;

    return IrrigationChartSection(
      title: 'Gráficos comparativos',
      height: 340,
      tabs: abas,
      selectedIndex: _abaSelecionada,
      onTabSelected: (index) => setState(() => _abaSelecionada = index),
      children: filhos,
    );
  }
}

/// Cor fixa por posição do cenário, reutilizada por todas as abas.
List<Color> _coresParaCenarios(ColorScheme colors) => [
  colors.primary,
  colors.tertiary,
  colors.secondary,
  colors.error,
  Colors.teal,
  Colors.deepPurple,
  Colors.orange,
];

/// Legenda colorida: um chip por cenário, na ordem das séries.
class _Legenda extends StatelessWidget {
  final List<CenarioSalvo> cenarios;
  final List<Color> cores;
  const _Legenda({required this.cenarios, required this.cores});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (var i = 0; i < cenarios.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: cores[i % cores.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  cenarios[i].nome,
                  style: text.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Largura das barras conforme o número de cenários (até 7).
double _larguraDaBarra(int quantidade) {
  if (quantidade <= 1) return 36;
  if (quantidade == 2) return 18;
  if (quantidade == 3) return 13;
  if (quantidade == 4) return 10;
  return 7;
}

/// Ea/CUC/DU/Er em barras agrupadas: um grupo por indicador, uma barra por
/// cenário (cor = posição do cenário na legenda).
class _BarrasDeDesempenho extends StatelessWidget {
  final List<CenarioSalvo> cenarios;
  final List<Color> cores;
  const _BarrasDeDesempenho({required this.cenarios, required this.cores});

  static const _indicadores = <(String, double Function(SimulationResult))>[
    ('Ea', _lerEficiencia),
    ('CUC', _lerCuc),
    ('DU', _lerDu),
    ('Er', _lerEr),
  ];

  static double _lerEficiencia(SimulationResult r) => r.eficiencia;
  static double _lerCuc(SimulationResult r) => r.cuc;
  static double _lerDu(SimulationResult r) => r.du;
  static double _lerEr(SimulationResult r) => r.eficienciaRequerimento;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final largura = _larguraDaBarra(cenarios.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Legenda(cenarios: cenarios, cores: cores),
        const SizedBox(height: 10),
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
                    getTooltipItem: (grupo, _, rod, indiceRod) {
                      final nome = cenarios[indiceRod.clamp(
                        0,
                        cenarios.length - 1,
                      )].nome;
                      final indicador = _indicadores[grupo.x.clamp(
                        0,
                        _indicadores.length - 1,
                      )];
                      return BarTooltipItem(
                        '$nome\n'
                        '${indicador.$1}: ${rod.toY.toStringAsFixed(1)}%',
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
                        if (idx < 0 || idx >= _indicadores.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            _indicadores[idx].$1,
                            style: text.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text('%'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 25,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(
                          '${value.toInt()}',
                          style: text.labelSmall,
                        ),
                      ),
                    ),
                  ),
                ),
                gridData: FlGridData(
                  horizontalInterval: 25,
                  drawVerticalLine: false,
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
                  for (var i = 0; i < _indicadores.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        for (var j = 0; j < cenarios.length; j++)
                          BarChartRodData(
                            toY: _indicadores[i]
                                .$2(cenarios[j].resultado)
                                .clamp(0, 100)
                                .toDouble(),
                            color: cores[j % cores.length],
                            width: largura,
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
      ],
    );
  }
}

/// Balanço de água aplicada em barras empilhadas (100%): aproveitado,
/// percolação profunda e escoamento superficial — uma barra por cenário
/// (A, B, C… conforme a ordem na legenda).
class _BarrasDeBalanco extends StatelessWidget {
  final List<CenarioSalvo> cenarios;
  final List<Color> cores;
  const _BarrasDeBalanco({required this.cenarios, required this.cores});

  double _aproveitado(SimulationResult r) =>
      r.metricas['Balanço - Aproveitado'] ?? r.eficiencia;
  double _percolacao(SimulationResult r) =>
      r.metricas['Balanço - Percolação'] ?? r.perdaPercolacao;
  double _escoamento(SimulationResult r) =>
      r.metricas['Balanço - Escoamento'] ?? r.perdaEscoamento;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final balancos = <(double, double, double)>[
      for (final cenario in cenarios)
        (
          math.max(0, _aproveitado(cenario.resultado)),
          math.max(0, _percolacao(cenario.resultado)),
          math.max(0, _escoamento(cenario.resultado)),
        ),
    ];
    final comDados = balancos.any((b) => b.$1 + b.$2 + b.$3 > 0);
    if (!comDados) {
      return const Center(
        child: Text('Sem componentes de balanço disponíveis'),
      );
    }

    BarChartGroupData barra(int indiceCenario) {
      final (aproveitado, percolacao, escoamento) = balancos[indiceCenario];
      final soma = aproveitado + percolacao + escoamento;
      if (soma <= 0) {
        return BarChartGroupData(
          x: indiceCenario,
          barRods: const [],
        );
      }
      return BarChartGroupData(
        x: indiceCenario,
        barRods: [
          BarChartRodData(
            toY: soma,
            width: math.max(_larguraDaBarra(cenarios.length), 14),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
            rodStackItems: [
              BarChartRodStackItem(0, aproveitado, colors.primary),
              BarChartRodStackItem(
                aproveitado,
                aproveitado + percolacao,
                colors.tertiary,
              ),
              BarChartRodStackItem(
                aproveitado + percolacao,
                soma,
                colors.error,
              ),
            ],
          ),
        ],
      );
    }

    double normalizado(double parte, int indiceCenario) {
      final (aproveitado, percolacao, escoamento) = balancos[indiceCenario];
      final soma = aproveitado + percolacao + escoamento;
      if (soma <= 0) return 0;
      return parte / soma * 100;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Legenda(cenarios: cenarios, cores: cores),
        const SizedBox(height: 10),
        Expanded(
          child: ExcludeSemantics(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colors.inverseSurface,
                    getTooltipItem: (grupo, _, _, _) {
                      final indice = grupo.x.clamp(0, balancos.length - 1);
                      final nome = cenarios[indice].nome;
                      return BarTooltipItem(
                        '$nome\n'
                        'Aproveitado '
                        '${normalizado(balancos[indice].$1, indice).toStringAsFixed(1)}% · '
                        'Percolação '
                        '${normalizado(balancos[indice].$2, indice).toStringAsFixed(1)}%\n'
                        'Escoamento '
                        '${normalizado(balancos[indice].$3, indice).toStringAsFixed(1)}%',
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
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= cenarios.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            String.fromCharCode(65 + idx),
                            style: text.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text('%'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 25,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(
                          '${value.toInt()}',
                          style: text.labelSmall,
                        ),
                      ),
                    ),
                  ),
                ),
                gridData: FlGridData(
                  horizontalInterval: 25,
                  drawVerticalLine: false,
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
                  for (var i = 0; i < cenarios.length; i++) barra(i),
                ],
              ),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 350),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            _ItemLegendaFixa(
              cor: colors.primary,
              label: 'Aproveitado',
              colors: colors,
              text: text,
            ),
            _ItemLegendaFixa(
              cor: colors.tertiary,
              label: 'Percolação',
              colors: colors,
              text: text,
            ),
            _ItemLegendaFixa(
              cor: colors.error,
              label: 'Escoamento',
              colors: colors,
              text: text,
            ),
          ],
        ),
      ],
    );
  }
}

class _ItemLegendaFixa extends StatelessWidget {
  final Color cor;
  final String label;
  final ColorScheme colors;
  final TextTheme text;
  const _ItemLegendaFixa({
    required this.cor,
    required this.label,
    required this.colors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: text.labelSmall),
      ],
    );
  }
}

/// Gráfico de linhas com uma série por cenário, usado por avanço,
/// oportunidade e perfil longitudinal.
class _CurvasComparadas extends StatelessWidget {
  final List<(String, List<PontoGrafico>, Color)> series;
  final String tituloEixoX;
  final String tituloEixoY;
  final String rotuloX;
  final String rotuloY;

  const _CurvasComparadas({
    required this.series,
    required this.tituloEixoX,
    required this.tituloEixoY,
    required this.rotuloX,
    required this.rotuloY,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final seriesValidas = [
      for (final (nome, pontos, cor) in series)
        if (pontos
            .any((ponto) => ponto.x.isFinite && ponto.y.isFinite && ponto.y >= 0))
          (nome, pontos, cor),
    ];
    if (seriesValidas.isEmpty) {
      return const Center(child: Text('Sem dados para comparar'));
    }
    final maxX = [
      for (final (_, pontos, _) in series)
        for (final ponto in pontos)
          if (ponto.x.isFinite && ponto.x >= 0) ponto.x,
    ].fold(0.0, math.max);
    final maxY = [
      for (final (_, pontos, _) in series)
        for (final ponto in pontos)
          if (ponto.y.isFinite && ponto.y >= 0) ponto.y,
    ].fold(0.0, math.max);
    final chartMaxX = math.max(maxX, 1).toDouble();
    final chartMaxY = math.max(maxY, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final (nome, _, cor) in seriesValidas)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: cor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      nome,
                      style: text.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ExcludeSemantics(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: chartMaxX,
                minY: 0,
                maxY: chartMaxY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  drawVerticalLine: true,
                  horizontalInterval: chartMaxY / 4,
                  verticalInterval: chartMaxX / 4,
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
                    axisNameWidget: Text(tituloEixoX),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: chartMaxX / 4,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(
                          value.toStringAsFixed(0),
                          style: text.labelSmall,
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(tituloEixoY),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      interval: chartMaxY / 4,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(
                          value.toStringAsFixed(0),
                          style: text.labelSmall,
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
                            '${seriesValidas[spot.barIndex.clamp(0, seriesValidas.length - 1)].$1}\n'
                            '${spot.x.toStringAsFixed(1)} $rotuloX · '
                            '${spot.y.toStringAsFixed(1)} $rotuloY',
                            TextStyle(color: colors.onInverseSurface),
                          ),
                        )
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  for (final serie in seriesValidas)
                    LineChartBarData(
                      spots: [
                        for (final ponto in serie.$2)
                          if (ponto.x.isFinite &&
                              ponto.y.isFinite &&
                              ponto.y >= 0 &&
                              ponto.x >= 0)
                            FlSpot(ponto.x, ponto.y),
                      ],
                      isCurved: true,
                      curveSmoothness: .25,
                      preventCurveOverShooting: true,
                      color: serie.$3,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                    ),
                ],
              ),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 350),
            ),
          ),
        ),
      ],
    );
  }
}
