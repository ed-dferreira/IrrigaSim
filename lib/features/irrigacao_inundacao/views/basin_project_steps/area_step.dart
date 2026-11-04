import 'package:flutter/material.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/projeto_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/tabelas_referencia_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_project/basin_project_fields.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';

/// Etapa 2: área, geometria do tabuleiro, textura e lâminas do regime
/// intermitente, com o guia orientativo de área × vazão (p. 16).
List<Widget> areaStep(
  BuildContext context,
  BasinProjectFields fields,
  ProjetoInundacao project,
) => [
  fields.number(
    'comprimentoAreaM',
    'Comprimento da área (L)',
    project.comprimentoAreaM,
    'm',
  ),
  fields.number('larguraAreaM', 'Largura da área', project.larguraAreaM, 'm'),
  fields.number(
    'areaUtilM2',
    'Área útil (opcional)',
    project.areaUtilM2,
    'm²',
    optional: true,
  ),
  if (project.regime == TipoInundacao.permanente)
    fields.number('areaHectares', 'Área irrigada', project.areaHectares, 'ha'),
  fields.number(
    'comprimentoM',
    'Comprimento do tabuleiro (L)',
    project.comprimentoM,
    'm',
  ),
  fields.number('larguraM', 'Largura do tabuleiro', project.larguraM, 'm'),
  fields.number(
    'declividade',
    'Declividade longitudinal (m/m)',
    project.declividade,
    'ex.: 0,0025 = 0,25%',
    zero: true,
  ),
  fields.select<TexturaSolo>(
    'Textura do solo',
    project.texturaSolo ?? TexturaSolo.media,
    TexturaSolo.values,
    fields.controller.setTexturaSolo,
    (value) => value.displayName,
  ),
  if (project.regime == TipoInundacao.intermitente) ...[
    fields.number(
      'laminaInicialMm',
      'Lâmina inicial Li (opcional)',
      project.laminaInicialMm,
      'mm',
      optional: true,
    ),
    fields.number(
      'laminaFinalMm',
      'Lâmina final Lf (opcional)',
      project.laminaFinalMm,
      'mm',
      optional: true,
    ),
  ],
  if (project.areaTabuleiroM2 != null)
    IrrigationFormulaCard(
      formula:
          'Área do tabuleiro = ${fields.format(project.comprimentoM)} × '
          '${fields.format(project.larguraM)} = '
          '${fields.format(project.areaTabuleiroM2)} m²',
      description: 'O tabuleiro precisa caber entre 1 m² e 5 ha.',
    ),
  if (project.laminaMediaPlanaltoM != null &&
      project.declividade != null) ...[
    IrrigationFormulaCard(
      formula:
          'Lm = ${fields.format(project.laminaMediaPlanaltoM! * 100)} cm · '
          'Δz admissível = 2/3 Lm = '
          '${fields.format((project.desnivelAdmissivelM ?? 0) * 100)} cm · '
          'Δz real = ${fields.format((project.desnivelRealM ?? 0) * 100)} cm',
      description:
          'Regra dos 2/3: o desnível real não pode superar 2/3 da '
          'lâmina média no planalto.',
    ),
    if (project.comprimentoMaximoDesnivelM != null)
      IrrigationFormulaCard(
        formula:
            'L máximo = (2/3 Lm) / S = '
            '${fields.format(project.comprimentoMaximoDesnivelM)} m',
        description:
            'Exemplos do material: 0,25% → 40 m; 0,05% → 200 m, pela '
            'direção avaliada.',
      ),
  ],
  ..._guiaAreaFields(fields, project),
];

/// Sugestão de área do guia da p. 16 para a textura e a vazão atuais.
List<Widget> _guiaAreaFields(BasinProjectFields fields, ProjetoInundacao project) {
  final vazao = project.vazaoAplicadaLs ?? project.vazaoDisponivelLps;
  final chave = _chaveGuiaSolo(project.texturaSolo);
  final sugerida = chave == null || vazao == null
      ? null
      : const TabelasReferencia().areaSugerida(chave, vazao);
  return [
    ExpansionTile(
      leading: const Icon(AppIcons.soloArgiloso),
      title: const Text('Sugestão de área × vazão'),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        if (sugerida != null)
          IrrigationFormulaCard(
            formula:
                'Textura ${project.texturaSolo?.displayName ?? '—'} → '
                '${fields.format(sugerida, casas: 2)} ha para '
                '${fields.format(vazao, casas: 1)} L/s',
            description:
                'Guia orientativo; não substitui o '
                'dimensionamento hidráulico.',
          ),
        for (final row in TabelasReferencia.guiaSolo)
          IrrigationAuditRow(
            row.rotulo,
            vazao == null
                ? '${row.areaHaBase} ha a 10 L/s'
                : '${fields.format(row.areaParaVazao(vazao), casas: 2)} ha a '
                      '${fields.format(vazao, casas: 1)} L/s',
            detail: 'Orientativo; não substitui o dimensionamento.',
            isWarning: true,
          ),
      ],
    ),
  ];
}

String? _chaveGuiaSolo(TexturaSolo? textura) => switch (textura) {
  TexturaSolo.muitoGrossa || TexturaSolo.grossa => 'arenoso',
  TexturaSolo.media => 'franco-arenoso',
  TexturaSolo.fina => 'franco-argiloso',
  TexturaSolo.muitoFina => 'argiloso',
  null => null,
};
