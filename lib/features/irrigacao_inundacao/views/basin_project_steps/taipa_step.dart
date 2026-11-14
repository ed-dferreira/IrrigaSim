import 'package:material_ui/material_ui.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/projeto_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_project/basin_project_fields.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';

/// Etapa 3: tabuleiro, taipa e limites construtivos (base, altura, margem).
List<Widget> taipaStep(
  BuildContext context,
  BasinProjectFields fields,
  ProjetoInundacao project,
) => [
  fields.number('alturaDiqueM', 'Altura da taipa', project.alturaDiqueM, 'm'),
  fields.number('baseDiqueM', 'Base da taipa', project.baseDiqueM, 'm'),
  fields.number(
    'margemLivreM',
    'Margem livre acima da lâmina',
    project.margemLivreM,
    'm',
  ),
  const IrrigationFormulaCard(
    description:
        'A taipa precisa conter a profundidade normal com margem. '
        'Limites: base 0,60–1,80 m; altura 0,60–0,80 m; margem '
        '0,05–0,20 m.',
  ),
];
