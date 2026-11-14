import 'package:material_ui/material_ui.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_projeto.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_medicoes.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_project/border_project_fields.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_forms.dart';

/// Etapa 1: levantamento topográfico.
List<Widget> areaStep(
  BorderProjectFields fields,
  BorderProject p,
  String? erroPerfil,
) => [
  fields.number(
    'comprimentoAreaM',
    'Comprimento da área',
    p.comprimentoAreaM,
    'm',
  ),
  fields.number('larguraAreaM', 'Largura da área bruta', p.larguraAreaM, 'm'),
  fields.number(
    'areaUtilM2',
    'Área útil irrigável (opcional)',
    p.areaUtilM2,
    'm²',
    optional: true,
  ),
  IrrigationLabeledField(
    label: 'Orientação da área (opcional)',
    child: TextFormField(
      initialValue: p.orientacaoArea,
      decoration: const InputDecoration(
        hintText: 'Ex.: Norte–Sul; sentido do avanço',
      ),
      onChanged: (value) {
        fields.controller.setOrientacaoArea(value);
        fields.unconfirm();
      },
    ),
  ),
  fields.number(
    'desnivelLongitudinalM',
    'Desnível longitudinal',
    p.desnivelLongitudinalM,
    'm',
    zero: true,
  ),
  fields.number(
    'baseLongitudinalM',
    'Distância medida no sentido longitudinal',
    p.baseLongitudinalM,
    'm',
  ),
  TextFormField(
    key: const ValueKey('perfilLongitudinal'),
    initialValue: p.perfilLongitudinal
        .map((point) => '${point.xM};${point.cotaM}')
        .join('\n'),
    maxLines: 4,
    decoration: InputDecoration(
      labelText: 'Perfil longitudinal levantado (opcional)',
      helperText: 'Uma estaca por linha: distância m;cota m. Inclua 0 e o comprimento total. Perfil variável/terminal plano fica registrado, mas requer motor por trechos.',
      errorText: erroPerfil,
    ),
    onChanged: (text) {
      try {
        final points = text.trim().isEmpty
            ? <BorderTerrainPoint>[]
            : text.trim().split('\n').map((line) {
                final values = line
                    .split(';')
                    .map(
                      (value) =>
                          double.parse(value.trim().replaceAll(',', '.')),
                    )
                    .toList();
                if (values.length != 2 ||
                    values.any((value) => !value.isFinite)) {
                  throw const FormatException(
                    'Use distância;cota, ambas em metros.',
                  );
                }
                return BorderTerrainPoint(values[0], values[1]);
              }).toList();
        fields.controller.setPerfilLongitudinal(points);
        fields.setErroPerfil(null);
      } on FormatException catch (error) {
        fields.setErroPerfil(error.message);
      }
    },
  ),
  fields.number(
    'desnivelTransversalM',
    'Desnível transversal',
    p.desnivelTransversalM,
    'm',
    zero: true,
  ),
  fields.number(
    'baseTransversalM',
    'Distância medida no sentido transversal',
    p.baseTransversalM,
    'm',
  ),
  IrrigationFormulaCard(
    formula:
        'S0 = ${fields.format(p.declividadeLongitudinal)} m/m · St = ${fields.format(p.declividadeTransversal)} m/m',
    description: 'Declividades longitudinal e transversal calculadas a partir do levantamento.',
  ),
];
