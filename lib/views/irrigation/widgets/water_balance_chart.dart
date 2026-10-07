import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:irrigasim/models/simulation_result.dart';

class WaterBalanceChart extends StatelessWidget {
  const WaterBalanceChart({super.key, required this.resultado});

  final SimulationResult resultado;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final metricas = resultado.metricas;

    final aproveitado =
        metricas['Balanço - Aproveitado'] ?? resultado.eficiencia;
    final percolacao =
        metricas['Balanço - Percolação'] ?? resultado.perdaPercolacao;
    final escoamento =
        metricas['Balanço - Escoamento'] ?? resultado.perdaEscoamento;
    final utilMm = metricas['Lâmina útil'];
    final percoladaMm = metricas['Lâmina percolada'];
    final escoadaMm = metricas['Lâmina escoada'];
    final aplicadaMm = metricas['Lâmina aplicada'];
    final deficitMm = metricas['Déficit de lâmina'];

    final rawItems = [
      (
        label: 'Aproveitado',
        value: aproveitado,
        color: colors.primary,
        mm: utilMm,
      ),
      (
        label: 'Percolação profunda',
        value: percolacao,
        color: colors.tertiary,
        mm: percoladaMm,
      ),
      (
        label: 'Escoamento superficial',
        value: escoamento,
        color: colors.error,
        mm: escoadaMm,
      ),
    ];
    final positive = rawItems
        .map(
          (item) => (
            label: item.label,
            value: item.value.clamp(0.0, double.infinity),
            color: item.color,
            mm: item.mm,
          ),
        )
        .where((item) => item.value > 0)
        .toList();
    final total = positive.fold<double>(0, (sum, item) => sum + item.value);
    final items = total > 0
        ? positive
              .map(
                (item) => (
                  label: item.label,
                  value: item.value / total * 100,
                  color: item.color,
                  mm: item.mm,
                ),
              )
              .toList()
        : positive;
    final displayTotal = items.fold<double>(0, (sum, item) => sum + item.value);

    if (displayTotal <= 0) {
      return Semantics(
        label: 'Balanço hídrico indisponível para visualização: não há componentes positivos calculados para representar. O déficit de demanda, quando existente, não integra o balanço da água aplicada.',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: colors.onSurfaceVariant),
                const SizedBox(height: 8),
                Text(
                  'Sem componentes de água aplicada disponíveis para o gráfico.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (deficitMm != null && deficitMm > 0)
                  Text(
                    'Déficit de demanda: ${deficitMm.toStringAsFixed(1)} mm. Esse valor não compõe o balanço da água aplicada.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final deficiteAbaixo =
        deficitMm != null &&
            deficitMm > 0.5 &&
            utilMm != null &&
            percoladaMm != null
        ? deficitMm
        : null;

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
                    sections: items
                        .map(
                          (item) => PieChartSectionData(
                            value: item.value,
                            color: item.color,
                            radius: 24,
                            showTitle: false,
                          ),
                        )
                        .toList(),
                  ),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 350),
                ),
                ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${aproveitado.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Aproveitado',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      if (aplicadaMm != null)
                        Text(
                          '${aplicadaMm.toStringAsFixed(0)} mm aplicados',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );

          final legend = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...items.map((item) {
                final mm = item.mm;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _LegendItem(
                    color: item.color,
                    label: item.label,
                    value: '${item.value.toStringAsFixed(1)}%',
                    detail: mm != null ? '${mm.toStringAsFixed(1)} mm' : null,
                  ),
                );
              }),
              if (deficiteAbaixo != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Déficit: ${deficiteAbaixo.toStringAsFixed(1)} mm da demanda não atendida',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: colors.onSecondaryContainer),
                  ),
                ),
              ],
            ],
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
    this.detail,
  });

  final Color color;
  final String label;
  final String value;
  final String? detail;

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
      if (detail != null) ...[
        const SizedBox(width: 6),
        Text(
          detail!,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
      const SizedBox(width: 8),
      Text(
        value,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
}
