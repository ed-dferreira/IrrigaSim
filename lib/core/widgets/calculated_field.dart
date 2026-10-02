import 'package:flutter/material.dart';

/// Valor calculado pela aplicação — exibição somente leitura.
class CalculatedField extends StatelessWidget {
  const CalculatedField({
    super.key,
    required this.label,
    required this.value,
    this.suffix,
    this.helper,
  });

  final String label;
  final double value;
  final String? suffix;
  final String? helper;

  String get _formatted {
    final fix = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
    return suffix == null ? fix : '$fix $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _formatted,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.calculate_outlined,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          helper ?? 'Calculado pela aplicação',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
