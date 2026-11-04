import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/core/widgets/calculated_field.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/proveniencia_dado.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';

import 'project_step_widgets.dart';

// ──────────────────────── Step 6: Operação ────────────────────────

class OperacaoStep extends ConsumerWidget {
  const OperacaoStep({
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
        title: 'Manejo da aplicação',
        subtitle: 'Escolha o tipo de manejo antes de configurar os parâmetros.',
        icon: AppIcons.projetoOperacao,
        accent: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<ManejoSulco>(
              segments: ManejoSulco.values
                  .map(
                    (m) => ButtonSegment(value: m, label: Text(m.displayName)),
                  )
                  .toList(),
              selected: {state.manejoSulco},
              onSelectionChanged: (value) => ref
                  .read(provedorParametrosSulco.notifier)
                  .definirManejoSulco(value.first),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors(context).surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                state.manejoSulco.descricao,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      StepBentoCard(
        title: 'Parâmetros do manejo',
        subtitle:
            'Dados operacionais para calcular desempenho e balanço hídrico.',
        icon: AppIcons.projetoOperacao,
        accent: accent,
        child: StepFieldGrid(
          wide: wide,
          fields: [
            CalculatedField(
              label: 'Vazão por sulco',
              value: state.vazao,
              suffix: 'L/s',
            ),
            if (state.dimensionarComprimentoCriddle &&
                state.provenienciaGeometria == ProvenienciaDado.calculado)
              CalculatedField(
                label: 'Tempo de oportunidade (To)',
                value: state.tempoAplicacao,
                suffix: 'min',
              )
            else if (state.dimensionarComprimentoCriddle)
              Text(
                'To será calculado junto com o comprimento.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              StepField(
                name: 'tempoAplicacao',
                label: 'Tempo de oportunidade no final',
                value: state.tempoAplicacao,
                suffix: 'min',
              ),
            if (state.manejoSulco == ManejoSulco.reduzida) ...[
              if (state.origemVazaoReduzida == OrigemVazaoReduzida.informada)
                StepField(
                  name: 'vazaoReduzidaLs',
                  label: 'Vazão reduzida informada',
                  value: state.vazaoReduzidaLs,
                  suffix: 'L/s',
                  allowZero: true,
                ),
              StepField(
                name: 'tempoMudancaMin',
                label: 'Atraso para redução após avanço',
                value: state.tempoMudancaMin,
                suffix: 'min',
                allowZero: true,
              ),
            ],
            if (state.manejoSulco == ManejoSulco.surtir) ...[
              StepField(
                name: 'cicloSurtirMin',
                label: 'Duração do ciclo (aplicação)',
                value: state.cicloSurtirMin,
                suffix: 'min',
              ),
              StepField(
                name: 'tempoMudancaMin',
                label: 'Duração da pausa',
                value: state.tempoMudancaMin,
                suffix: 'min',
                allowZero: true,
              ),
            ],
            StepField(
              name: 'periodoIrrigacaoDias',
              label: 'Período de irrigação adotado',
              value: state.periodoIrrigacaoDias.toDouble(),
              suffix: 'dias',
            ),
            StepField(
              name: 'tempoMudancaParcelaMin',
              label: 'Tempo entre parcelas',
              value: state.tempoMudancaParcelaMin,
              suffix: 'min',
              allowZero: true,
            ),
            StepField(
              name: 'jornadaDiariaH',
              label: 'Jornada diária disponível',
              value: state.jornadaDiariaH,
              suffix: 'h',
            ),
            StepField(
              name: 'perdasConducaoLs',
              label: 'Perdas de condução',
              value: state.perdasConducaoLs,
              suffix: 'L/s',
              allowZero: true,
            ),
            StepField(
              name: 'vazaoDisponivelLps',
              label: 'Vazão disponível na fonte',
              value: state.vazaoDisponivelLps,
              suffix: 'L/s',
            ),
          ],
        ),
      ),
      if (state.manejoSulco == ManejoSulco.reduzida) ...[
        const SizedBox(height: 12),
        StepBentoCard(
          title: 'Origem da vazão reduzida',
          subtitle: 'F23 e F24 são estimativas diferentes; a curva de avanço após a troca não é prevista.',
          icon: AppIcons.projetoOperacao,
          accent: accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<OrigemVazaoReduzida>(
                initialValue: state.origemVazaoReduzida,
                decoration: const InputDecoration(
                  labelText: 'Método de escolha de qr',
                ),
                items: const [
                  DropdownMenuItem(
                    value: OrigemVazaoReduzida.informada,
                    child: Text('Vazão informada'),
                  ),
                  DropdownMenuItem(
                    value: OrigemVazaoReduzida.taxaFinalDaCurva,
                    child: Text('Taxa no fim da curva (estimativa)'),
                  ),
                  DropdownMenuItem(
                    value: OrigemVazaoReduzida.vib,
                    child: Text('VIB · F23'),
                  ),
                  DropdownMenuItem(
                    value: OrigemVazaoReduzida.somatorioEspacial,
                    child: Text('Estacas medidas · F24 (p.96)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(provedorParametrosSulco.notifier)
                        .definirOrigemVazaoReduzida(value);
                  }
                },
              ),
              if (state.origemVazaoReduzida == OrigemVazaoReduzida.vib) ...[
                const SizedBox(height: 12),
                StepField(
                  name: 'vib',
                  label: 'VIB para F23',
                  value: state.vib,
                  suffix: 'm/min',
                ),
                SwitchListTile(
                  title: const Text('Aplicar fator 1,1 à estimativa F23'),
                  value: state.fator11Vib,
                  onChanged: ref
                      .read(provedorParametrosSulco.notifier)
                      .definirFator11Vib,
                ),
              ],
              if (state.origemVazaoReduzida ==
                  OrigemVazaoReduzida.somatorioEspacial)
                Text(
                  'F24 integra VI(x) entre estacas medidas até o comprimento escolhido, no instante Ta + atraso. Sem estacas e cobertura completas, não há estimativa.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 8),
              Text(
                'A simulação condiciona o perfil à manutenção da cobertura. A oferta e o balanço são testados; não há previsão hidráulica da mudança de vazão.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ],
  );

  ColorScheme colors(BuildContext context) => Theme.of(context).colorScheme;
}
