import 'package:flutter/material.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/crop_presets.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_project/border_project_fields.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_forms.dart';

/// Etapa 4: cultura e sistema radicular (com predefinições).
List<Widget> culturaStep(
  BuildContext context,
  BorderProjectFields fields,
  CropPreset? predefinicaoSelecionada,
  String? cultura,
  int cropPresetRevision,
) => [
  Card(
    margin: EdgeInsets.zero,
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Informações da cultura para estimativa de demanda hídrica.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          IrrigationLabeledField(
            label: 'Predefinição de cultura',
            child: DropdownButtonFormField<CropPreset?>(
              key: ValueKey('crop-preset-$cropPresetRevision'),
              isExpanded: true,
              initialValue: predefinicaoSelecionada,
              decoration: const InputDecoration(
                helperText: 'Selecione uma cultura para preencher os parâmetros; eles podem ser ajustados depois.',
              ),
              items: [
                const DropdownMenuItem<CropPreset?>(
                  value: null,
                  child: Text('Personalizada / sem predefinição'),
                ),
                ...cropPresets.map(
                  (preset) => DropdownMenuItem<CropPreset?>(
                    value: preset,
                    child: Text(preset.name),
                  ),
                ),
              ],
              onChanged: (preset) {
                if (preset == null) return;
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
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final fieldWidth = constraints.maxWidth >= 650
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: IrrigationLabeledField(
                      label: 'Nome da cultura',
                      child: TextFormField(
                        key: ValueKey('crop-name-$cropPresetRevision'),
                        initialValue: cultura ?? '',
                        onChanged: (value) {
                          fields.controller.setCultura(value);
                          fields.unconfirm();
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: fields.number(
                      'kc',
                      'Coeficiente da cultura (Kc)',
                      fields.project.agronomia?.kc,
                      '',
                      resetKey: cropPresetRevision,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: fields.number(
                      'espacamentoFileirasM',
                      'Espaçamento entre fileiras',
                      fields.project.agronomia?.espacamentoFileirasM,
                      'm',
                      resetKey: cropPresetRevision,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: fields.number(
                      'espacamentoPlantasM',
                      'Espaçamento entre plantas',
                      fields.project.agronomia?.espacamentoPlantasM,
                      'm',
                      resetKey: cropPresetRevision,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: fields.number(
                      'profundidadeRaizesCm',
                      'Profundidade das raízes',
                      fields.project.agronomia?.profundidadeRaizesCm,
                      'cm',
                      resetKey: cropPresetRevision,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: fields.number(
                      'fracaoDisponivel',
                      'Fração de água disponível',
                      fields.project.agronomia?.fracaoAguaDisponivel,
                      '',
                      resetKey: cropPresetRevision,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  ),
];
