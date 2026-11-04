import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/features/cenarios/providers/scenario_providers.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/scenario_comparison_chart.dart';

/// Aba "Comparação": gráfico do resultado atual contra o cenário salvo.
class ScenarioComparison extends ConsumerWidget {
  const ScenarioComparison({super.key, required this.resultadoAtual});

  final SimulationResult resultadoAtual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarios = ref.watch(cenariosProvider);
    return scenarios.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _comparisonMessage(
        context,
        'Não foi possível carregar os cenários salvos.',
      ),
      data: (items) {
        if (items.isEmpty) {
          return _comparisonMessage(
            context,
            'Salve outro cenário para compará-lo com este resultado.',
          );
        }
        final scenario = items.first;
        return ScenarioComparisonChart(
          resultadoA: resultadoAtual,
          resultadoB: scenario.resultado,
          labelA: 'Resultado atual',
          labelB: scenario.nome,
        );
      },
    );
  }

  Widget _comparisonMessage(BuildContext context, String message) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.comparar, size: 40, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
