import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:irrigasim/core/theme/app_icons.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_medicoes.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_projeto.dart';
import 'package:irrigasim/features/irrigacao_faixas/models/faixa_resultado.dart';
import 'package:irrigasim/features/irrigacao_faixas/services/faixa_ensaio_campo.dart';
import 'package:irrigasim/features/irrigacao_faixas/services/faixa_hidraulica.dart';
import 'package:irrigasim/features/cenarios/services/faixa_csv.dart';
import 'package:irrigasim/features/irrigacao_faixas/viewmodels/border_project_controller.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_project/border_project_fields.dart';
import 'package:irrigasim/features/irrigacao_faixas/views/border_trial_chart.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_forms.dart';

/// Etapa 6: manejo, vazão, ensaio de campo com estacas.
List<Widget> avancoStep(
  BuildContext context,
  BorderProjectFields fields,
  BorderProject p, {
  required String? erroEstacas,
  required BorderTrialResult? trial,
  required BorderResult? simulacaoEnsaio,
  required bool Function() montado,
}) => [
  fields.select<ManejoFaixa>(
    'Manejo',
    p.manejo,
    [
      ManejoFaixa.vazaoConstante,
      // O material de faixas lista redução de vazão e reuso (pp. 49–50) sem
      // equações; só o escoamento livre tem modelo. Opções sem modelo ficam
      // visíveis apenas em cenários antigos carregados.
      if (p.manejo != ManejoFaixa.vazaoConstante) p.manejo,
    ],
    fields.controller.setManejo,
    (v) => switch (v) {
      ManejoFaixa.vazaoConstante => 'Vazão constante',
      ManejoFaixa.vazaoReduzida => 'Vazão reduzida — sem modelo no material',
      ManejoFaixa.reuso => 'Reuso — sem modelo no material',
    },
  ),
  fields.number(
    'vazaoUnitariaLsM',
    'Vazão unitária q0',
    p.vazaoUnitariaLsM,
    'L/s/m',
  ),
  const Text(
    'Com ρ1, ρ2 e Vmax completos, calcula a vazão máxima não erosiva e avisa quando q0 excede.',
  ),
  fields.number(
    'rho1F02',
    'ρ1 (opcional)',
    p.rho1F02,
    '',
    optional: true,
  ),
  fields.number(
    'rho2F02',
    'ρ2 (opcional)',
    p.rho2F02,
    '',
    optional: true,
  ),
  fields.number(
    'vmaxF02',
    'Vmax (opcional)',
    p.vmaxF02,
    '',
    optional: true,
  ),
  IrrigationLabeledField(
    label: 'Unidade de Vmax',
    child: TextFormField(
      initialValue: p.unidadeVmaxF02,
      decoration: const InputDecoration(
        hintText: 'Unidade conforme a fonte consultada',
      ),
      onChanged: (value) {
        fields.controller.setUnidadeVmaxF02(value);
        fields.unconfirm();
      },
    ),
  ),
  fields.number('rInicial', 'Palpite inicial r', p.rInicial, '', optional: true),
  const Text(
    'O tempo de corte do dimensionamento é calculado. Para avaliar um ensaio medido, informe estacas; o corte abaixo só vale para esse ensaio.',
  ),
  IrrigationLabeledField(
    label: 'Referência de corte antecipado (condicional)',
    child: DropdownButtonFormField<double?>(
      initialValue: p.fracaoCortePlanejada,
      items: const [
        DropdownMenuItem<double?>(
          value: null,
          child: Text('Não selecionar'),
        ),
        DropdownMenuItem<double?>(value: 2 / 3, child: Text('2/3 de L')),
        DropdownMenuItem<double?>(value: .75, child: Text('3/4 de L')),
      ],
      onChanged: (value) {
        fields.controller.setFracaoCorte(value);
        fields.unconfirm();
      },
    ),
  ),
  if (p.fracaoCortePlanejada != null)
    const IrrigationAlertBanner(
      message: 'Este manejo antecipa o corte em relação ao avanço completo. O motor ainda não calcula o avanço com água remanescente; a simulação ficará bloqueada até haver modelo por regime.',
    ),
  TextFormField(
    key: const ValueKey('estacas'),
    initialValue: p.estacas
        .map(
          (s) =>
              '${s.xM};${s.avancoMin}${s.recessaoMin == null ? '' : ';${s.recessaoMin}'}',
        )
        .join('\n'),
    maxLines: 5,
    decoration: InputDecoration(
      labelText: 'Estacas medidas (opcional)',
      helperText: 'Uma por linha: distância m; avanço min; recessão min (opcional). Inclua 0;0, estacas preferencialmente a cada 10–30 m e a última em L.',
      errorText: erroEstacas,
    ),
    onChanged: (value) {
      try {
        final stakes = value.trim().isEmpty
            ? <BorderStake>[]
            : value.trim().split('\n').map((line) {
                final parts = line
                    .split(';')
                    .map((v) => double.parse(v.trim().replaceAll(',', '.')))
                    .toList();
                if (parts.length < 2 || parts.length > 3) {
                  throw const FormatException(
                    'Use x; avanço; recessão (opcional).',
                  );
                }
                return BorderStake(
                  parts[0],
                  parts[1],
                  recessaoMin: parts.length == 3 ? parts[2] : null,
                );
              }).toList();
        fields.controller.setEstacas(stakes);
        fields.setErroEstacas(null);
      } on FormatException {
        fields.setErroEstacas(
          'Revise as estacas: use x; avanço; recessão (opcional).',
        );
      }
    },
  ),
  fields.number(
    'corteEnsaioMin',
    'Instante de corte medido (opcional)',
    p.corteEnsaioMin,
    'min',
    optional: true,
  ),
  OutlinedButton.icon(
    onPressed: p.estacas.isEmpty || erroEstacas != null
        ? null
        : () {
            try {
              final measured = const BorderFieldTrial().avaliar(
                p,
                p.estacas,
                cutoffMin: p.corteEnsaioMin,
              );
              fields.ref.read(borderTrialProvider.notifier).state = measured;
              try {
                fields.ref.read(borderTrialSimulationProvider.notifier).state =
                    const BorderHydraulics().dimensionar(p);
              } on FormatException {
                fields.ref.read(borderTrialSimulationProvider.notifier).state =
                    null;
              }
            } on FormatException catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(e.message)));
            }
          },
    icon: const Icon(AppIcons.projetoEnsaio),
    label: const Text('Avaliar ensaio medido'),
  ),
  if (trial case final trial?) ...[
    BorderTrialChart(trial: trial, simulated: simulacaoEnsaio),
    Text(
      'Avanço medido ajustado: p=${fields.format(trial.avanco.p)} m/minʳ, r=${fields.format(trial.avanco.r)}, erro=${fields.format(trial.avanco.rmseMin)} min',
    ),
    Text(
      trial.perfil.isEmpty
          ? 'Recessão medida ausente: só o ajuste de avanço está disponível.'
          : 'Perfil interpolado em ${trial.perfil.length} posições. '
                'Er: ${fields.format(100 * trial.utilM3M! / (p.irnEfetivaMm! / 1000 * p.comprimentoM!))}%'
                '${trial.ea == null ? '; Ea, Pp e Pe pendentes de corte e q0 do ensaio.' : '; Ea: ${fields.format(trial.ea)}%, Pp: ${fields.format(100 * trial.percoladoM3M! / trial.entradaM3M!)}%, Pe: ${fields.format(100 * trial.escoadoM3M! / trial.entradaM3M!)}%.'}',
    ),
    OutlinedButton.icon(
      onPressed: () async {
        await Clipboard.setData(
          ClipboardData(
            text: borderTrialCsv(
              p,
              trial,
              simulacao: fields.ref.read(borderTrialSimulationProvider),
            ),
          ),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSV do ensaio copiado.')),
          );
        }
      },
      icon: const Icon(AppIcons.exportarDados),
      label: const Text('Copiar CSV do ensaio'),
    ),
  ],
  IrrigationLabeledField(
    label: 'Data do ensaio (opcional)',
    child: TextFormField(
      initialValue: p.dataEnsaioIso,
      decoration: const InputDecoration(
        hintText: 'AAAA-MM-DD',
        helperText: 'Data civil local registrada; não é inferida.',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return null;
        return DateTime.tryParse(value.trim()) == null
            ? 'Use uma data ISO válida'
            : null;
      },
      onChanged: (value) {
        fields.controller.setDataEnsaio(value);
        fields.unconfirm();
      },
    ),
  ),
  IrrigationLabeledField(
    label: 'Referência do relógio do ensaio (opcional)',
    child: TextFormField(
      initialValue: p.referenciaRelogioEnsaio,
      decoration: const InputDecoration(
        hintText: 'Ex.: instante inicial do cronômetro',
      ),
      onChanged: (value) {
        fields.controller.setReferenciaRelogioEnsaio(value);
        fields.unconfirm();
      },
    ),
  ),
  IrrigationLabeledField(
    label: 'Observações de campo (opcional)',
    child: TextFormField(
      initialValue: p.observacoesEnsaio,
      minLines: 2,
      maxLines: 4,
      onChanged: (value) {
        fields.controller.setObservacoesEnsaio(value);
        fields.unconfirm();
      },
    ),
  ),
];
