import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:irrigasim/core/widgets/calculated_field.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/projeto_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/nucleo_referencia_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_project/basin_project_fields.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_forms.dart';

/// Etapa 4: solo e infiltração — variante intermitente com o cenário
/// k/a/VIB dos testes de irrigação (p. 53) e campo calculado I(t).
List<Widget> soloIntermitenteStep(
  BuildContext context,
  BasinProjectFields fields,
  ProjetoInundacao project, {
  required int presetRevision,
  required double tempoInfiltracaoMin,
  required ValueChanged<double> onTempoInfiltracaoChanged,
}) => [
  const Text(
    'A infiltração controla o avanço e o tempo de contato. Os cenários '
    'da primeira e da terceira irrigação servem de referência, cada um '
    'com k, a e VIB próprios.',
  ),
  fields.select<CenarioInfiltracaoInundacao>(
    'Cenário de infiltração',
    project.cenarioInfiltracao,
    CenarioInfiltracaoInundacao.values,
    fields.controller.setCenarioInfiltracao,
    (value) => value.displayName,
  ),
  const Text(
    'O cenário identifica a origem dos coeficientes: k, a e VIB vêm da '
    'irrigação escolhida ou dos valores informados, sem misturar '
    'coeficientes entre irrigações.',
  ),
  fields.number(
    'k',
    'k da infiltração',
    project.k,
    'm/min^a',
    key: 'k-$presetRevision-${project.cenarioInfiltracao.name}',
  ),
  fields.number(
    'a',
    'Expoente a',
    project.a,
    '0 < a < 1',
    key: 'a-$presetRevision-${project.cenarioInfiltracao.name}',
  ),
  fields.number(
    'vibMMin',
    'VIB',
    project.vibMMin,
    'm/min',
    key: 'vib-$presetRevision-${project.cenarioInfiltracao.name}',
  ),
  ..._infiltracaoCalculadaFields(
    fields,
    project,
    tempoInfiltracaoMin: tempoInfiltracaoMin,
    onTempoInfiltracaoChanged: onTempoInfiltracaoChanged,
  ),
];

/// Campo calculado I(t) = (k · t^a + VIB · t) · 1000, com t em minutos.
List<Widget> _infiltracaoCalculadaFields(
  BasinProjectFields fields,
  ProjetoInundacao project, {
  required double tempoInfiltracaoMin,
  required ValueChanged<double> onTempoInfiltracaoChanged,
}) => [
  IrrigationLabeledField(
    label: 'Tempo de contato t',
    child: TextFormField(
      key: const ValueKey('tempoInfiltracaoMin'),
      initialValue: tempoInfiltracaoMin.toString().replaceAll('.', ','),
      decoration: const InputDecoration(
        suffixText: 'min',
        helperText: 'Tempo usado no cálculo de I(t)',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.-]')),
      ],
      validator: (texto) {
        if (texto == null || texto.trim().isEmpty) return 'Informe o tempo.';
        final parsed = double.tryParse(texto.replaceAll(',', '.'));
        if (parsed == null || !parsed.isFinite || parsed <= 0) {
          return 'Maior que zero.';
        }
        return null;
      },
      onChanged: (texto) {
        final parsed = double.tryParse(texto.replaceAll(',', '.'));
        if (parsed == null || !parsed.isFinite || parsed <= 0) return;
        onTempoInfiltracaoChanged(parsed);
      },
    ),
  ),
  if (_infiltracaoAcumuladaMm(project, tempoInfiltracaoMin) != null)
    CalculatedField(
      label: 'Infiltração acumulada I(t)',
      value: _infiltracaoAcumuladaMm(project, tempoInfiltracaoMin)!,
      suffix: 'mm',
    ),
];

double? _infiltracaoAcumuladaMm(
  ProjetoInundacao project,
  double tempoInfiltracaoMin,
) {
  final k = project.k;
  final a = project.a;
  final vib = project.vibMMin;
  final t = tempoInfiltracaoMin;
  if (k == null || a == null || vib == null || k <= 0 || vib < 0 || t <= 0) {
    return null;
  }
  if (!(a > 0 && a < 1)) return null;
  try {
    return Infiltracao(k, a, vib).acumulada(t) * 1000;
  } on ArgumentError {
    return null;
  }
}

/// Etapa 4 no regime permanente: só a lâmina superficial sustenta o turno
/// de rega; o cenário k/a/VIB é exclusivo do intermitente (p. 53).
List<Widget> soloPermanenteStep(
  BuildContext context,
  BasinProjectFields fields,
  ProjetoInundacao project,
) => [
  const Text(
    'No regime contínuo os dados do solo sustentam o turno de rega e as '
    'vazões Qe e Qm. O cenário de infiltração k/a/VIB vale só para o '
    'regime intermitente. Porosidade, camada, DTA, fator de '
    'disponibilidade e K0 ficam na etapa Cultura e sistema radicular.',
  ),
  fields.number(
    'laminaSuperficialMm',
    'Lâmina superficial',
    project.laminaSuperficialMm,
    'mm',
  ),
];
