import 'package:flutter/material.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/projeto_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_project/basin_project_fields.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/crop_presets.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_forms.dart';

/// Etapa 5: cultura e sistema radicular (Fase 3) — presets de cultura,
/// insumos de solo/raízes da IRN e, no permanente, os campos de camada
/// movidos da etapa de solo (G15).
List<Widget> culturaStep(
  BuildContext context,
  BasinProjectFields fields,
  ProjetoInundacao project, {
  required int cropPresetRevision,
  required VoidCallback revisarCropPreset,
}) {
  final agronomia = project.agronomia;
  return [
    const Text(
      'A cultura e o sistema radicular definem a demanda hídrica e, no '
      'intermitente, a lâmina requerida (IRN). Os presets preenchem Kc, '
      'raízes e fração; os dados de solo (UCC, UPMP e Ds) continuam seus.',
    ),
    IrrigationLabeledField(
      label: 'Predefinição de cultura',
      child: DropdownButtonFormField<CropPreset?>(
        key: ValueKey('basin-crop-preset-$cropPresetRevision'),
        isExpanded: true,
        initialValue: _selectedCropPreset(project),
        decoration: const InputDecoration(
          helperText:
              'Selecione uma cultura para preencher os parâmetros; eles '
              'podem ser ajustados depois.',
        ),
        items: [
          const DropdownMenuItem<CropPreset?>(
            value: null,
            child: Text(
              'Personalizada / sem predefinição',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          ...cropPresets.map(
            (preset) => DropdownMenuItem<CropPreset?>(
              value: preset,
              child: Text(
                preset.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
        onChanged: (preset) {
          if (preset == null) return;
          final controller = fields.controller;
          for (final entry in {
            'kc': preset.kc,
            'profundidadeRaizesCm': preset.roots,
            'fracaoDisponivel': preset.fraction,
          }.entries) {
            controller.setAgronomia(entry.key, entry.value.toString());
          }
          controller.setCultura(preset.name);
          revisarCropPreset();
        },
      ),
    ),
    IrrigationLabeledField(
      label: 'Nome da cultura (opcional)',
      child: TextFormField(
        key: ValueKey('basin-crop-name-$cropPresetRevision'),
        initialValue: project.culturaEfetiva ?? '',
        decoration: const InputDecoration(helperText: 'Opcional'),
        onChanged: (value) {
          fields.unconfirm();
          fields.controller.setCultura(value);
        },
      ),
    ),
    fields.number(
      'kc',
      'Coeficiente da cultura (Kc)',
      agronomia?.kc,
      '—',
      key: 'kc-$cropPresetRevision',
    ),
    fields.number(
      'profundidadeRaizesCm',
      'Profundidade do sistema radicular (z)',
      agronomia?.profundidadeRaizesCm,
      'cm',
      key: 'raiz-$cropPresetRevision',
    ),
    fields.number(
      'fracaoDisponivel',
      'Fração de água disponível (f)',
      agronomia?.fracaoDisponivel,
      '0–1',
      key: 'fracao-$cropPresetRevision',
    ),
    fields.number(
      'uccPercentual',
      'Umidade na capacidade de campo (UCC)',
      agronomia?.uccPercentual,
      '%',
      optional: true,
    ),
    fields.number(
      'upmpPercentual',
      'Umidade no ponto de murcha permanente (UPMP)',
      agronomia?.upmpPercentual,
      '%',
      optional: true,
    ),
    fields.number(
      'densidadeGcm3',
      'Densidade aparente do solo (Ds)',
      agronomia?.densidadeGcm3,
      'g/cm³',
      optional: true,
    ),
    if (project.regime == TipoInundacao.permanente) ...[
      const Text(
        'Camadas e turno do regime contínuo: porosidade, profundidade '
        'da camada, DTA, fator de disponibilidade e K0 sustentam o turno '
        'de rega (TR) e as vazões Qe e Qm.',
      ),
      fields.number('porosidade', 'Porosidade', project.porosidade, '0–1'),
      fields.number(
        'profundidadeCamadaMm',
        'Profundidade da camada (Z)',
        project.profundidadeCamadaMm,
        'mm',
      ),
      fields.number(
        'dtaMmCm',
        'Disponibilidade total de água (DTA)',
        project.dtaMmCm,
        'mm/cm',
      ),
      fields.number(
        'fatorDisponibilidade',
        'Fator de disponibilidade (f)',
        project.fatorDisponibilidade,
        '0–1',
      ),
      fields.number(
        'condutividadeHidraulicaMmDia',
        'Condutividade hidráulica K0',
        project.condutividadeHidraulicaMmDia,
        'mm/dia',
      ),
      _turnoRegaPermanenteCard(fields, project),
    ],
  ];
}

CropPreset? _selectedCropPreset(ProjetoInundacao project) {
  final agronomia = project.agronomia;
  if (agronomia == null) return null;
  for (final preset in cropPresets) {
    if (preset.name == project.culturaEfetiva &&
        preset.kc == agronomia.kc &&
        preset.roots == agronomia.profundidadeRaizesCm &&
        preset.fraction == agronomia.fracaoDisponivel) {
      return preset;
    }
  }
  return null;
}

/// Card derivado do turno de rega contínuo (G15; p. 73), com o valor vivo
/// quando DTA, Z, f e ETc estão completos.
Widget _turnoRegaPermanenteCard(
  BasinProjectFields fields,
  ProjetoInundacao project,
) {
  final tr = turnoRegaPermanente(project);
  return IrrigationFormulaCard(
    formula: tr == null
        ? null
        : 'TR = ${fields.format(tr, casas: 1)} dias',
    description:
        'Turno de rega do regime contínuo; Qe e Qm saem do fator 0,116 '
        'com a ETc da etapa de clima.',
  );
}
