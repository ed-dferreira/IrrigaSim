import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:irrigasim/shared/irrigacao/services/formatacao_numerica.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_forms.dart';

/// Campo numérico comum às telas de projeto de irrigação.
///
/// Formata o valor inicial uma única vez (quando [fieldKey] muda, o campo
/// reconstrói); a validação fica por conta de [validator], preservando as
/// mensagens específicas de cada feature.
class IrrigationNumberField extends StatelessWidget {
  const IrrigationNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.unit,
    this.optional = false,
    this.allowZero = false,
    this.helper,
    this.validator,
    this.fieldKey,
    this.initialText,
  });

  final String label;
  final double? value;
  final String? unit;
  final bool optional;
  final bool allowZero;
  final String? helper;
  final String? Function(String?)? validator;
  final ValueChanged<String> onChanged;
  final Key? fieldKey;

  /// Texto inicial alternativo; quando nulo, o campo usa [value] formatado
  /// por [formatarNumero] (casas: 6, sem zeros finais).
  final String? initialText;

  @override
  Widget build(BuildContext context) => IrrigationLabeledField(
    label: label,
    child: TextFormField(
      key: fieldKey,
      initialValue: initialText ??
          (value == null
              ? ''
              : formatarNumero(value!, casas: 6, removerZerosFinais: true)),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.-]'))],
      decoration: InputDecoration(suffixText: unit, helperText: helper),
      onChanged: onChanged,
      validator: validator,
    ),
  );
}

/// Seletor comum às telas de projeto de irrigação.
class IrrigationSelectField<T> extends StatelessWidget {
  const IrrigationSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.labelFor,
    required this.onChanged,
    this.expanded = true,
  });

  final String label;
  final T value;
  final List<T> options;
  final String Function(T) labelFor;
  final ValueChanged<T> onChanged;
  final bool expanded;

  @override
  Widget build(BuildContext context) => IrrigationLabeledField(
    label: label,
    child: DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: expanded,
      items: [
        for (final option in options)
          DropdownMenuItem<T>(
            value: option,
            child: Text(
              labelFor(option),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (option) {
        if (option == null) return;
        onChanged(option);
      },
    ),
  );
}
