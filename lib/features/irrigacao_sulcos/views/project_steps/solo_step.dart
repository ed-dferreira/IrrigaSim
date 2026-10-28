import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/medicoes_campo.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/curva_infiltracao.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';

import 'project_step_widgets.dart';
import 'avanco_step.dart';

// ──────────────────────── Step 2: Solo ────────────────────────

class SoloStep extends ConsumerWidget {
  const SoloStep({
    super.key,
    required this.state,
    required this.accent,
    required this.wide,
  });
  final EstadoParametrosSulco state;
  final Color accent;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StepBentoCard(
        title: 'Textura do solo',
        subtitle: 'Selecione a textura para fórmula de erosão por tipo.',
        icon: Icons.landscape_rounded,
        accent: accent,
        child: SegmentedButton<TexturaSolo>(
          segments: TexturaSolo.values
              .map((t) => ButtonSegment(value: t, label: Text(t.displayName)))
              .toList(),
          selected: {state.texturaSolo},
          onSelectionChanged: (value) =>
              ref.read(provedorParametrosSulco.notifier).definirTexturaSolo(value.first),
        ),
      ),
      const SizedBox(height: 16),
      StepBentoCard(
        title: 'Água disponível no solo',
        subtitle:
            'Dados para calcular automaticamente a lâmina requerida (IRN).',
        icon: Icons.water_drop_outlined,
        accent: accent,
        child: StepFieldGrid(
          wide: wide,
          fields: [
            StepField(
              name: 'uccPercentual',
              label: 'Umidade na capacidade de campo (UCC)',
              value: state.uccPercentual,
              suffix: '%',
            ),
            StepField(
              name: 'upmpPercentual',
              label: 'Umidade no ponto de murcha (UPMP)',
              value: state.upmpPercentual,
              suffix: '%',
            ),
            StepField(
              name: 'densidadeAparenteGcm3',
              label: 'Densidade aparente',
              value: state.densidadeAparenteGcm3,
              suffix: 'g/cm³',
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      StepBentoCard(
        title: 'Infiltração do solo',
        subtitle: 'Parâmetros da curva de infiltração acumulada.',
        icon: AppIcons.projetoSolo,
        accent: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.origemCurvaInfiltracao ==
                OrigemCurvaInfiltracao.equacaoAcumuladaInformada) ...[
              if (state.entradasSulco.curvaInfiltracao case final curva?) ...[
                DropdownButtonFormField<TipoCurvaInfiltracao>(
                  initialValue: curva.tipo,
                  decoration: const InputDecoration(
                    labelText: 'Lei de infiltração informada',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: TipoCurvaInfiltracao.acumulada,
                      child: Text('Acumulada I = K·T^a'),
                    ),
                    DropdownMenuItem(
                      value: TipoCurvaInfiltracao.taxa,
                      child: Text('Taxa VI = K·T^n'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(provedorParametrosSulco.notifier)
                          .configurarCurvaInfiltracao(tipo: value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BaseInfiltracao>(
                  initialValue: curva.base,
                  decoration: const InputDecoration(labelText: 'Base da curva'),
                  items: [
                    DropdownMenuItem(
                      value: BaseInfiltracao.milimetros,
                      child: Text(
                        curva.tipo == TipoCurvaInfiltracao.taxa ? 'mm/h' : 'mm',
                      ),
                    ),
                    DropdownMenuItem(
                      value: BaseInfiltracao.litrosPorMetro,
                      child: Text(
                        curva.tipo == TipoCurvaInfiltracao.taxa
                            ? 'L/min/m'
                            : 'L/m',
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(provedorParametrosSulco.notifier)
                          .configurarCurvaInfiltracao(base: value);
                    }
                  },
                ),
                const SizedBox(height: 12),
              ] else
                OutlinedButton(
                  onPressed: () => ref
                      .read(provedorParametrosSulco.notifier)
                      .configurarCurvaInfiltracao(),
                  child: const Text(
                    'Informar origem e unidades da curva legada',
                  ),
                ),
            ],
            StepFieldGrid(
              wide: wide,
              fields: [
                if (state.origemCurvaInfiltracao ==
                        OrigemCurvaInfiltracao.equacaoAcumuladaInformada &&
                    (state.entradasSulco.curvaInfiltracao == null ||
                        (state.entradasSulco.curvaInfiltracao!.tipo ==
                                TipoCurvaInfiltracao.acumulada &&
                            state.entradasSulco.curvaInfiltracao!.base ==
                                BaseInfiltracao.milimetros))) ...[
                  StepField(
                    name: 'k',
                    label: 'Coeficiente acumulado aI',
                    value: state.k,
                    suffix: 'mm/minⁿ',
                  ),
                  StepField(
                    name: 'a',
                    label: 'Expoente acumulado n',
                    value: state.a,
                    helper: 'Entre 0 e 1',
                  ),
                ],
                if (state.origemCurvaInfiltracao ==
                        OrigemCurvaInfiltracao.equacaoAcumuladaInformada &&
                    state.entradasSulco.curvaInfiltracao != null &&
                    (state.entradasSulco.curvaInfiltracao!.tipo !=
                            TipoCurvaInfiltracao.acumulada ||
                        state.entradasSulco.curvaInfiltracao!.base !=
                            BaseInfiltracao.milimetros)) ...[
                  StepField(
                    name: 'curvaCoeficiente',
                    label: 'Coeficiente K da curva',
                    value: state.entradasSulco.curvaInfiltracao!.coeficiente,
                    suffix: state
                        .entradasSulco
                        .curvaInfiltracao!
                        .unidadeCoeficiente,
                  ),
                  StepField(
                    name: 'curvaExpoente',
                    label: 'Expoente da curva',
                    value: state.entradasSulco.curvaInfiltracao!.expoente,
                  ),
                ],
              ],
            ),
            if (state.origemCurvaInfiltracao ==
                OrigemCurvaInfiltracao.equacaoAcumuladaInformada) ...[
              if (state.entradasSulco.curvaInfiltracao case final curva?) ...[
                if (curva.base == BaseInfiltracao.litrosPorMetro)
                  OptionalNumericCurveField(
                    label: 'E medido para converter L/m em mm (m)',
                    value: curva.espacamentoConversaoM,
                    name: 'curvaEspacamentoM',
                  ),
                OptionalNumericCurveField(
                  label: 'VIB separada da curva (mm/h, opcional)',
                  value: curva.vibMmHora,
                  name: 'curvaVibMmHora',
                ),
                OptionalNumericCurveField(
                  label: 'Início do intervalo calibrado (min, opcional)',
                  value: curva.tempoMinCalibrado,
                  name: 'curvaTempoMin',
                ),
                OptionalNumericCurveField(
                  label: 'Fim do intervalo calibrado (min, opcional)',
                  value: curva.tempoMaxCalibrado,
                  name: 'curvaTempoMax',
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final data = await showDatePicker(
                      context: context,
                      initialDate: curva.dataEnsaio ?? DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime(2100),
                    );
                    if (data != null && context.mounted) {
                      ref
                          .read(provedorParametrosSulco.notifier)
                          .definirDataCurvaInfiltracao(data);
                    }
                  },
                  child: Text(
                    curva.dataEnsaio == null
                        ? 'Informar data do ensaio (opcional)'
                        : 'Data do ensaio: ${curva.dataEnsaio!.day}/${curva.dataEnsaio!.month}/${curva.dataEnsaio!.year}',
                  ),
                ),
                Text(
                  'VIB não é somada automaticamente à lei potencial. Valores além do intervalo calibrado ou VI < VIB serão sinalizados.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
            const SizedBox(height: 8),
            Text(
              'A lâmina infiltrada usa a curva selecionada, integrada se a entrada for VI(T); tempo em minutos.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            SegmentedButton<OrigemCurvaInfiltracao>(
              segments: const [
                ButtonSegment(
                  value: OrigemCurvaInfiltracao.equacaoAcumuladaInformada,
                  label: Text('Equação informada'),
                ),
                ButtonSegment(
                  value: OrigemCurvaInfiltracao.ensaioEntradaSaida,
                  label: Text('Ensaio entrada/saída'),
                ),
              ],
              selected: {state.origemCurvaInfiltracao},
              onSelectionChanged: (value) => ref
                  .read(provedorParametrosSulco.notifier)
                  .definirOrigemCurvaInfiltracao(value.first),
            ),
            if (state.origemCurvaInfiltracao ==
                OrigemCurvaInfiltracao.ensaioEntradaSaida) ...[
              const SizedBox(height: 12),
              StepFieldGrid(
                wide: wide,
                fields: [
                  StepField(
                    name: 'distanciaEnsaioInfiltracaoM',
                    label: 'Comprimento ensaiado',
                    value: state.distanciaEnsaioInfiltracaoM,
                    suffix: 'm',
                  ),
                  StepField(
                    name: 'espacamentoEnsaioInfiltracaoM',
                    label: 'Espaçamento ensaiado',
                    value: state.espacamentoEnsaioInfiltracaoM,
                    suffix: 'm',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              EntradaSaidaEditor(
                pontos: state.medicoesEntradaSaida,
                onChanged: ref
                    .read(provedorParametrosSulco.notifier)
                    .definirMedicoesEntradaSaida,
              ),
              Text(
                'Informe as vazões totais do trecho ensaiado. Se o dado estiver '
                'normalizado por 100 m, use 100 m no comprimento ensaiado. '
                'O ajuste usa VI = (Qentrada − Qsaída) × 3600 / '
                '(comprimento × espaçamento). A integração converte VI '
                '(mm/h) para a equação acumulada usada no perfil.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
