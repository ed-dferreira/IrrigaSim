import 'package:material_ui/material_ui.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_input_fields.dart';
import 'package:irrigasim/core/theme/app_icons.dart';

import 'irrigation_project_components.dart';

/// Rótulo acima do campo, no padrão das telas de projeto de irrigação.
class IrrigationLabeledField extends StatelessWidget {
  const IrrigationLabeledField({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 6),
      child,
    ],
  );
}

/// Grade responsiva de campos; widgets sem rótulo ocupam a linha inteira.
class IrrigationFieldGrid extends StatelessWidget {
  const IrrigationFieldGrid({
    super.key,
    required this.fields,
    this.maxFieldWidth = 340,
    this.spacing = IrrigationSpacing.field,
  });

  final List<Widget> fields;
  final double maxFieldWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;
      final columns = maxWidth <= 0
          ? 1
          : ((maxWidth + spacing) / (maxFieldWidth + spacing))
                .floor()
                .clamp(1, 3);
      final fieldWidth = (maxWidth - (columns - 1) * spacing) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final field in fields)
            SizedBox(
              width: field is IrrigationLabeledField ||
                      field is IrrigationNumberField ||
                      field is IrrigationSelectField
                  ? fieldWidth
                  : maxWidth,
              child: field,
            ),
        ],
      );
    },
  );
}

/// Barra de navegação comum dos wizards de projeto de irrigação.
class IrrigationStepNavigation extends StatelessWidget {
  const IrrigationStepNavigation({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.isConfirmed,
    required this.isBusy,
    required this.canCalculate,
    required this.onPrevious,
    required this.onConfirm,
    required this.onNext,
    required this.onCalculate,
    this.nextLabel = 'Próximo',
    this.calculateLabel = 'Calcular projeto',
    this.busyLabel = 'Calculando…',
    this.nextTooltip,
    this.calculateTooltip,
    this.calculateIcon = AppIcons.executarSimulacao,
  });

  final bool isFirst;
  final bool isLast;
  final bool isConfirmed;
  final bool isBusy;
  final bool canCalculate;
  final String nextLabel;
  final String calculateLabel;
  final String busyLabel;
  final String? nextTooltip;
  final String? calculateTooltip;
  final IconData calculateIcon;
  final VoidCallback onPrevious;
  final VoidCallback onConfirm;
  final VoidCallback onNext;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final previous = isFirst
        ? null
        : OutlinedButton.icon(
            onPressed: onPrevious,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Voltar'),
          );
    final confirm = isConfirmed
        ? Chip(
            avatar: Icon(Icons.check_rounded, size: 16, color: colors.primary),
            label: const Text('Confirmada'),
            backgroundColor: colors.primaryContainer,
            side: BorderSide.none,
          )
        : OutlinedButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Confirmar'),
          );
    final advance = isLast
        ? FilledButton.icon(
            onPressed: isBusy || !canCalculate ? null : onCalculate,
            icon: isBusy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(calculateIcon),
            label: Text(isBusy ? busyLabel : calculateLabel),
          )
        : FilledButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(nextLabel),
          );
    final advanced = isLast && calculateTooltip != null
        ? Tooltip(message: calculateTooltip!, child: advance)
        : !isLast && nextTooltip != null
        ? Tooltip(message: nextTooltip!, child: advance)
        : advance;
    final actions = Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [if (!isLast) confirm, advanced],
    );

    if (previous == null) {
      return Align(alignment: Alignment.centerRight, child: actions);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 420) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              previous,
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: actions,
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            previous,
            const SizedBox(height: IrrigationSpacing.compact),
            Align(alignment: Alignment.centerRight, child: actions),
          ],
        );
      },
    );
  }
}
