import 'package:flutter/material.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_projeto.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_project/border_project_fields.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';

/// Etapa 5: clima, evapotranspiração e lâmina requerida.
List<Widget> climaStep(BorderProjectFields fields, BorderProject p) => [
  const Text(
    'A demanda da cultura e a precipitação efetiva definem a lâmina necessária. Use IRN informada ou calcule com os dados de solo e raízes.',
  ),
  fields.number(
    'evapotranspiracaoMmDia',
    'Evapotranspiração da cultura (ETc)',
    p.agronomia?.evapotranspiracaoMmDia,
    'mm/dia',
    optional: true,
  ),
  fields.number(
    'precipitacaoEfetivaMmDia',
    'Precipitação efetiva',
    p.agronomia?.precipitacaoEfetivaMmDia,
    'mm/dia',
    optional: true,
    zero: true,
  ),
  fields.select<OrigemIrnFaixa>(
    'Origem da IRN',
    p.origemIrn,
    OrigemIrnFaixa.values,
    fields.controller.setOrigemIrn,
    (v) => v == OrigemIrnFaixa.informada
        ? 'Informada'
        : 'Calculada a partir de solo, raízes e demanda climática',
  ),
  if (p.origemIrn == OrigemIrnFaixa.informada)
    fields.number('irnMm', 'Irrigação real necessária (IRN)', p.irnMm, 'mm')
  else
    IrrigationFormulaCard(
      formula: 'IRN calculada: ${fields.format(p.irnEfetivaMm)} mm',
      description: 'Lâmina necessária calculada com os dados de solo, raízes e demanda.',
    ),
];
