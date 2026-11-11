import 'package:flutter/material.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/projeto_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_project/basin_project_fields.dart';
import 'package:irrigasim/shared/cultura/models/crop_presets.dart';
import 'package:irrigasim/shared/cultura/widgets/cultura_step_form.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';

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
  final permanente = project.regime == TipoInundacao.permanente;
  return [
    CulturaStepForm(
      introducao:
          'A cultura e o sistema radicular definem a demanda hídrica e, no '
          'intermitente, a lâmina requerida (IRN). Os presets preenchem Kc, '
          'raízes e fração; os dados de solo (UCC, UPMP e Ds) continuam seus.',
      nomeCultura: project.culturaEfetiva,
      presetInicial: _selectedCropPreset(project),
      kc: agronomia?.kc,
      profundidadeRaizesCm: agronomia?.profundidadeRaizesCm,
      fracaoDisponivel: agronomia?.fracaoDisponivel,
      revision: cropPresetRevision,
      // Arroz inundado não usa espaçamento de plantio.
      mostrarEspacamentos: false,
      onPresetSelecionado: (preset) {
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
      onCampoAlterado: (campo, texto) {
        fields.unconfirm();
        fields.controller.setAgronomia(campo, texto);
      },
      onNomeAlterado: (texto) {
        fields.unconfirm();
        fields.controller.setCultura(texto);
      },
      extraFields: [
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
        if (permanente) ...[
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
        ],
      ],
      footer: permanente ? _turnoRegaPermanenteCard(fields, project) : null,
    ),
  ];
}

CropPreset? _selectedCropPreset(ProjetoInundacao project) {
  final agronomia = project.agronomia;
  if (agronomia == null) return null;
  // Espaçamentos não participam: a inundação não os utiliza.
  return selectedCropPreset(
    cultura: project.culturaEfetiva,
    kc: agronomia.kc,
    roots: agronomia.profundidadeRaizesCm,
    fraction: agronomia.fracaoDisponivel,
  );
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
