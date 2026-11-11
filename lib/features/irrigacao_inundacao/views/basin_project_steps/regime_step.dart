import 'package:flutter/material.dart';
import 'package:irrigasim/core/theme/app_icons.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/projeto_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_project/basin_project_fields.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_project_components.dart';

/// Etapa 1: escolha do regime intermitente ou permanente.
List<Widget> regimeStep(
  BuildContext context,
  BasinProjectFields fields,
  ProjetoInundacao project,
) => [
  SegmentedButton<TipoInundacao>(
    segments: const [
      ButtonSegment(
        value: TipoInundacao.intermitente,
        label: Text('Intermitente (sem circulação)'),
        icon: Icon(AppIcons.inundacao),
      ),
      ButtonSegment(
        value: TipoInundacao.permanente,
        label: Text('Permanente (com circulação)'),
        icon: Icon(AppIcons.inundacao),
      ),
    ],
    selected: {project.regime},
    onSelectionChanged: (selection) {
      fields.unconfirm();
      fields.controller.setRegime(selection.first);
    },
  ),
  const SizedBox(height: IrrigationSpacing.field),
  if (project.regime == TipoInundacao.intermitente)
    const Text(
      'Enchimento e esvaziamento de cada ciclo: a água entra, avança pelo '
      'tabuleiro e escoa na jusante.',
    )
  else
    const IrrigationFormulaCard(
      description:
          'Rega contínua com nível permanente: Qe forma a lâmina e Qm '
          'recompõe evapotranspiração e percolação.',
    ),
  const SizedBox(height: IrrigationSpacing.field),
];
