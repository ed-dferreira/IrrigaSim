import 'package:flutter/material.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/features/irrigation/domain/entities/irrigation_parameters.dart';

class IrrigationMethodCard extends StatelessWidget {
  final MetodoIrrigacao metodo;
  final VoidCallback onTap;

  const IrrigationMethodCard({
    super.key,
    required this.metodo,
    required this.onTap,
  });

  Color _getColor(ColorScheme colorScheme) {
    switch (metodo) {
      case MetodoIrrigacao.sulco:
        return AppColors.sulco;
      case MetodoIrrigacao.faixa:
        return AppColors.faixa;
      case MetodoIrrigacao.inundacao:
        return AppColors.inundacao;
    }
  }

  IconData get _icon {
    switch (metodo) {
      case MetodoIrrigacao.sulco:
        return Icons.water_drop_outlined;
      case MetodoIrrigacao.faixa:
        return Icons.view_week_outlined;
      case MetodoIrrigacao.inundacao:
        return Icons.water_outlined;
    }
  }

  String get _descricao {
    switch (metodo) {
      case MetodoIrrigacao.sulco:
        return 'Irrigação por canais estreitos entre linhas de cultivo';
      case MetodoIrrigacao.faixa:
        return 'Irrigação por faixas superficiais ao longo do terreno';
      case MetodoIrrigacao.inundacao:
        return 'Irrigação por alagamento controlado do terreno';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final methodColor = _getColor(colorScheme);

    return Semantics(
      label: 'Método de irrigação: ${metodo.displayName}. $_descricao',
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
                    color: methodColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, color: methodColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metodo.displayName,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _descricao,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
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
