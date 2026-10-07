import 'package:flutter/material.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/views/irrigation/widgets/irrigation_project_components.dart';

/// Componentes de apresentação comuns aos relatórios dos métodos de irrigação.
class IrrigationAuditSection extends StatelessWidget {
  const IrrigationAuditSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = true,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: IrrigationSpacing.major),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    clipBehavior: Clip.antiAlias,
    child: initiallyExpanded
        ? Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeading(title: title, icon: icon),
                const SizedBox(height: IrrigationSpacing.section),
                ...children,
              ],
            ),
          )
        : ExpansionTile(
            leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
            title: Text(title),
            initiallyExpanded: false,
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: children,
          ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class IrrigationAuditRow extends StatelessWidget {
  const IrrigationAuditRow(
    this.label,
    this.value, {
    super.key,
    this.detail,
    this.isWarning = false,
  });
  final String label;
  final String value;
  final String? detail;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final valueContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isWarning ? colors.error : null,
          ),
        ),
        if (detail != null)
          Text(
            detail!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isWarning ? colors.error : colors.onSurfaceVariant,
            ),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: IrrigationSpacing.compact),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 2),
                valueContent,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 220,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Expanded(child: valueContent),
            ],
          );
        },
      ),
    );
  }
}

class IrrigationFormulaCard extends StatelessWidget {
  const IrrigationFormulaCard({
    super.key,
    required this.formula,
    required this.description,
  });
  final String formula;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formula,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class IrrigationAlertBanner extends StatelessWidget {
  const IrrigationAlertBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.atencao, color: colors.onErrorContainer, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
