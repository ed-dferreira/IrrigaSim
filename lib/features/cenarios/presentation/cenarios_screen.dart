import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/features/irrigation/data/models/cenario_salvo.dart';
import 'package:irrigasim/features/irrigation/providers.dart';
import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';

class CenariosScreen extends ConsumerWidget {
  const CenariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cenariosAsync = ref.watch(cenariosProvider);
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: cenariosAsync.when(
          data: (cenarios) => _buildContent(context, ref, cenarios, colors, textStyles),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Erro ao carregar cenários: $e'),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<CenarioSalvo> cenarios,
    ColorScheme colors,
    TextTheme textStyles,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cenários Salvos',
                      style: textStyles.headlineMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      '${cenarios.length} simulação(ões) registrada(s)',
                      style: textStyles.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (cenarios.isNotEmpty)
                IconButton(
                  onPressed: () => context.go('/home'),
                  icon: Icon(AppIcons.novoCenario, color: colors.primary),
                ),
            ],
          ),

          const SizedBox(height: 16),

          if (cenarios.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppIcons.navCenarios,
                        size: 36,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum cenário salvo ainda',
                      style: textStyles.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Execute uma simulação e clique em "Salvar"\npara registrar seus testes aqui.',
                      style: textStyles.bodyMedium?.copyWith(
                        color: colors.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: Icon(AppIcons.criarNovaSimulacao),
                      label: const Text('Criar Nova Simulação'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: cenarios.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final cenario = cenarios[index];
                  return _CenarioCard(
                    cenario: cenario,
                    onView: () {
                      // TODO: Navigate to results for this scenario
                    },
                    onDelete: () async {
                      final repo = ref.read(irrigationRepositoryProvider);
                      await repo.excluir(cenario.id);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CenarioCard extends StatelessWidget {
  final CenarioSalvo cenario;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const _CenarioCard({
    required this.cenario,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final dateFormat = '${cenario.dataCriacao.day.toString().padLeft(2, '0')}/${cenario.dataCriacao.month.toString().padLeft(2, '0')}/${cenario.dataCriacao.year}';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    cenario.nome,
                    style: textStyles.titleMedium?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cenario.metodo.displayName,
                    style: textStyles.labelSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Salvo em: $dateFormat',
              style: textStyles.bodySmall?.copyWith(color: colors.outline),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 1,
              color: colors.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _KpiColumn(
                  label: 'Eficiência (Ea)',
                  value: '${cenario.resultado.eficiencia.toInt()}%',
                  color: colors.secondary,
                ),
                _KpiColumn(
                  label: 'Uniformidade (CUC)',
                  value: '${cenario.resultado.cuc.toInt()}%',
                  color: colors.tertiary,
                ),
                _KpiColumn(
                  label: 'Lâmina Média',
                  value: '${cenario.resultado.laminaMedia.toStringAsFixed(1)} mm',
                  color: colors.primary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onView,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Visualizar'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => _confirmDelete(context),
                  icon: Icon(
                    AppIcons.excluirCenario,
                    color: colors.error,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir cenário'),
        content: Text('Deseja excluir "${cenario.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: Text('Excluir', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }
}

class _KpiColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          label,
          style: textStyles.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        Text(
          value,
          style: textStyles.titleSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
