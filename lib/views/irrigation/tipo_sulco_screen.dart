import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/app/theme/app_text_styles.dart';
import 'package:irrigasim/models/tipo_sulco_info.dart';
import 'package:irrigasim/viewmodels/parameters_controller.dart';

class TipoSulcoScreen extends ConsumerWidget {
  const TipoSulcoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tipo de Sulco')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selecione o Tipo de Sulco', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              'Escolha o tipo de sulco mais adequado para suas condições de terreno e cultura.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: TipoSulco.values.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final tipo = TipoSulco.values[index];
                  return _TipoSulcoCard(
                    tipo: tipo,
                    onTap: () => _open(context, ref, tipo),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref, TipoSulco tipo) {
    ref.read(parametersProvider.notifier).setTipoSulco(tipo);
    context.push('/home/irrigation/project');
  }
}

class _TipoSulcoCard extends StatelessWidget {
  const _TipoSulcoCard({
    required this.tipo,
    required this.onTap,
  });

  final TipoSulco tipo;
  final VoidCallback onTap;

  Color get _color => AppColors.sulco;

  IconData get _icon => switch (tipo) {
    TipoSulco.sulcos_comuns => Icons.straighten_rounded,
    TipoSulco.sulcos_contorno => Icons.terrain_rounded,
    TipoSulco.sulcos_corrugados => Icons.waves_rounded,
    TipoSulco.sulcos_nivel_tabuleiros => Icons.grid_view_rounded,
    TipoSulco.sulcos_nivel_fechados => Icons.lock_rounded,
    TipoSulco.sulcos_em_zigue_zague => Icons.swap_calls_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final info = TipoSulcoInfo.getInfo(tipo);

    return Semantics(
      label: 'Tipo de sulco: ${tipo.displayName}. ${tipo.descricao}',
      button: true,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, color: _color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tipo.displayName,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tipo.descricao,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _InfoChip(
                            label: 'Declividade',
                            value: info.declividade.faixaIdealLabel,
                          ),
                          _InfoChip(
                            label: 'Comprimento',
                            value: info.comprimentoFaixa,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
