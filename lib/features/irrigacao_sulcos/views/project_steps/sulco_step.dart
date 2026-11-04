import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/core/widgets/calculated_field.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/proveniencia_dado.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/tipo_sulco_info.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';

import 'project_step_widgets.dart';

// ──────────────────────── Step 1: Sulco ────────────────────────

class SulcoStep extends ConsumerWidget {
  const SulcoStep({
    super.key,
    required this.state,
    required this.accent,
    required this.wide,
  });
  final EstadoParametrosSulco state;
  final Color accent;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fields = <Widget>[
      if (state.dimensionarComprimentoCriddle &&
          state.provenienciaGeometria == ProvenienciaDado.calculado)
        CalculatedField(
          label: 'Comprimento dimensionado por Criddle',
          value: state.comprimento,
          suffix: 'm',
        )
      else if (state.dimensionarComprimentoCriddle)
        Text(
          'Comprimento aguardando dados válidos para o dimensionamento automático.',
          style: Theme.of(context).textTheme.bodySmall,
        )
      else
        StepField(
          name: 'comprimento',
          label: 'Comprimento informado do sulco',
          value: state.comprimento,
          suffix: 'm',
        ),
      StepField(
        name: 'larguraSulcoM',
        label: 'Largura superior do sulco (opcional)',
        value: state.larguraSulcoM,
        suffix: 'm',
        helper: 'Mantenha em branco quando não medida.',
        optional: true,
      ),
      StepField(
        name: 'profundidadeSulcoM',
        label: 'Profundidade do sulco (opcional)',
        value: state.profundidadeSulcoM,
        suffix: 'm',
        helper: 'Mantenha em branco quando não medida.',
        optional: true,
      ),
      CalculatedField(
        label: 'Avanço até metade do comprimento',
        value: state.tempoAvancoMetadeMin,
        suffix: 'min',
      ),
      CalculatedField(
        label: 'Avanço até o final',
        value: state.tempoAvancoFinalMin,
        suffix: 'min',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.tipoSulco != null) ...[
          TipoSulcoInfoCard(tipo: state.tipoSulco!),
          const SizedBox(height: 16),
          if (!state.tipoSulco!.suportaEscoamentoTerminal) ...[
            UnsupportedFurrowModelNotice(tipo: state.tipoSulco!),
            const SizedBox(height: 16),
          ],
        ],
        StepBentoCard(
          title: 'Dimensões e operação do sulco',
          subtitle: 'Geometria e espaçamento. Vazão e tempos de avanço são calculados pela aplicação; o tempo de oportunidade pode ser editado.',
          icon: AppIcons.projetoSulco,
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
                    label: const Text('Informar comprimento'),
                    selected: !state.dimensionarComprimentoCriddle,
                    onSelected: (_) => ref
                        .read(provedorParametrosSulco.notifier)
                        .definirDimensionarComprimentoCriddle(false),
                  ),
                  ChoiceChip(
                    avatar: const Icon(AppIcons.curvaAvanco),
                    label: const Text('Dimensionar por Criddle'),
                    selected: state.dimensionarComprimentoCriddle,
                    onSelected: (_) => ref
                        .read(provedorParametrosSulco.notifier)
                        .definirDimensionarComprimentoCriddle(true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StepFieldGrid(fields: fields, wide: wide),
              if (state.dimensionarComprimentoCriddle &&
                  state.provenienciaGeometria ==
                      ProvenienciaDado.calculado) ...[
                const SizedBox(height: 12),
                ComprimentoCriddleResult(state: state),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ComprimentoCriddleResult extends StatelessWidget {
  const ComprimentoCriddleResult({super.key, required this.state});

  final EstadoParametrosSulco state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.sucesso, color: colors.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dimensionamento por Criddle',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(color: colors.onPrimaryContainer),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tempo de oportunidade To: ${state.tempoAplicacao.toStringAsFixed(1)} min · '
                  'tempo alvo Ta = To/4: ${state.tempoAvancoFinalMin.toStringAsFixed(1)} min',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UnsupportedFurrowModelNotice extends StatelessWidget {
  const UnsupportedFurrowModelNotice({super.key, required this.tipo});

  final TipoSulco tipo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.atencao, color: colors.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${tipo.motivoSemSuporteTerminal} A simulação genérica está bloqueada para evitar resultados hidráulicos enganosos.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────── Tipo Sulco Info ────────────────────────

class TipoSulcoInfoCard extends StatelessWidget {
  const TipoSulcoInfoCard({super.key, required this.tipo});
  final TipoSulco tipo;

  @override
  Widget build(BuildContext context) {
    final info = TipoSulcoInfo.para(tipo);
    final accent = AppColors.sulco;

    return StepBentoCard(
      title: info.tipo.displayName,
      subtitle: info.tipo.descricao,
      icon: Icons.info_outline_rounded,
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: 'Alinhamento', value: info.alinhamento),
          InfoRow(label: 'Formas', value: info.formas.join(', ')),
          InfoRow(label: 'Comprimento', value: info.comprimentoFaixa),
          InfoRow(
            label: 'Declividade ideal',
            value: info.declividade.faixaIdealLabel,
          ),
          if (info.declividade.aconselhavelMax != null)
            InfoRow(
              label: 'Declividade aconselhável',
              value: info.declividade.faixaAconselhavelLabel,
            ),
          if (info.declividade.usavelMax != null)
            InfoRow(
              label: 'Declividade usável',
              value: info.declividade.faixaUsavelLabel,
            ),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
