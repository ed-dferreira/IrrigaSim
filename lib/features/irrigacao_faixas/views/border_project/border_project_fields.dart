import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_projeto.dart';
import 'package:irrigasim/features/irrigacao_faixas/viewmodels/border_project_controller.dart';
import 'package:irrigasim/shared/irrigacao/services/formatacao_numerica.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_input_fields.dart';

/// Helpers de formulário do projeto de faixas: campo numérico, seletor,
/// linha de revisão e formatação. Centraliza as mensagens de validação
/// específicas da feature.
class BorderProjectFields {
  BorderProjectFields({
    required this.ref,
    required this.unconfirm,
    required this.setState,
    required this.setErroPerfil,
    required this.setErroEstacas,
    required this.setDiametroBooherCm,
    required this.setCargaBooherCm,
    required this.revisarPredefinicaoCultura,
  });

  final WidgetRef ref;
  /// Limpa a confirmação da etapa atual (chamado em qualquer edição).
  final VoidCallback unconfirm;
  /// Reexecuta o `setState` do orquestrador (etapas com estado próprio).
  final ValueChanged<VoidCallback> setState;
  /// Persiste o erro do perfil longitudinal (null limpa e desconfirma).
  final ValueChanged<String?> setErroPerfil;
  /// Persiste o erro das estacas (null limpa e desconfirma).
  final ValueChanged<String?> setErroEstacas;
  final ValueChanged<double> setDiametroBooherCm;
  final ValueChanged<double> setCargaBooherCm;
  /// Incrementa a revisão das predefinições de cultura (rebuild dos campos).
  final VoidCallback revisarPredefinicaoCultura;

  BorderProjectController get controller =>
      ref.read(borderProjectProvider.notifier);

  BorderProject get project => ref.read(borderProjectProvider);

  Widget number(
    String field,
    String label,
    double? value,
    String unit, {
    bool optional = false,
    bool zero = false,
    int? resetKey,
  }) => IrrigationNumberField(
    label: label,
    value: value,
    unit: unit.isEmpty ? null : unit,
    optional: optional,
    helper: optional ? 'Opcional; vazio = não informado' : null,
    fieldKey: ValueKey(resetKey == null ? field : '$field-$resetKey'),
    onChanged: (v) {
      controller.setNumero(field, v);
      unconfirm();
    },
    validator: (v) {
      if (optional && (v == null || v.trim().isEmpty)) return null;
      final n = double.tryParse((v ?? '').replaceAll(',', '.'));
      if (n == null || !n.isFinite) return 'Informe um número válido';
      if (zero ? n < 0 : n <= 0) {
        return zero ? 'Use zero ou valor positivo' : 'Use valor positivo';
      }
      if (field == 'a' && n >= 1) return 'O expoente deve ser menor que 1';
      if (field == 'fracaoDisponivel' && n > 1) return 'Use fração até 1';
      if ((field == 'periodoDias' || field == 'faixasSimultaneas') &&
          n != n.roundToDouble()) {
        return 'Informe um número inteiro';
      }
      return null;
    },
  );

  Widget select<T>(
    String label,
    T value,
    List<T> options,
    ValueChanged<T> onChanged,
    String Function(T) title,
  ) => IrrigationSelectField<T>(
    label: label,
    value: value,
    options: options,
    labelFor: title,
    onChanged: (v) {
      onChanged(v);
      unconfirm();
    },
  );

  Widget review(String label, String value) => IrrigationAuditRow(label, value);

  /// Formatação da feature: números minúsculos (declives) ganham 6 casas.
  String format(double? n) => n == null
      ? '—'
      : n.abs() < .001 && n != 0
      ? formatarNumero(n, casas: 6)
      : formatarNumero(n, casas: 3);
}
