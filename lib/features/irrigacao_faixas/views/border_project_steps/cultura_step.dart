import 'package:flutter/material.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_project/border_project_fields.dart';
import 'package:irrigasim/shared/cultura/models/crop_presets.dart';
import 'package:irrigasim/shared/cultura/widgets/cultura_step_form.dart';

/// Etapa 4: cultura e sistema radicular (com predefinições).
List<Widget> culturaStep(
  BuildContext context,
  BorderProjectFields fields,
  CropPreset? predefinicaoSelecionada,
  String? cultura,
  int cropPresetRevision,
) => [
  CulturaStepForm(
    nomeCultura: cultura,
    presetInicial: predefinicaoSelecionada,
    kc: fields.project.agronomia?.kc,
    espacamentoFileirasM: fields.project.agronomia?.espacamentoFileirasM,
    espacamentoPlantasM: fields.project.agronomia?.espacamentoPlantasM,
    profundidadeRaizesCm: fields.project.agronomia?.profundidadeRaizesCm,
    fracaoDisponivel: fields.project.agronomia?.fracaoAguaDisponivel,
    revision: cropPresetRevision,
    onPresetSelecionado: (preset) {
      final controller = fields.controller;
      controller.setCultura(preset.name);
      for (final value in {
        'kc': preset.kc,
        'espacamentoFileirasM': preset.rows,
        'espacamentoPlantasM': preset.plants,
        'profundidadeRaizesCm': preset.roots,
        'fracaoDisponivel': preset.fraction,
      }.entries) {
        controller.setNumero(value.key, value.value.toString());
      }
      fields.revisarPredefinicaoCultura();
    },
    onCampoAlterado: (campo, texto) {
      fields.controller.setNumero(campo, texto);
      fields.unconfirm();
    },
    onNomeAlterado: (texto) {
      fields.controller.setCultura(texto);
      fields.unconfirm();
    },
  ),
];
