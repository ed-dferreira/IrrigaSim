import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/projeto_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/nucleo_referencia_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/viewmodels/basin_project_controller.dart';
import 'package:irrigasim/shared/irrigacao/services/formatacao_numerica.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_input_fields.dart';

/// Helpers de formulário do projeto de inundação: campo numérico, seletor,
/// linha de revisão e formatação. Centraliza as mensagens específicas da
/// feature ('Informe …', 'Maior que zero.', 'Máximo 1.' etc.) e cálculos
/// derivados do regime contínuo usados pelas etapas.
class BasinProjectFields {
  BasinProjectFields({required this.ref, required this.unconfirm});

  final WidgetRef ref;
  /// Limpa a confirmação da etapa atual (chamado em qualquer edição).
  final VoidCallback unconfirm;

  /// Controller do projeto de inundação (persistência via Riverpod).
  BasinProjectController get controller =>
      ref.read(basinProjectProvider.notifier);

  /// Campo numérico com a validação histórica da tela, preservada verbatim
  /// (a ordem das checagens define qual mensagem vence).
  Widget number(
    String field,
    String label,
    double? value,
    String unit, {
    bool optional = false,
    bool zero = false,
    String? key,
  }) => IrrigationNumberField(
    label: label,
    value: value,
    unit: unit,
    optional: optional,
    helper: optional ? 'Opcional' : null,
    initialText: value == null ? '' : value.toString().replaceAll('.', ','),
    fieldKey: ValueKey(key ?? field),
    onChanged: (texto) {
      controller.setNumero(field, texto);
      unconfirm();
    },
    validator: (texto) {
      if (texto == null || texto.trim().isEmpty) {
        return optional ? null : 'Informe $label.';
      }
      final parsed = double.tryParse(texto.replaceAll(',', '.'));
      if (parsed == null || !parsed.isFinite) return 'Valor inválido.';
      if (zero ? parsed < 0 : parsed <= 0) {
        return zero ? 'Não aceite valores negativos.' : 'Maior que zero.';
      }
      if (field == 'a' && parsed >= 1) return 'Exige 0 < a < 1.';
      if (field == 'porosidade' && parsed > 1) return 'Máximo 1.';
      if (field == 'fatorDisponibilidade' && parsed > 1) return 'Máximo 1.';
      if (field == 'umidadeGraos' && parsed > 1) return 'Máximo 1.';
      if (field == 'indiceColheita' && parsed > 1) return 'Máximo 1.';
      if (field == 'fracaoDisponivel' && parsed > 1) return 'Máximo 1.';
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
    onChanged: (option) {
      unconfirm();
      onChanged(option);
    },
  );

  Widget review(String label, String value, {String? pagina}) =>
      IrrigationAuditRow(label, value, pagina: pagina);

  /// Formatação da tela: 4 casas por padrão, sem zeros finais e '—' para
  /// valores ausentes.
  String format(double? value, {int casas = 4}) =>
      formatarNumero(value, casas: casas, removerZerosFinais: true);
}

/// Turno de rega TR do regime contínuo (p. 67); null se faltar entrada.
double? turnoRegaPermanente(ProjetoInundacao project) {
  final dtaMmCm = project.dtaMmCm;
  final fator = project.fatorDisponibilidade;
  final zMm = project.profundidadeCamadaMm;
  final etMmDia = project.etcMmDia;
  if (dtaMmCm == null || fator == null || zMm == null || etMmDia == null) {
    return null;
  }
  try {
    return turnoRega(dtaMmCm, fator, zMm / 10, etMmDia);
  } on ArgumentError {
    return null;
  }
}

/// Vazões Qe (enchimento) e Qm (manutenção) do regime contínuo (p. 67);
/// null quando o projeto ainda está incompleto.
ResultadoContinua? fluxoPermanente(ProjetoInundacao project) {
  final porosidade = project.porosidade;
  final zMm = project.profundidadeCamadaMm;
  final laminaMm = project.laminaSuperficialMm;
  final etMmDia = project.etcMmDia;
  final kMmDia = project.condutividadeHidraulicaMmDia;
  final areaHa = project.areaHectares;
  if (porosidade == null ||
      zMm == null ||
      laminaMm == null ||
      etMmDia == null ||
      kMmDia == null ||
      areaHa == null) {
    return null;
  }
  final tr = turnoRegaPermanente(project);
  if (tr == null) return null;
  try {
    return continua(
      porosidade: porosidade,
      zMm: zMm,
      laminaMm: laminaMm,
      etMmDia: etMmDia,
      kMmDia: kMmDia,
      areaHa: areaHa,
      turnoDias: tr < 1 ? 1.0 : tr,
    );
  } on ArgumentError {
    return null;
  } on StateError {
    return null;
  }
}
