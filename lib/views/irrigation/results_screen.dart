import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/simulation_result.dart';
import 'package:irrigasim/viewmodels/parameters_controller.dart';
import 'package:irrigasim/viewmodels/results_controller.dart';
import 'package:irrigasim/views/irrigation/widgets/advance_chart.dart';
import 'package:irrigasim/views/irrigation/widgets/infiltration_chart.dart';
import 'package:irrigasim/views/irrigation/widgets/water_balance_chart.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(parametersProvider);
    final result = state.resultado;
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultados da simulação')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppIcons.curvaAvanco,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Execute uma simulação primeiro.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }
    final resultsState = ref.watch(resultsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados da simulação'),
        actions: [
          IconButton(
            tooltip: 'Exportar dados',
            onPressed: () => _showExport(context, state, result),
            icon: const Icon(AppIcons.exportarDados),
          ),
        ],
      ),
      body: _StandardResultsBody(
        state: state,
        result: result,
        resultsState: resultsState,
        onTabSelected: ref.read(resultsProvider.notifier).setAba,
        onNameChanged: ref.read(resultsProvider.notifier).setNomeCenario,
        onSave: () => _saveScenario(context, ref, state, result),
      ),
    );
  }

  Future<void> _saveScenario(
    BuildContext context,
    WidgetRef ref,
    ParametersState state,
    SimulationResult result,
  ) async {
    final notifier = ref.read(resultsProvider.notifier);
    if (ref.read(resultsProvider).nomeCenario.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um nome para o cenário.')),
      );
      return;
    }
    await notifier.salvarCenario(
      metodo: state.metodo,
      parametros: state.toIrrigationParameters(),
      resultado: result,
    );
    if (!context.mounted) return;
    final error = ref.read(resultsProvider).erro;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Cenário salvo com sucesso!')),
    );
  }

  void _showExport(
    BuildContext context,
    ParametersState state,
    SimulationResult result,
  ) {
    final csv = _csv(state, result);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Exportar dados em CSV',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'O conteúdo inclui entradas, indicadores e séries dos gráficos.',
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 260),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    csv,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: csv));
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'CSV copiado. Cole em um arquivo ou planilha.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copiar CSV'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StandardResultsBody extends StatelessWidget {
  const _StandardResultsBody({
    required this.state,
    required this.result,
    required this.resultsState,
    required this.onTabSelected,
    required this.onNameChanged,
    required this.onSave,
  });

  final ParametersState state;
  final SimulationResult result;
  final ResultsState resultsState;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StandardKpiGrid(result: result),
                  const SizedBox(height: 20),
                  _ResultTabs(
                    selectedIndex: resultsState.abaAtual.clamp(0, 2),
                    onSelected: onTabSelected,
                  ),
                  const SizedBox(height: 16),
                  _SelectedChart(
                    selectedIndex: resultsState.abaAtual.clamp(0, 2),
                    result: result,
                    compact: constraints.maxWidth < 520,
                  ),
                  const SizedBox(height: 20),
                  _StandardRecommendation(state: state, result: result),
                  const SizedBox(height: 20),
                  _InlineSaveCard(
                    state: state,
                    saving: resultsState.salvando,
                    onNameChanged: onNameChanged,
                    onSave: onSave,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StandardKpiGrid extends StatelessWidget {
  const _StandardKpiGrid({required this.result});

  final SimulationResult result;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Eficiência Ea',
        '${result.eficiencia.toStringAsFixed(1)}%',
        result.classificacaoEa,
      ),
      (
        'Requerimento Er',
        '${result.eficienciaRequerimento.toStringAsFixed(1)}%',
        'Adequação',
      ),
      (
        'Uniformidade CUC',
        '${result.cuc.toStringAsFixed(1)}%',
        result.classificacaoCuc,
      ),
      (
        'Distribuição DU',
        '${result.du.toStringAsFixed(1)}%',
        result.classificacaoDu,
      ),
      (
        'Lâmina média',
        '${(result.laminaMedia * 1000).toStringAsFixed(1)} mm',
        'Aplicada',
      ),
      (
        'Tempo de avanço',
        '${result.tempoAvanco.toStringAsFixed(0)} min',
        'Até o final',
      ),
      if (result.metricas['Eficiência de condução'] case final ec?)
        ('Eficiência Ec', '${ec.toStringAsFixed(1)}%', 'Condução'),
      if (result.metricas['Grau de adequação'] case final ga?)
        ('Grau de adequação GA', '${ga.toStringAsFixed(1)}%', 'Espacial'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 3 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$1,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.$2,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.$3,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ResultTabs extends StatelessWidget {
  const _ResultTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const tabs = [
      (AppIcons.balancoHidrico, 'Balanço'),
      (AppIcons.curvaAvanco, 'Avanço'),
      (AppIcons.perfilInfiltracao, 'Infiltração'),
    ];
    return Card(
      child: Row(
        children: [
          for (var index = 0; index < tabs.length; index++)
            Expanded(
              child: Semantics(
                selected: selectedIndex == index,
                button: true,
                child: InkWell(
                  onTap: () => onSelected(index),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selectedIndex == index
                          ? colors.primaryContainer
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: selectedIndex == index
                              ? colors.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(tabs[index].$1, size: 20),
                        const SizedBox(height: 2),
                        Text(
                          tabs[index].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: selectedIndex == index
                                    ? colors.onPrimaryContainer
                                    : colors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectedChart extends StatelessWidget {
  const _SelectedChart({
    required this.selectedIndex,
    required this.result,
    required this.compact,
  });

  final int selectedIndex;
  final SimulationResult result;
  final bool compact;

  static const _titles = [
    'Balanço hídrico volumétrico',
    'Curva de avanço da água',
    'Perfil longitudinal da lâmina infiltrada',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titles[selectedIndex],
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: selectedIndex == 0 && compact ? 360 : 340,
              child: IndexedStack(
                index: selectedIndex,
                children: [
                  WaterBalanceChart(resultado: result),
                  AdvanceChart(resultado: result),
                  InfiltrationChart(resultado: result),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandardRecommendation extends StatelessWidget {
  const _StandardRecommendation({required this.state, required this.result});

  final ParametersState state;
  final SimulationResult result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final good =
        result.alertaVazaoExcedida == null &&
        result.eficiencia >= 85 &&
        result.cuc >= 80 &&
        result.du >= 65;
    final title = good ? 'Desempenho satisfatório' : 'Otimização recomendada';
    final adjustment = switch (state.metodo) {
      MetodoIrrigacao.sulco => 'a vazão, o tempo de aplicação, a declividade e o espaçamento entre sulcos',
      MetodoIrrigacao.faixa => 'a vazão unitária, o tempo de aplicação, a rugosidade e a largura da faixa',
      MetodoIrrigacao.inundacao =>
        'a vazão total, o tempo de aplicação e a geometria da área',
    };
    final message =
        result.alertaVazaoExcedida ??
        (good
            ? 'O cenário atende a bons critérios de eficiência e uniformidade.'
            : 'A distribuição está irregular. Revise $adjustment.');
    final background = good
        ? colors.primaryContainer
        : colors.tertiaryContainer;
    final foreground = good
        ? colors.onPrimaryContainer
        : colors.onTertiaryContainer;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            good ? AppIcons.sucesso : AppIcons.atencao,
            color: foreground,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.metodo.displayName}: L = ${state.comprimento.toStringAsFixed(0)} m, '
                  '${state.metodo == MetodoIrrigacao.sulco ? 'espaçamento' : 'largura'} = ${state.larguraOuEspacamento.toStringAsFixed(2)} m. '
                  'Q = ${state.vazao.toStringAsFixed(2)} L/s por '
                  '${state.tempoAplicacao.toStringAsFixed(0)} min. '
                  'Avanço em ${result.tempoAvanco.toStringAsFixed(0)} min.\n$message',
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

class _InlineSaveCard extends StatelessWidget {
  const _InlineSaveCard({
    required this.state,
    required this.saving,
    required this.onNameChanged,
    required this.onSave,
  });

  final ParametersState state;
  final bool saving;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(AppIcons.salvarCenario, color: colors.primary),
                const SizedBox(width: 10),
                Text(
                  'Salvar este cenário',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              onChanged: onNameChanged,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: saving ? null : (_) => onSave(),
              decoration: InputDecoration(
                labelText: 'Nome do cenário',
                hintText:
                    '${state.metodo.displayName} - ${state.comprimento.toStringAsFixed(0)} m (${state.vazao.toStringAsFixed(2)} L/s)',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(AppIcons.salvarCenario),
              label: Text(saving ? 'Salvando...' : 'Salvar na minha conta'),
            ),
          ],
        ),
      ),
    );
  }
}

String _csv(ParametersState state, SimulationResult result) {
  final rows = <String>[
    'grupo;indicador;valor;unidade',
    'identificação;método;${state.metodo.displayName};',
    if (state.metodo == MetodoIrrigacao.inundacao)
      'identificação;regime;${state.tipoInundacao.displayName};',
    'entrada;comprimento;${state.comprimento};m',
    'entrada;declividade longitudinal;${state.declividade};m/m',
    'entrada;declividade transversal;${state.declividadeTransversal};m/m',
    'entrada;desnível longitudinal;${state.desnivelM};m',
    'entrada;distância longitudinal;${state.distanciaHorizontalM};m',
    'entrada;desnível transversal;${state.desnivelTransversalM};m',
    'entrada;distância transversal;${state.distanciaTransversalM};m',
    'resultado;eficiência de aplicação;${result.eficiencia};%',
    'resultado;CUC;${result.cuc};%',
    'resultado;DU;${result.du};%',
    'resultado;lâmina média;${result.laminaMedia * 1000};mm',
    'resultado;tempo de avanço;${result.tempoAvanco};min',
  ];
  for (final entry in result.metricas.entries) {
    rows.add(
      'resultado;${entry.key};${entry.value};${result.unidadesMetricas[entry.key] ?? ''}',
    );
  }
  for (var i = 0; i < result.curvaAvanco.length; i++) {
    final point = result.curvaAvanco[i];
    rows.add('série avanço;posição ${point.y} m;${point.x};min');
  }
  for (var i = 0; i < result.perfilLongitudinal.length; i++) {
    rows.add(
      'série infiltração;ponto ${i + 1};${result.perfilLongitudinal[i] * 1000};mm',
    );
  }
  return rows.join('\n');
}
