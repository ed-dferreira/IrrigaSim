import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_forms.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_input_fields.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_project_components.dart';
import 'package:irrigasim/shared/irrigacao/services/lamina_requerida.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';

// ──────────────────────── Navigation Buttons ────────────────────────

class StepNavigationButtons extends StatelessWidget {
  const StepNavigationButtons({
    super.key,
    required this.currentStep,
    required this.isFirst,
    required this.isLast,
    required this.executando,
    required this.isConfirmed,
    required this.canCalculate,
    required this.onPrevious,
    required this.onNext,
    required this.onConfirm,
    required this.onCalculate,
  });

  final int currentStep;
  final bool isFirst;
  final bool isLast;
  final bool executando;
  final bool isConfirmed;
  final bool canCalculate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onConfirm;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) => IrrigationStepNavigation(
    isFirst: isFirst,
    isLast: isLast,
    isConfirmed: isConfirmed,
    isBusy: executando,
    canCalculate: canCalculate,
    onPrevious: onPrevious,
    onConfirm: onConfirm,
    onNext: onNext,
    onCalculate: onCalculate,
  );
}

// ──────────────────────── Shared BentoCard ────────────────────────

class StepBentoCard extends StatelessWidget {
  const StepBentoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.child,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) => IrrigationProjectStepCard(
    title: title,
    subtitle: subtitle,
    icon: icon,
    accent: accent,
    child: child,
  );
}

// ──────────────────────── Shared Field ────────────────────────

class StepField extends ConsumerWidget {
  const StepField({
    super.key,
    required this.name,
    required this.label,
    required this.value,
    this.suffix,
    this.helper,
    this.allowZero = false,
    this.optional = false,
  });
  final String name;
  final String label;
  final double? value;
  final String? suffix;
  final String? helper;
  final bool allowZero;
  final bool optional;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IrrigationNumberField(
    label: label,
    value: value,
    unit: suffix,
    helper: helper,
    allowZero: allowZero,
    optional: optional,
    fieldKey: ValueKey(name),
    onChanged: (text) => ref
        .read(provedorParametrosSulco.notifier)
        .atualizarCampo(campo: name, valor: text),
    validator: (text) {
      if (optional && (text == null || text.trim().isEmpty)) {
        return null;
      }
      final number = double.tryParse((text ?? '').replaceAll(',', '.'));
      if (number == null) return 'Informe um número válido';
      if (allowZero ? number < 0 : number <= 0) {
        return allowZero
            ? 'Use zero ou um valor positivo'
            : 'Use um valor maior que zero';
      }
      if ((name == 'a' || name == 'kc') && number > 1.4) {
        return 'O valor máximo é 1,4';
      }
      if (name == 'periodoIrrigacaoDias' &&
          number != number.truncateToDouble()) {
        return 'Informe o período como número inteiro de dias';
      }
      return null;
    },
  );
}

class StepStringField extends ConsumerWidget {
  const StepStringField({
    super.key,
    required this.name,
    required this.label,
    required this.value,
    this.helper,
  });
  final String name;
  final String label;
  final String value;
  final String? helper;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IrrigationLabeledField(
    label: label,
    child: TextFormField(
      initialValue: value,
      decoration: InputDecoration(helperText: helper),
      onChanged: (text) =>
          ref.read(provedorParametrosSulco.notifier).definirNomeCultura(text),
    ),
  );
}

class StepFieldGrid extends StatelessWidget {
  const StepFieldGrid({super.key, required this.fields, required this.wide});
  final List<Widget> fields;
  final bool wide;

  @override
  Widget build(BuildContext context) => IrrigationFieldGrid(fields: fields);
}

class LaminaRequeridaCard extends StatelessWidget {
  const LaminaRequeridaCard({
    super.key,
    required this.resultado,
    required this.areaHectares,
  });

  final LaminaRequeridaResultado? resultado;
  final double areaHectares;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final res = resultado;
    if (res == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'Informe uma demanda líquida positiva e dados válidos do solo para calcular a IRN.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    final volumeM3 = res.irnMm * areaHectares * 10;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'Lâmina requerida (IRN): ${res.irnMm.toStringAsFixed(1)} mm\n'
        'Volume líquido estimado para ${areaHectares.toStringAsFixed(2)} ha: '
        '${volumeM3.toStringAsFixed(0)} m³\n'
        'Demanda líquida: ${res.demandaLiquidaMmDia.toStringAsFixed(1)} mm/dia\n'
        'Turno de rega: ${res.turnoCalculadoDias.toStringAsFixed(1)} dias '
        '(operacional: ${res.turnoOperacionalDias} dias)',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class OptionalNumericCurveField extends ConsumerWidget {
  const OptionalNumericCurveField({
    super.key,
    required this.label,
    required this.value,
    required this.name,
  });
  final String label;
  final double? value;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: IrrigationLabeledField(
      label: label,
      child: TextFormField(
        key: ValueKey(name),
        initialValue: value?.toString() ?? '',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(),
        onChanged: (text) => ref
            .read(provedorParametrosSulco.notifier)
            .atualizarCampo(campo: name, valor: text),
      ),
    ),
  );
}

// ──────────────────────── Helpers ────────────────────────
