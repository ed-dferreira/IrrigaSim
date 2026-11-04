import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/clima_demanda.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';

import 'project_step_widgets.dart';

// ──────────────────────── Step 4: Clima ────────────────────────

class ClimaStep extends ConsumerWidget {
  const ClimaStep({
    super.key,
    required this.state,
    required this.accent,
    required this.wide,
  });
  final EstadoParametrosSulco state;
  final Color accent;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) => StepBentoCard(
    title: 'Clima e demanda hídrica',
    subtitle: 'Evapotranspiração, precipitação e demanda líquida para cálculo do turno de rega.',
    icon: AppIcons.projetoClima,
    accent: accent,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ChoiceChip(
              avatar: const Icon(AppIcons.editarPerfil),
              label: const Text('Informar dados'),
              selected: state.metodoEtc != MetodoEtc.blaneyCriddle,
              onSelected: (_) => ref
                  .read(provedorParametrosSulco.notifier)
                  .definirMetodoEtc(MetodoEtc.adotada),
            ),
            ChoiceChip(
              avatar: const Icon(AppIcons.climaSolar),
              label: const Text('Blaney–Criddle'),
              selected: state.metodoEtc == MetodoEtc.blaneyCriddle,
              onSelected: (_) => ref
                  .read(provedorParametrosSulco.notifier)
                  .definirMetodoEtc(MetodoEtc.blaneyCriddle),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.metodoEtc != MetodoEtc.blaneyCriddle)
          DropdownButtonFormField<MetodoEtc>(
            isExpanded: true,
            initialValue: state.metodoEtc,
            decoration: const InputDecoration(labelText: 'Dados manuais'),
            items: const [
              DropdownMenuItem(
                value: MetodoEtc.adotada,
                child: Text('Informar ETc diretamente'),
              ),
              DropdownMenuItem(
                value: MetodoEtc.etoVezesKc,
                child: Text('Informar ETo e calcular ETc = ETo × Kc'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(provedorParametrosSulco.notifier).definirMetodoEtc(value);
              }
            },
          ),
        if (state.metodoEtc == MetodoEtc.blaneyCriddle) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'O método estima a ETo e aplica o Kc informado na etapa Cultura. '
              'A necessidade líquida e o comprimento também consideram os dados de solo, chuva e avanço configurados.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          StepFieldGrid(
            wide: wide,
            fields: [
              OptionalNumericCurveField(
                name: 'temperaturaMediaC',
                label: 'Temperatura média do ar (°C)',
                value: state.temperaturaMediaC,
              ),
              OptionalNumericCurveField(
                name: 'latitudeGraus',
                label: 'Latitude (°; sul negativa)',
                value: state.latitudeGraus,
              ),
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: state.mesReferencia,
                decoration: const InputDecoration(
                  labelText: 'Mês de referência',
                ),
                items:
                    const [
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
                        ]
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
                  if (value != null) {
                    ref
                        .read(provedorParametrosSulco.notifier)
                        .definirMesReferencia(value);
                  }
                },
              ),
            ],
          ),
          if (state.etoBlaneyCriddle != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'ETo estimada: ${state.etoBlaneyCriddle!.toStringAsFixed(2)} mm/dia · '
                'ETc (ETo × Kc): ${(state.etoBlaneyCriddle! * state.kc).toStringAsFixed(2)} mm/dia',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          if (state.etoBlaneyCriddle == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Preencha os três dados climáticos. Use latitude entre −60° e 60° (negativa no hemisfério sul).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<OrigemChuva>(
          isExpanded: true,
          initialValue: state.origemChuva,
          decoration: const InputDecoration(
            labelText: 'Origem da precipitação',
          ),
          items: const [
            DropdownMenuItem(
              value: OrigemChuva.naoInformada,
              child: Text('Não informada'),
            ),
            DropdownMenuItem(
              value: OrigemChuva.efetiva,
              child: Text('Efetiva adotada'),
            ),
            DropdownMenuItem(
              value: OrigemChuva.observada,
              child: Text('Efetiva observada'),
            ),
            DropdownMenuItem(
              value: OrigemChuva.provavel,
              child: Text('Provável (não convertida em efetiva)'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              ref.read(provedorParametrosSulco.notifier).definirOrigemChuva(value);
            }
          },
        ),
        if (state.origemChuva == OrigemChuva.provavel)
          Text(
            'Chuva provável foi registrada, mas não pode ser subtraída da ETc como Pef sem um método explícito.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        const SizedBox(height: 12),
        StepFieldGrid(
          wide: wide,
          fields: [
            if (state.metodoEtc == MetodoEtc.adotada)
              StepField(
                name: 'evapotranspiracaoMmDia',
                label: 'Evapotranspiração da cultura (ETc adotada)',
                value: state.evapotranspiracaoMmDia,
                suffix: 'mm/dia',
              ),
            if (state.metodoEtc == MetodoEtc.etoVezesKc)
              OptionalNumericCurveField(
                name: 'etoMmDia',
                label: 'Evapotranspiração de referência (ETo, mm/dia)',
                value: state.etoMmDia,
              ),
            StepField(
              name: 'precipitacaoEfetivaMmDia',
              label: state.origemChuva == OrigemChuva.provavel
                  ? 'Precipitação provável (não é Pef)'
                  : 'Precipitação efetiva (Pef)',
              value: state.precipitacaoEfetivaMmDia,
              suffix: 'mm/dia',
              allowZero: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        LaminaRequeridaCard(
          resultado: state.laminaRequeridaResultado,
          areaHectares: state.areaHectares,
        ),
      ],
    ),
  );
}
