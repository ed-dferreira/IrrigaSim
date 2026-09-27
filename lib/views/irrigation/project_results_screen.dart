import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/simulation_result.dart';
import 'package:irrigasim/viewmodels/parameters_controller.dart';
import 'package:irrigasim/viewmodels/results_controller.dart';
import 'package:irrigasim/viewmodels/irrigation_providers.dart';
import 'package:irrigasim/views/irrigation/widgets/advance_chart.dart';
import 'package:irrigasim/views/irrigation/widgets/infiltration_chart.dart';
import 'package:irrigasim/views/irrigation/widgets/water_balance_chart.dart';
import 'package:irrigasim/views/irrigation/widgets/opportunity_time_chart.dart';
import 'package:irrigasim/views/irrigation/widgets/performance_bars_chart.dart';
import 'package:irrigasim/views/irrigation/widgets/depth_along_furrow_chart.dart';
import 'package:irrigasim/views/irrigation/widgets/terrain_view.dart';
import 'package:irrigasim/views/irrigation/widgets/scenario_comparison_chart.dart';

class ProjectResultsScreen extends ConsumerWidget {
  const ProjectResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(parametersProvider);
    final result = state.resultado;
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultados do projeto')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppIcons.projetoRevisao,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Execute o dimensionamento primeiro.',
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
        title: const Text('Resultados do projeto'),
        actions: [
          IconButton(
            tooltip: 'Exportar dados',
            onPressed: () => _showExport(context, state, result),
            icon: const Icon(AppIcons.exportarDados),
          ),
        ],
      ),
      body: _AuditResultsBody(
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
    final csv = _buildCsv(state, result);
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
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
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

// ──────────────────────── Audit Results Body ────────────────────────

class _AuditResultsBody extends StatelessWidget {
  const _AuditResultsBody({
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RecommendationBanner(state: state, result: result),
                const SizedBox(height: 20),
                _KpiGrid(result: result),
                const SizedBox(height: 20),
                _AuditableSection(
                  title: 'Dados de entrada',
                  icon: Icons.input_rounded,
                  children: [
                    _AuditRow('Método', state.metodo.displayName),
                    _AuditRow(
                      'Comprimento',
                      '${state.comprimento.toStringAsFixed(0)} m',
                    ),
                    _AuditRow(
                      state.metodo == MetodoIrrigacao.sulco
                          ? 'Espaçamento'
                          : 'Largura',
                      '${state.larguraOuEspacamento.toStringAsFixed(2)} m',
                    ),
                    _AuditRow(
                      'Declividade',
                      '${state.declividade.toStringAsFixed(6)} m/m',
                      detail:
                          '${(state.declividade * 100).toStringAsFixed(4)}%',
                    ),
                    _AuditRow('Textura do solo', state.texturaSolo.displayName),
                    _AuditRow('Coef. infiltração k', '${state.k}'),
                    _AuditRow('Expoente a', '${state.a}'),
                    if (state.metodo != MetodoIrrigacao.sulco) ...[
                      _AuditRow(
                        'Vazão',
                        '${state.vazao.toStringAsFixed(2)} L/s',
                      ),
                      _AuditRow(
                        'Tempo de aplicação',
                        '${state.tempoAplicacao.toStringAsFixed(0)} min',
                      ),
                    ],
                    _AuditRow(
                      'Lâmina requerida',
                      '${state.laminaRequerida.toStringAsFixed(0)} mm',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _AuditableSection(
                  title: 'Resultados calculados',
                  icon: Icons.output_rounded,
                  children: [
                    if (state.metodo == MetodoIrrigacao.sulco) ...[
                      _AuditRow(
                        'Vazão por sulco',
                        '${(result.metricas['Vazão por sulco'] ?? state.vazao).toStringAsFixed(2)} L/s',
                        detail: 'Calculado pela aplicação',
                      ),
                      _AuditRow(
                        'Tempo de oportunidade',
                        '${(result.metricas['Tempo de oportunidade'] ?? state.tempoAplicacao).toStringAsFixed(0)} min',
                        detail: 'Calculado pela aplicação',
                      ),
                      _AuditRow(
                        'Tempo de aplicação (Tt)',
                        '${(result.metricas['Tempo de aplicação calculado'] ?? 0).toStringAsFixed(0)} min',
                        detail: 'Calculado pela aplicação',
                      ),
                      _AuditRow(
                        'Avanço até metade',
                        '${state.tempoAvancoMetadeMin.toStringAsFixed(1)} min',
                        detail: 'Calculado pela aplicação',
                      ),
                      _AuditRow(
                        'Avanço até o final',
                        '${result.tempoAvanco.toStringAsFixed(1)} min',
                        detail: 'Calculado pela aplicação',
                      ),
                    ],
                    _AuditRow(
                      'Eficiência de aplicação (Ea)',
                      '${result.eficiencia.toStringAsFixed(2)}%',
                      detail: result.classificacaoEa,
                    ),
                    _AuditRow(
                      'Uniformidade de Christiansen (CUC)',
                      '${result.cuc.toStringAsFixed(2)}%',
                      detail: result.classificacaoCuc,
                    ),
                    _AuditRow(
                      'Uniformidade de distribuição (DU)',
                      '${result.du.toStringAsFixed(2)}%',
                      detail: result.classificacaoDu,
                    ),
                    _AuditRow(
                      'Lâmina média infiltrada',
                      '${(result.laminaMedia * 1000).toStringAsFixed(2)} mm',
                    ),
                    _AuditRow(
                      'Tempo de avanço',
                      '${result.tempoAvanco.toStringAsFixed(2)} min',
                    ),
                    _AuditRow(
                      'Perda por percolação',
                      '${result.perdaPercolacao.toStringAsFixed(2)}%',
                    ),
                    _AuditRow(
                      'Perda por escoamento',
                      '${result.perdaEscoamento.toStringAsFixed(2)}%',
                    ),
                    _AuditRow(
                      'Eficiência de requerimento (Er)',
                      '${result.eficienciaRequerimento.toStringAsFixed(2)}%',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (state.metodo == MetodoIrrigacao.sulco) ...[
                  _FurrowDetailsSection(state: state, result: result),
                  const SizedBox(height: 16),
                ],
                _AuditableSection(
                  title: 'Fórmulas utilizadas',
                  icon: Icons.functions_rounded,
                  children: [
                    _FormulaCard(
                      formula: 'Ea = (Lf / Lm) × 100',
                      description: 'Eficiência de aplicação: lâmina média infiltrada sobre lâmina aplicada.',
                    ),
                    _FormulaCard(
                      formula: 'CUC = (1 - Σ|yi - ȳ| / (n × ȳ)) × 100',
                      description: 'Uniformidade de Christiansen baseada na média absoluta dos desvios.',
                    ),
                    _FormulaCard(
                      formula: 'DU = (L25 / ȳ) × 100',
                      description: 'Uniformidade de distribuição: média dos 25% menores sobre a média.',
                    ),
                    if (state.metodo == MetodoIrrigacao.sulco)
                      _FormulaCard(
                        formula: 'Tx = k × x^b',
                        description: 'Curva de avanço: tempo na distância x.',
                      ),
                    if (state.metodo == MetodoIrrigacao.sulco)
                      _FormulaCard(
                        formula: 'I = [K/(60×(n+1))] × T^(n+1)',
                        description: 'Infiltração acumulada pelo modelo Kostiakov-Lewis.',
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _AuditableSection(
                  title: 'Medidas de segurança',
                  icon: Icons.shield_rounded,
                  children: [
                    _AuditRow(
                      'Percolação',
                      '${result.perdaPercolacao.toStringAsFixed(1)}%',
                      detail: result.perdaPercolacao > 15
                          ? 'Limite excedido (>15%)'
                          : 'Dentro do limite',
                      isWarning: result.perdaPercolacao > 15,
                    ),
                    _AuditRow(
                      'Escoamento',
                      '${result.perdaEscoamento.toStringAsFixed(1)}%',
                      detail: result.perdaEscoamento > 10
                          ? 'Limite excedido (>10%)'
                          : 'Dentro do limite',
                      isWarning: result.perdaEscoamento > 10,
                    ),
                    _AuditRow(
                      'Eficiência',
                      '${result.eficiencia.toStringAsFixed(1)}%',
                      detail: result.eficiencia < 60
                          ? 'Abaixo do mínimo (60%)'
                          : result.eficiencia >= 75
                          ? 'Ideal (≥75%)'
                          : 'Aceitável',
                      isWarning: result.eficiencia < 60,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ChartSection(
                  title: 'Gráficos',
                  selectedIndex: resultsState.abaAtual.clamp(0, 6),
                  onTabSelected: onTabSelected,
                  result: result,
                ),
                const SizedBox(height: 20),
                TerrainView(
                  comprimentoM: state.comprimento,
                  larguraM: state.larguraOuEspacamento * 10,
                  espacamentoSulcosM: state.larguraOuEspacamento,
                  declividadePercentual: state.declividade * 100,
                  tipoSulco: state.metodo == MetodoIrrigacao.sulco
                      ? state.tipoSulco
                      : null,
                ),
                const SizedBox(height: 20),
                if (result.alertaVazaoExcedida != null)
                  _AlertBanner(message: result.alertaVazaoExcedida!),
                const SizedBox(height: 16),
                _SaveCard(
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
    );
  }
}

// ──────────────────────── Recommendation Banner ────────────────────────

class _RecommendationBanner extends StatelessWidget {
  const _RecommendationBanner({required this.state, required this.result});
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
    final message =
        result.alertaVazaoExcedida ??
        (good
            ? 'O dimensionamento atende a bons critérios de eficiência e uniformidade.'
            : 'Revise os parâmetros para melhorar o desempenho.');
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
                  'Q = ${state.vazao.toStringAsFixed(2)} L/s por ${state.tempoAplicacao.toStringAsFixed(0)} min. '
                  'Ea = ${result.eficiencia.toStringAsFixed(1)}%, CUC = ${result.cuc.toStringAsFixed(1)}%.\n$message',
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

// ──────────────────────── KPI Grid ────────────────────────

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.result});
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
      (
        'Er',
        '${result.eficienciaRequerimento.toStringAsFixed(1)}%',
        'Adequação',
      ),
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

// ──────────────────────── Auditable Section ────────────────────────

class _AuditableSection extends StatelessWidget {
  const _AuditableSection({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow(
    this.label,
    this.value, {
    this.detail,
    this.isWarning = false,
  });
  final String label;
  final String value;
  final String? detail;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isWarning ? colors.error : null,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isWarning ? colors.error : colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────── Formula Card ────────────────────────

class _FormulaCard extends StatelessWidget {
  const _FormulaCard({required this.formula, required this.description});
  final String formula;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formula,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────── Alert Banner ────────────────────────

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.atencao, color: colors.onErrorContainer, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────── Chart Section ────────────────────────

class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.title,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.result,
  });
  final String title;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final SimulationResult result;

  static const _chartLabels = [
    'Balanço',
    'Avanço',
    'Infiltração',
    'Oportunidade',
    'Desempenho',
    'Lâmina',
    'Comparação',
  ];

  static const _chartIcons = [
    AppIcons.balancoHidrico,
    AppIcons.curvaAvanco,
    AppIcons.perfilInfiltracao,
    AppIcons.oportunidade,
    AppIcons.indicadores,
    AppIcons.lamina,
    AppIcons.comparar,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final clampedIndex = selectedIndex.clamp(0, _chartLabels.length - 1);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(AppIcons.chart, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _chartLabels.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = index == clampedIndex;
                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label: _chartLabels[index],
                    child: InkWell(
                      onTap: () => onTabSelected(index),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primaryContainer
                              : colors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? colors.primary
                                : colors.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _chartIcons[index],
                              size: 18,
                              color: isSelected
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _chartLabels[index],
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: isSelected
                                        ? colors.primary
                                        : colors.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 340,
              child: IndexedStack(
                index: clampedIndex,
                children: [
                  WaterBalanceChart(resultado: result),
                  AdvanceChart(resultado: result),
                  InfiltrationChart(resultado: result),
                  OpportunityTimeChart(resultado: result),
                  PerformanceBarsChart(resultado: result),
                  DepthAlongFurrowChart(resultado: result),
                  _ScenarioComparison(resultadoAtual: result),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────── Furrow Details Section ────────────────────────

class _FurrowDetailsSection extends StatelessWidget {
  const _FurrowDetailsSection({required this.state, required this.result});
  final ParametersState state;
  final SimulationResult result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final qmaxMetric = result.metricas['Vazão máxima não erosiva'];
    final appTime = result.metricas['Tempo de aplicação calculado'];
    final laminaAplicada = result.metricas['Lâmina aplicada'];
    final laminaInicio = result.perfilLongitudinal.isNotEmpty
        ? result.perfilLongitudinal.first * 1000
        : 0.0;
    final laminaFinal = result.perfilLongitudinal.isNotEmpty
        ? result.perfilLongitudinal.last * 1000
        : 0.0;
    final ta = result.tempoAvanco;
    final to = state.tempoAplicacao;
    final ti = (appTime ?? (ta + to)) - ta;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.sulco, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Dados do sulco',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Manejo
            _DetailSubSection(
              title: 'Manejo',
              rows: [
                _AuditRow('Tipo de manejo', state.manejoSulco.displayName),
                if (state.manejoSulco == ManejoSulco.reduzida) ...[
                  _AuditRow(
                    'Vazão reduzida',
                    state.vazaoReduzidaLs > 0
                        ? '${state.vazaoReduzidaLs.toStringAsFixed(2)} L/s'
                        : 'Não informada',
                  ),
                  _AuditRow(
                    'Atraso após avanço',
                    '${state.tempoMudancaMin.toStringAsFixed(0)} min',
                  ),
                ],
                if (state.manejoSulco == ManejoSulco.surtir) ...[
                  _AuditRow(
                    'Ciclo de surtirção',
                    '${state.cicloSurtirMin.toStringAsFixed(0)} min',
                  ),
                  _AuditRow(
                    'Pausa',
                    '${state.tempoMudancaMin.toStringAsFixed(0)} min',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Vazão e erosão
            _DetailSubSection(
              title: 'Vazão e erosão',
              rows: [
                _AuditRow(
                  'Vazão aplicada',
                  '${state.vazao.toStringAsFixed(2)} L/s',
                ),
                _AuditRow(
                  'Vazão máxima não erosiva',
                  qmaxMetric != null
                      ? '${qmaxMetric.toStringAsFixed(3)} L/s'
                      : '—',
                  detail:
                      'Textura: ${state.texturaSolo.displayName} — qmax = C / S0^a',
                ),
                _AuditRow(
                  'Status da vazão',
                  state.vazao <= (qmaxMetric ?? double.infinity)
                      ? 'Dentro do limite'
                      : 'Erosiva (excede qmax)',
                  isWarning: state.vazao > (qmaxMetric ?? double.infinity),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fases hidráulicas
            _DetailSubSection(
              title: 'Fases hidráulicas',
              rows: [
                _AuditRow(
                  'Tempo de avanço (ta)',
                  '${ta.toStringAsFixed(1)} min',
                  detail: 'Até o final do sulco',
                ),
                _AuditRow(
                  'Tempo de infiltração (ti)',
                  '${ti.toStringAsFixed(1)} min',
                  detail: 'Reposição após avanço',
                ),
                _AuditRow(
                  'Tempo de oportunidade (To)',
                  '${to.toStringAsFixed(0)} min',
                  detail: 'No final do sulco',
                ),
                _AuditRow(
                  'Tempo total de aplicação (Tt)',
                  '${(appTime ?? (ta + to)).toStringAsFixed(0)} min',
                  detail: 'Ta + To',
                ),
                _AuditRow(
                  'Relação ta/To',
                  to > 0 ? (ta / to).toStringAsFixed(2) : '—',
                  detail: to > 0
                      ? (ta / to <= 0.25
                            ? 'Ideal (≤ 0,25 — Criddle)'
                            : 'Acima do recomendado')
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lâminas
            _DetailSubSection(
              title: 'Lâminas',
              rows: [
                _AuditRow(
                  'Lâmina requerida',
                  '${state.laminaRequerida.toStringAsFixed(0)} mm',
                ),
                _AuditRow(
                  'Lâmina aplicada (média)',
                  laminaAplicada != null
                      ? '${laminaAplicada.toStringAsFixed(1)} mm'
                      : '—',
                ),
                _AuditRow(
                  'Lâmina infiltrada (início)',
                  '${laminaInicio.toStringAsFixed(1)} mm',
                  detail: laminaInicio > state.laminaRequerida * 1.2
                      ? 'Excesso no início'
                      : null,
                  isWarning: laminaInicio > state.laminaRequerida * 1.2,
                ),
                _AuditRow(
                  'Lâmina infiltrada (final)',
                  '${laminaFinal.toStringAsFixed(1)} mm',
                  detail: laminaFinal < state.laminaRequerida * 0.8
                      ? 'Déficit no final'
                      : null,
                  isWarning: laminaFinal < state.laminaRequerida * 0.8,
                ),
                _AuditRow(
                  'Lâmina média infiltrada',
                  '${(result.laminaMedia * 1000).toStringAsFixed(1)} mm',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSubSection extends StatelessWidget {
  const _DetailSubSection({required this.title, required this.rows});
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 6),
        ...rows,
      ],
    );
  }
}

class _ScenarioComparison extends ConsumerWidget {
  const _ScenarioComparison({required this.resultadoAtual});

  final SimulationResult resultadoAtual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarios = ref.watch(cenariosProvider);
    return scenarios.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _comparisonMessage(
        context,
        'Não foi possível carregar os cenários salvos.',
      ),
      data: (items) {
        if (items.isEmpty) {
          return _comparisonMessage(
            context,
            'Salve outro cenário para compará-lo com este resultado.',
          );
        }
        final scenario = items.first;
        return ScenarioComparisonChart(
          resultadoA: resultadoAtual,
          resultadoB: scenario.resultado,
          labelA: 'Resultado atual',
          labelB: scenario.nome,
        );
      },
    );
  }

  Widget _comparisonMessage(BuildContext context, String message) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.comparar, size: 40, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────── Save Card ────────────────────────

class _SaveCard extends StatelessWidget {
  const _SaveCard({
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
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                  'Salvar este projeto',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

// ──────────────────────── CSV Builder ────────────────────────

String _buildCsv(ParametersState state, SimulationResult result) {
  final rows = <String>[
    'grupo;indicador;valor;unidade',
    'identificação;método;${state.metodo.displayName};',
    if (state.metodo == MetodoIrrigacao.inundacao)
      'identificação;regime;${state.tipoInundacao.displayName};',
    'entrada;comprimento;${state.comprimento};m',
    'entrada;declividade longitudinal;${state.declividade};m/m',
    'entrada;desnível longitudinal;${state.desnivelM};m',
    'entrada;distância longitudinal;${state.distanciaHorizontalM};m',
    'entrada;textura solo;${state.texturaSolo.displayName};',
    'entrada;coeficiente infiltração k;${state.k};',
    'entrada;expoente a;${state.a};',
    'entrada;vazão;${state.vazao};L/s',
    'entrada;tempo aplicação;${state.tempoAplicacao};min',
    'entrada;lâmina requerida;${state.laminaRequerida};mm',
    'resultado;eficiência de aplicação;${result.eficiencia};%',
    'resultado;CUC;${result.cuc};%',
    'resultado;DU;${result.du};%',
    'resultado;eficiência requerimento;${result.eficienciaRequerimento};%',
    'resultado;lâmina média;${result.laminaMedia * 1000};mm',
    'resultado;tempo de avanço;${result.tempoAvanco};min',
    'resultado;perda percolação;${result.perdaPercolacao};%',
    'resultado;perda escoamento;${result.perdaEscoamento};%',
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
