import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final children = <Widget>[
      if (!isFirst)
        OutlinedButton.icon(
          onPressed: onPrevious,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Voltar'),
        ),
      if (!isLast)
        isConfirmed
            ? Chip(
                avatar: Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: colors.primary,
                ),
                label: const Text('Confirmada'),
                backgroundColor: colors.primaryContainer,
                side: BorderSide.none,
              )
            : OutlinedButton.icon(
                onPressed: onConfirm,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Confirmar'),
              ),
      if (!isLast)
        FilledButton.icon(
          onPressed: onNext,
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text('Próximo'),
        )
      else
        FilledButton.icon(
          onPressed: executando || !canCalculate ? null : onCalculate,
          icon: executando
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(AppIcons.executarSimulacao),
          label: Text(executando ? 'Calculando…' : 'Calcular projeto'),
        ),
    ];
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 8,
      runSpacing: 8,
      children: children,
    );
  }
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
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 6),
      TextFormField(
        initialValue: value == null ? '' : _format(value!),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.-]')),
        ],
        decoration: InputDecoration(suffixText: suffix, helperText: helper),
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
      ),
    ],
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
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 6),
      TextFormField(
        initialValue: value,
        decoration: InputDecoration(helperText: helper),
        onChanged: (text) =>
            ref.read(provedorParametrosSulco.notifier).definirNomeCultura(text),
      ),
    ],
  );
}

class StepFieldGrid extends StatelessWidget {
  const StepFieldGrid({super.key, required this.fields, required this.wide});
  final List<Widget> fields;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return Column(
        children: fields
            .map(
              (e) =>
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: e),
            )
            .toList(),
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: fields.map((e) => SizedBox(width: 300, child: e)).toList(),
    );
  }
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
    child: TextFormField(
      key: ValueKey(name),
      initialValue: value?.toString() ?? '',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      onChanged: (text) => ref
          .read(provedorParametrosSulco.notifier)
          .atualizarCampo(campo: name, valor: text),
    ),
  );
}

// ──────────────────────── Helpers ────────────────────────

String _format(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
