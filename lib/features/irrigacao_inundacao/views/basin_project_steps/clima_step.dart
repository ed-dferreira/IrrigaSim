import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/core/widgets/calculated_field.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/projeto_inundacao.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_project/basin_project_fields.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/clima_demanda.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_forms.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_project_components.dart';

const _mesesNomes = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

/// Etapa 6 — Clima e demanda (Fase 3): método de ETc, origem da chuva,
/// origem da IRN (G14) e o card vivo de IRN/volume/TR; no permanente
/// mostra ETc/Pef/TR do contínuo e esconde a IRN intermitente (G8).
List<Widget> climaStep(
  BuildContext context,
  BasinProjectFields fields,
  ProjetoInundacao project,
) {
  final intermitente = project.regime == TipoInundacao.intermitente;
  return [
    const Text(
      'A demanda da cultura (ETc) e a precipitação efetiva alimentam o '
      'balanço e o turno de rega. Chuva '
      'registrada como provável não vira crédito de Pef.',
    ),
    Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final metodo in MetodoEtc.values)
          ChoiceChip(
            label: Text(switch (metodo) {
              MetodoEtc.adotada => 'ETc adotada',
              MetodoEtc.etoVezesKc => 'ETo × Kc',
              MetodoEtc.blaneyCriddle => 'Blaney–Criddle',
            }),
            selected: project.metodoEtc == metodo,
            onSelected: (_) {
              fields.unconfirm();
              fields.controller.setMetodoEtc(metodo);
            },
          ),
      ],
    ),
    const SizedBox(height: IrrigationSpacing.field),
    if (project.metodoEtc == MetodoEtc.adotada)
      intermitente
          ? fields.number(
              'etIntermitenteMmDia',
              'Evapotranspiração do intervalo (ETc)',
              project.etIntermitenteMmDia,
              'mm/dia',
            )
          : fields.number(
              'evapotranspiracaoMmDia',
              'Evapotranspiração (ETc)',
              project.evapotranspiracaoMmDia,
              'mm/dia',
            ),
    if (project.metodoEtc == MetodoEtc.etoVezesKc) ...[
      fields.number(
        'etoMmDia',
        'Evapotranspiração de referência (ETo)',
        project.etoMmDia,
        'mm/dia',
      ),
      if (project.etoMmDia != null && project.agronomia?.kc != null)
        CalculatedField(
          label: 'ETc estimada (ETo × Kc)',
          value: project.etcMmDia!,
          suffix: 'mm/dia',
          helper:
              'ETo ${fields.format(project.etoMmDia)} × '
              'Kc ${fields.format(project.agronomia?.kc)}.',
        )
      else
        Text(
          'Informe a ETo e o Kc da etapa Cultura para estimar a ETc.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
    ],
    if (project.metodoEtc == MetodoEtc.blaneyCriddle) ...[
      fields.number(
        'temperaturaMediaC',
        'Temperatura média do ar',
        project.temperaturaMediaC,
        '°C',
        optional: true,
        zero: true,
      ),
      _latitudeField(fields, project),
      _mesReferenciaField(fields, project),
      if (project.etoBlaneyCriddleMmDia != null)
        CalculatedField(
          label: 'ETo estimada (Blaney–Criddle)',
          value: project.etoBlaneyCriddleMmDia!,
          suffix: 'mm/dia',
          helper: project.agronomia?.kc == null
              ? 'Informe o Kc da etapa Cultura para obter a ETc.'
              : 'ETc (ETo × Kc) = ${fields.format(project.etcMmDia)} mm/dia.',
        )
      else
        Text(
          'Preencha temperatura, latitude e mês; a latitude fica entre '
          '−60° e 60° (negativa no hemisfério sul).',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
    ],
    fields.select<OrigemChuva>(
      'Origem da precipitação',
      project.origemChuva,
      OrigemChuva.values,
      fields.controller.setOrigemChuva,
      (value) => switch (value) {
        OrigemChuva.naoInformada => 'Não informada',
        OrigemChuva.efetiva => 'Efetiva adotada',
        OrigemChuva.observada => 'Efetiva observada',
        OrigemChuva.provavel => 'Provável (não é Pef)',
      },
    ),
    if (project.origemChuva == OrigemChuva.provavel)
      Text(
        'Chuva provável foi registrada, mas não pode ser subtraída da ETc '
        'como Pef sem um método explícito.',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.error),
      ),
    fields.number(
      'precipitacaoEfetivaMmDia',
      project.origemChuva == OrigemChuva.provavel
          ? 'Precipitação provável (não é Pef)'
          : 'Precipitação efetiva (Pef)',
      project.precipitacaoEfetivaMmDia,
      'mm/dia',
      optional: true,
      zero: true,
    ),
    if (intermitente) ...[
      fields.select<OrigemIrnInundacao>(
        'Origem da IRN',
        project.origemIrn,
        OrigemIrnInundacao.values,
        fields.controller.setOrigemIrn,
        (value) => value == OrigemIrnInundacao.informada
            ? 'Informada'
            : 'Calculada (solo, raízes e demanda)',
      ),
      if (project.origemIrn == OrigemIrnInundacao.informada)
        fields.number(
          'laminaRequeridaMm',
          'Lâmina requerida (IRN)',
          project.laminaRequeridaMm,
          'mm',
        ),
      ..._irnDemandaFields(fields, project),
    ] else ...[
      _turnoRegaPermanenteCard(fields, project),
    ],
  ];
}

Widget _latitudeField(BasinProjectFields fields, ProjetoInundacao project) =>
    IrrigationLabeledField(
      label: 'Latitude (sul negativa)',
      child: TextFormField(
        key: const ValueKey('latitudeGraus'),
        initialValue: project.latitudeGraus == null
            ? ''
            : project.latitudeGraus.toString().replaceAll('.', ','),
        decoration: const InputDecoration(
          suffixText: '°',
          helperText: 'Opcional; entre −60° e 60°',
        ),
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.-]')),
        ],
        validator: (texto) {
          if (texto == null || texto.trim().isEmpty) return null;
          final parsed = double.tryParse(texto.replaceAll(',', '.'));
          if (parsed == null || !parsed.isFinite) return 'Valor inválido.';
          if (parsed.abs() > 60) return 'Use latitude entre −60° e 60°.';
          return null;
        },
        onChanged: (texto) {
          fields.unconfirm();
          fields.controller.setNumero('latitudeGraus', texto);
        },
      ),
    );

Widget _mesReferenciaField(BasinProjectFields fields, ProjetoInundacao project) =>
    IrrigationLabeledField(
      label: 'Mês de referência',
      child: DropdownButtonFormField<int>(
        initialValue: project.mesReferencia,
        decoration: const InputDecoration(),
        items: _mesesNomes
            .asMap()
            .entries
            .map(
              (entry) => DropdownMenuItem(
                value: entry.key + 1,
                child: Text(entry.value),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          fields.unconfirm();
          fields.controller.setMesReferencia(value);
        },
      ),
    );

/// Card derivado do turno de rega contínuo (G15; p. 73), com o valor vivo
/// quando DTA, Z, f e ETc estão completos.
Widget _turnoRegaPermanenteCard(
  BasinProjectFields fields,
  ProjetoInundacao project,
) {
  final tr = turnoRegaPermanente(project);
  return IrrigationFormulaCard(
    formula: tr == null
        ? 'TR = DTA · Z · f / ETc'
        : 'TR = DTA · Z · f / ETc = ${fields.format(tr, casas: 1)} dias',
    description:
        'Turno de rega do regime contínuo; Qe e Qm saem do fator 0,116 '
        'com a ETc da etapa de clima.',
  );
}

/// Card vivo da IRN: efetiva com origem, as duas IRNs quando divergentes
/// (G14), volume no tabuleiro (mm · ha → m³) e TR = IRN/(ETc − Pef).
List<Widget> _irnDemandaFields(
  BasinProjectFields fields,
  ProjetoInundacao project,
) {
  final informada = project.laminaRequeridaMm;
  final calculada = project.irnCalculadaMm;
  final efetiva = project.irnEfetivaMm;
  final tr = project.turnoRegaIrnDias;
  final areaHa = project.areaTabuleiroHa ?? project.areaHectares;
  final volume = efetiva == null || areaHa == null
      ? null
      : efetiva * areaHa * 10;
  final divergente =
      informada != null &&
      calculada != null &&
      (informada - calculada).abs() > 1e-6;
  return [
    IrrigationAuditSection(
      title: 'Demanda e IRN',
      icon: AppIcons.projetoClima,
      children: [
        IrrigationAuditRow(
          'IRN efetiva (${project.origemIrn.displayName.toLowerCase()})',
          efetiva == null
              ? (project.origemIrn == OrigemIrnInundacao.informada
                    ? 'Não informado'
                    : 'Não calculado')
              : '${fields.format(efetiva)} mm',
          detail: project.origemIrn == OrigemIrnInundacao.informada
              ? 'IRN digitada; prevalece sobre a calculada.'
              : 'IRN = (UCC − UPMP)/10 · Ds · z · f com a demanda do clima.',
        ),
        if (divergente) ...[
          IrrigationAuditRow(
            'IRN informada',
            '${fields.format(informada)} mm',
            detail:
                'As duas IRNs são exibidas sem sobrescrever; prevalece a '
                'informada no cálculo.',
            isWarning: true,
          ),
          IrrigationAuditRow(
            'IRN calculada',
            '${fields.format(calculada)} mm',
            detail: 'Somente auditoria nesta situação.',
          ),
        ],
        IrrigationAuditRow(
          'Volume no tabuleiro (IRN × área × 10)',
          volume == null
              ? 'Não calculado'
              : '${fields.format(volume, casas: 1)} m³ '
                    '(${fields.format(efetiva)} mm × ${fields.format(areaHa)} ha)',
          detail: '1 mm·ha equivale a 10 m³ de água.',
        ),
        IrrigationAuditRow(
          'TR = IRN / (ETc − Pef)',
          tr == null
              ? 'Não calculado'
              : '${fields.format(tr, casas: 1)} dias '
                    '(${fields.format(efetiva)} / '
                    '(${fields.format(project.etcMmDia)} − '
                    '${fields.format(project.precipitacaoEfetivaEfetivaMmDia)}))',
          detail:
              'Turno de rega pela demanda líquida; compare com o intervalo '
              'na etapa de operação.',
        ),
      ],
    ),
  ];
}
