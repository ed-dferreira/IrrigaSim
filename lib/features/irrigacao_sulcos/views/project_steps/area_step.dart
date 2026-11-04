import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/tipo_sulco_info.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';

import 'project_step_widgets.dart';
import 'sulco_step.dart';

// ──────────────────────── Step 0: Área ────────────────────────

class AreaStep extends ConsumerWidget {
  const AreaStep({
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
        title: 'Área e geometria do terreno',
        subtitle: 'Informe as dimensões da parcela e o desnível longitudinal.',
        icon: AppIcons.projetoArea,
        accent: accent,
        child: StepFieldGrid(
          wide: wide,
          fields: [
            StepField(
              name: 'comprimentoMaximoTerrenoM',
              label: 'Limite de comprimento do terreno',
              value: state.comprimentoMaximoTerrenoM,
              suffix: 'm',
            ),
            StepField(
              name: 'areaHectares',
              label: 'Área efetiva da parcela',
              value: state.areaHectares,
              suffix: 'ha',
            ),
            StepField(
              name: 'larguraOuEspacamento',
              label: 'Espaçamento entre sulcos',
              value: state.larguraOuEspacamento,
              suffix: 'm',
            ),
            StepField(
              name: 'desnivelM',
              label: 'Desnível longitudinal (ΔH)',
              value: state.desnivelM,
              suffix: 'm',
              allowZero: true,
            ),
            StepField(
              name: 'distanciaHorizontalM',
              label: 'Distância longitudinal',
              value: state.distanciaHorizontalM,
              suffix: 'm',
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SulcoStep(state: state, accent: accent, wide: wide),
      if (state.tipoSulco == TipoSulco.sulcos_contorno) ...[
        const SizedBox(height: 12),
        StepBentoCard(
          title: 'Declives distintos em contorno',
          subtitle: 'A faixa do catálogo refere-se à encosta; o motor usa o declive longitudinal medido do sulco.',
          icon: AppIcons.projetoArea,
          accent: accent,
          child: OptionalNumericCurveField(
            name: 'decliveEncostaPercent',
            label: 'Declive geral da encosta (%)',
            value: state.decliveEncostaPercent,
          ),
        ),
      ],
      const SizedBox(height: 12),
      SlopeSummaryCard(state: state),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () =>
            ref.read(provedorParametrosSulco.notifier).recomendarMaiorComprimento(),
        icon: const Icon(AppIcons.recomendacao),
        label: const Text('Avaliar candidatos pela eficiência'),
      ),
      if (state.mensagemPlanejamento != null) ...[
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Text(
            state.mensagemPlanejamento!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
      const SizedBox(height: 12),
      SlopeRangeAlert(state: state),
    ],
  );
}

class SlopeRangeAlert extends StatelessWidget {
  const SlopeRangeAlert({super.key, required this.state});
  final EstadoParametrosSulco state;

  @override
  Widget build(BuildContext context) {
    final tipo = state.tipoSulco;
    if (tipo == null) return const SizedBox.shrink();

    final info = TipoSulcoInfo.para(tipo);
    if (tipo == TipoSulco.sulcos_contorno &&
        state.decliveEncostaPercent == null) {
      return Text(
        'Declive geral da encosta não informado; não é possível classificar o sulco em contorno pela faixa da aula.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    final percent = tipo == TipoSulco.sulcos_contorno
        ? state.decliveEncostaPercent!
        : state.declividade * 100;
    final faixa = info.declividade.classificar(percent);
    final mensagem = info.declividade.alertaDeclividade(
      tipo: tipo,
      percent: percent,
    );
    if (mensagem == null) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final critico = faixa == FaixaDeclividade.fora;
    final background = critico
        ? colors.errorContainer
        : colors.tertiaryContainer;
    final foreground = critico
        ? colors.onErrorContainer
        : colors.onTertiaryContainer;
    final titulo = switch (faixa) {
      FaixaDeclividade.usavel => 'Declividade fora do aconselhável',
      FaixaDeclividade.fora => 'Declividade fora da faixa usável',
      FaixaDeclividade.naoInformada => 'Faixa usável não informada na aula',
      FaixaDeclividade.ideal || FaixaDeclividade.aconselhavel => '',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.atencao, color: foreground, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mensagem,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────── Pending Confirmations Alert ────────────────────────

class PendingConfirmationsAlert extends StatelessWidget {
  const PendingConfirmationsAlert({
    super.key,
    required this.stepTitles,
    required this.unconfirmedSteps,
  });

  final List<String> stepTitles;
  final List<int> unconfirmedSteps;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pendentes = unconfirmedSteps.map((s) => stepTitles[s]).join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.atencao, color: colors.onErrorContainer, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Etapas pendentes de confirmação',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confirme as seguintes etapas antes de calcular: $pendentes.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.onErrorContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────── Slope Summary ────────────────────────

class SlopeSummaryCard extends StatelessWidget {
  const SlopeSummaryCard({super.key, required this.state});
  final EstadoParametrosSulco state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final slopePercent = state.declividade * 100;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        children: [
          _slopeItem(
            context,
            'Declividade longitudinal',
            '${state.declividade.toStringAsFixed(4)} m/m',
            detail: '${slopePercent.toStringAsFixed(2)}%',
          ),
          _slopeItem(
            context,
            'Desnível total',
            '${state.desnivelM.toStringAsFixed(2)} m em ${state.distanciaHorizontalM.toStringAsFixed(0)} m',
          ),
        ],
      ),
    );
  }

  Widget _slopeItem(
    BuildContext context,
    String label,
    String value, {
    String? detail,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (detail != null)
          Text(
            detail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
      ],
    );
  }
}
