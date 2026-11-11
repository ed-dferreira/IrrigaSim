import 'package:flutter/material.dart';
import 'package:irrigasim/core/theme/app_icons.dart';

/// Estado vazio comum às telas de resultado de irrigação.
class IrrigationEmptyResult extends StatelessWidget {
  const IrrigationEmptyResult({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: colors.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(title, style: text.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message, style: text.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(AppIcons.etapasAnteriores),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
