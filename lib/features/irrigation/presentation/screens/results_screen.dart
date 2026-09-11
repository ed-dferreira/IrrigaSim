import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigation/domain/entities/simulation_result.dart';
import 'package:irrigasim/features/irrigation/presentation/viewmodels/parameters_view_model.dart';
import 'package:irrigasim/features/irrigation/presentation/viewmodels/results_view_model.dart';
import 'package:irrigasim/features/irrigation/presentation/widgets/advance_chart.dart';
import 'package:irrigasim/features/irrigation/presentation/widgets/infiltration_chart.dart';
import 'package:irrigasim/features/irrigation/presentation/widgets/water_balance_chart.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(parametersProvider);
    final result = state.resultado;
    if (result == null) {
      return const Scaffold(
        body: Center(child: Text('Execute uma simulação primeiro.')),
      );
    }
    final accent = _methodColor(state.metodo);
    return Scaffold(
      appBar: AppBar(title: const Text('Resultados da simulação')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ResultHero(
                        state: state,
                        accent: accent,
                        onSave: () => _showSaveDialog(context, ref),
                        onExport: () => _showExport(context, state, result),
                      ),
                      const SizedBox(height: 16),
                      _KpiGrid(result: result, state: state),
                      if (result.metricas.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _MetricsCard(result: result, accent: accent),
                      ],
                      const SizedBox(height: 16),
                      if (state.metodo == MetodoIrrigacao.inundacao &&
                          state.tipoInundacao == TipoInundacao.permanente)
                        _PermanentCharts(result: result)
                      else if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _ChartCard(
                                title: 'Balanço hídrico',
                                child: WaterBalanceChart(resultado: result),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _ChartCard(
                                title: 'Curva de avanço',
                                child: AdvanceChart(resultado: result),
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _ChartCard(
                          title: 'Balanço hídrico',
                          child: WaterBalanceChart(resultado: result),
                        ),
                        const SizedBox(height: 16),
                        _ChartCard(
                          title: 'Curva de avanço',
                          child: AdvanceChart(resultado: result),
                        ),
                      ],
                      if (!(state.metodo == MetodoIrrigacao.inundacao &&
                          state.tipoInundacao == TipoInundacao.permanente)) ...[
                        const SizedBox(height: 16),
                        _ChartCard(
                          title: 'Perfil de infiltração',
                          child: InfiltrationChart(resultado: result),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _Recommendation(result: result, accent: accent),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSaveDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final state = ref.read(parametersProvider);
    final result = state.resultado;
    if (result == null) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Salvar em Cenários'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome do cenário'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              final notifier = ref.read(resultsProvider.notifier);
              notifier.setNomeCenario(name);
              await notifier.salvarCenario(
                metodo: state.metodo,
                parametros: state.toIrrigationParameters(),
                resultado: result,
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              final error = ref.read(resultsProvider).erro;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error ?? 'Cenário salvo com sucesso!')),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _showExport(
    BuildContext context,
    ParametersState state,
    SimulationResult result,
  ) {
    final csv = _csv(state, result);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Exportar dados em CSV',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'O conteúdo inclui entradas, indicadores e séries dos gráficos.',
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 260),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    csv,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: csv));
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'CSV copiado. Cole em um arquivo ou planilha.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copiar CSV'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultHero extends StatelessWidget {
  const _ResultHero({
    required this.state,
    required this.accent,
    required this.onSave,
    required this.onExport,
  });
  final ParametersState state;
  final Color accent;
  final VoidCallback onSave;
  final VoidCallback onExport;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [accent, accent.withValues(alpha: .72)]),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.metodo.displayName,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            Text(
              state.metodo == MetodoIrrigacao.inundacao
                  ? state.tipoInundacao.displayName
                  : 'Diagnóstico hidráulico completo',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Exportar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
            ),
            FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Salvar cenário'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: accent,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.result, required this.state});
  final SimulationResult result;
  final ParametersState state;
  @override
  Widget build(BuildContext context) {
    final permanent =
        state.metodo == MetodoIrrigacao.inundacao &&
        state.tipoInundacao == TipoInundacao.permanente;
    final items = permanent
        ? [
            (
              'Turno de rega',
              '${_metric(result, 'Turno de rega')} dias',
              'Calculado',
            ),
            (
              'Vazão de enchimento',
              '${_metric(result, 'Vazão de enchimento')} L/s',
              'Qe',
            ),
            (
              'Vazão de manutenção',
              '${_metric(result, 'Vazão de manutenção')} L/s',
              'Qm',
            ),
            (
              'Vazão disponível',
              '${_metric(result, 'Vazão disponível')} L/s',
              'Fonte',
            ),
            (
              'Eficiência de condução',
              '${result.eficiencia.toStringAsFixed(1)}%',
              'Ec',
            ),
            (
              'Tempo de enchimento',
              '${_metric(result, 'Tempo de enchimento')} h',
              'Com a vazão disponível',
            ),
          ]
        : [
            (
              'Eficiência de aplicação',
              '${result.eficiencia.toStringAsFixed(1)}%',
              result.classificacaoEa,
            ),
            (
              'Grau de adequação',
              '${result.eficienciaRequerimento.toStringAsFixed(1)}%',
              'Er',
            ),
            (
              'Eficiência de distribuição',
              '${_metric(result, 'Eficiência de distribuição')}%',
              'Ed',
            ),
            (
              'Percolação profunda',
              '${result.perdaPercolacao.toStringAsFixed(1)}%',
              'Pp',
            ),
            (
              'Lâmina média infiltrada',
              '${(result.laminaMedia * 1000).toStringAsFixed(1)} mm',
              'Aplicada',
            ),
            (
              'Escoamento superficial',
              '${result.perdaEscoamento.toStringAsFixed(1)}%',
              'Pe',
            ),
          ];
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 900
            ? 3
            : box.maxWidth >= 560
            ? 2
            : 1;
        final width = (box.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.$2,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.$3,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.result, required this.accent});
  final SimulationResult result;
  final Color accent;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: accent),
              const SizedBox(width: 10),
              Text(
                'Dados calculados',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, box) {
              final width = box.maxWidth >= 800
                  ? (box.maxWidth - 32) / 3
                  : box.maxWidth >= 480
                  ? (box.maxWidth - 16) / 2
                  : box.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: result.metricas.entries.map((entry) {
                  return SizedBox(
                    width: width,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_number(entry.value)} ${result.unidadesMetricas[entry.key] ?? ''}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SizedBox(height: 320, child: child),
        ],
      ),
    ),
  );
}

class _PermanentCharts extends StatelessWidget {
  const _PermanentCharts({required this.result});
  final SimulationResult result;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final charts = [
          _BarChartCard(
            title: 'Comparação de vazões',
            unit: 'L/s',
            values: {
              'Enchimento': result.metricas['Vazão de enchimento'] ?? 0,
              'Manutenção': result.metricas['Vazão de manutenção'] ?? 0,
              'Disponível': result.metricas['Vazão disponível'] ?? 0,
            },
          ),
          _BarChartCard(
            title: 'Componentes do volume de enchimento',
            unit: 'm³',
            values: {
              'Solo': result.metricas['Armazenamento no solo'] ?? 0,
              'Superfície': result.metricas['Armazenamento superficial'] ?? 0,
              'ET': result.metricas['ET durante enchimento'] ?? 0,
              'Percolação':
                  result.metricas['Percolação durante enchimento'] ?? 0,
            },
          ),
        ];
        if (constraints.maxWidth < 800) {
          return Column(
            children: [charts.first, const SizedBox(height: 16), charts.last],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: charts.first),
            const SizedBox(width: 16),
            Expanded(child: charts.last),
          ],
        );
      },
    );
  }
}

class _BarChartCard extends StatelessWidget {
  const _BarChartCard({
    required this.title,
    required this.unit,
    required this.values,
  });
  final String title;
  final String unit;
  final Map<String, double> values;

  @override
  Widget build(BuildContext context) {
    final maximum = values.values.fold<double>(
      0,
      (current, value) => value > current ? value : current,
    );
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            for (final entry in values.entries) ...[
              Row(
                children: [
                  Expanded(child: Text(entry.key)),
                  Text(
                    '${_number(entry.value)} $unit',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: maximum <= 0 ? 0 : entry.value / maximum,
                  minHeight: 12,
                  color: colors.primary,
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _Recommendation extends StatelessWidget {
  const _Recommendation({required this.result, required this.accent});
  final SimulationResult result;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    final message =
        result.alertaVazaoExcedida ??
        (result.eficiencia >= 85 && result.cuc >= 80
            ? 'O cenário atende a bons critérios de eficiência e uniformidade.'
            : result.eficiencia >= 75
            ? 'O desempenho é adequado, mas ajustes de vazão ou tempo podem melhorar a uniformidade.'
            : 'Revise vazão, tempo de aplicação e parâmetros do solo antes de adotar este cenário.');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_rounded, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leitura do resultado',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _csv(ParametersState state, SimulationResult result) {
  final rows = <String>[
    'grupo;indicador;valor;unidade',
    'identificação;método;${state.metodo.displayName};',
    if (state.metodo == MetodoIrrigacao.inundacao)
      'identificação;regime;${state.tipoInundacao.displayName};',
    'entrada;comprimento;${state.comprimento};m',
    'entrada;declividade longitudinal;${state.declividade};m/m',
    'entrada;declividade transversal;${state.declividadeTransversal};m/m',
    'entrada;desnível longitudinal;${state.desnivelM};m',
    'entrada;distância longitudinal;${state.distanciaHorizontalM};m',
    'entrada;desnível transversal;${state.desnivelTransversalM};m',
    'entrada;distância transversal;${state.distanciaTransversalM};m',
    'resultado;eficiência de aplicação;${result.eficiencia};%',
    'resultado;CUC;${result.cuc};%',
    'resultado;DU;${result.du};%',
    'resultado;lâmina média;${result.laminaMedia * 1000};mm',
    'resultado;tempo de avanço;${result.tempoAvanco};min',
  ];
  for (final entry in result.metricas.entries) {
    rows.add(
      'resultado;${entry.key};${entry.value};${result.unidadesMetricas[entry.key] ?? ''}',
    );
  }
  for (var i = 0; i < result.curvaAvanco.length; i++) {
    final point = result.curvaAvanco[i];
    rows.add('série avanço;posição ${point.y} m;${point.x};min');
  }
  for (var i = 0; i < result.perfilLongitudinal.length; i++) {
    rows.add(
      'série infiltração;ponto ${i + 1};${result.perfilLongitudinal[i] * 1000};mm',
    );
  }
  return rows.join('\n');
}

String _number(double value) {
  final absolute = value.abs();
  if (absolute >= 1000) return value.toStringAsFixed(0);
  if (absolute >= 10) return value.toStringAsFixed(1);
  return value.toStringAsFixed(3);
}

String _metric(SimulationResult result, String key) =>
    _number(result.metricas[key] ?? 0);

Color _methodColor(MetodoIrrigacao method) => switch (method) {
  MetodoIrrigacao.sulco => AppColors.sulco,
  MetodoIrrigacao.faixa => AppColors.faixa,
  MetodoIrrigacao.inundacao => AppColors.inundacao,
};
