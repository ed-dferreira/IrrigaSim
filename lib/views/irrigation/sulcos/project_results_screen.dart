import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/models/irrigation_parameters.dart';
import 'package:irrigasim/models/sulcos/field_measurements.dart';
import 'package:irrigasim/models/simulation_result.dart';
import 'package:irrigasim/models/sulcos/tipo_sulco_info.dart';
import 'package:irrigasim/viewmodels/parameters_controller.dart';
import 'package:irrigasim/viewmodels/results_controller.dart';
import 'package:irrigasim/viewmodels/cenarios/scenario_providers.dart';
import 'package:irrigasim/services/simulation/operational_planning.dart';
import 'package:irrigasim/views/irrigation/widgets/advance_chart.dart';
import 'package:irrigasim/views/irrigation/widgets/infiltration_chart.dart';
import 'package:irrigasim/views/irrigation/widgets/water_balance_chart.dart';
import 'package:irrigasim/views/irrigation/widgets/opportunity_time_chart.dart';
import 'package:irrigasim/views/irrigation/widgets/performance_bars_chart.dart';
import 'package:irrigasim/views/irrigation/sulcos/widgets/depth_along_furrow_chart.dart';
import 'package:irrigasim/views/irrigation/sulcos/widgets/terrain_view.dart';
import 'package:irrigasim/views/irrigation/widgets/scenario_comparison_chart.dart';
import 'package:irrigasim/views/irrigation/widgets/auditable_widgets.dart';

class ProjectResultsScreen extends ConsumerWidget {
  const ProjectResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(parametersProvider);
    final result = state.resultado;
    if (state.executando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultados do projeto')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Calculando resultados…'),
            ],
          ),
        ),
      );
    }
    if (result == null) {
      final error = state.erro;
      return Scaffold(
        appBar: AppBar(title: const Text('Resultados do projeto')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  error == null ? AppIcons.projetoRevisao : AppIcons.atencao,
                  size: 48,
                  color: error == null
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  error == null
                      ? 'Execute o dimensionamento primeiro.'
                      : 'Não foi possível calcular os resultados.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
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
    final tempoAvancoNaMetade = result.curvaAvanco.isEmpty
        ? state.tempoAvancoMetadeMin
        : result.curvaAvanco.reduce((left, right) {
            final leftDistance = (left.x - state.comprimento / 2).abs();
            final rightDistance = (right.x - state.comprimento / 2).abs();
            return leftDistance <= rightDistance ? left : right;
          }).y;
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
                _KpiGrid(result: result),
                const SizedBox(height: 20),
                _AuditableSection(
                  title: 'Medidas de segurança',
                  icon: Icons.shield_rounded,
                  children: [
                    if (result.alertaInfiltracao case final aviso?)
                      _AuditRow(
                        'Domínio da infiltração',
                        aviso,
                        isWarning: true,
                      ),
                    _AuditRow(
                      'Percolação integral',
                      '${result.perdaPercolacao.toStringAsFixed(1)}%',
                      detail: result.perdaPercolacao > 15
                          ? 'Acima da referência indicativa (>15%)'
                          : 'Abaixo da referência indicativa',
                      isWarning: result.perdaPercolacao > 15,
                    ),
                    _AuditRow(
                      'Escoamento integral',
                      '${result.perdaEscoamento.toStringAsFixed(1)}%',
                      detail: result.perdaEscoamento > 10
                          ? 'Acima da referência indicativa (>10%)'
                          : 'Abaixo da referência indicativa',
                      isWarning: result.perdaEscoamento > 10,
                    ),
                    _AuditRow(
                      'Eficiência para avaliação (${result.balancoSulco == null ? 'Ea' : 'Ea integral'})',
                      '${(result.balancoSulco?.eaIntegral ?? result.eficiencia).toStringAsFixed(1)}%',
                      detail:
                          (result.balancoSulco?.eaIntegral ??
                                  result.eficiencia) <
                              60
                          ? 'Abaixo do critério indicativo (60%)'
                          : (result.balancoSulco?.eaIntegral ??
                                    result.eficiencia) >=
                                75
                          ? 'Acima da referência de 75%'
                          : 'Atende ao critério indicativo',
                      isWarning:
                          (result.balancoSulco?.eaIntegral ??
                              result.eficiencia) <
                          60,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _AuditableSection(
                  title: 'Dados de entrada',
                  icon: Icons.input_rounded,
                  children: [
                    _AuditRow('Método', state.metodo.displayName),
                    if (state.tipoSulco != null)
                      _AuditRow('Tipo de sulco', state.tipoSulco!.displayName),
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
                    if (state.metodo == MetodoIrrigacao.sulco &&
                        state.origemAvanco == OrigemAvanco.estimativa)
                      _AuditRow(
                        'Curva de avanço informada',
                        'Tx = ${state.coeficienteAvancoK.toStringAsPrecision(6)} · '
                            'x^${state.expoenteAvancoB.toStringAsFixed(5)}; '
                            'X=${state.comprimento.toStringAsFixed(2)} m',
                        detail: 'k em min/mᵇ; Tx em minutos.',
                      ),
                    if (state.origemAvanco == OrigemAvanco.ensaio) ...[
                      _AuditRow(
                        'Pontos originais do ensaio de avanço',
                        state.pontosEnsaioAvanco.isEmpty
                            ? '2 pontos informados nas estacas intermediária e final'
                            : '${state.pontosEnsaioAvanco.length} pontos medidos',
                      ),
                      for (final (index, point)
                          in state.pontosEnsaioAvanco.indexed)
                        _AuditRow(
                          'Avanço medido ${index + 1}',
                          '${point.distanciaM.toStringAsFixed(2)} m · ${point.tempoMin.toStringAsFixed(2)} min',
                        ),
                    ],
                    if (state.origemCurvaInfiltracao ==
                        OrigemCurvaInfiltracao.ensaioEntradaSaida) ...[
                      _AuditRow(
                        'Área do ensaio de infiltração',
                        '${(state.distanciaEnsaioInfiltracaoM * state.espacamentoEnsaioInfiltracaoM).toStringAsFixed(2)} m²',
                      ),
                      for (final (index, point)
                          in state.medicoesEntradaSaida.indexed)
                        _AuditRow(
                          'Entrada/saída ${index + 1}',
                          't=${point.tempoMin.toStringAsFixed(2)} min · '
                              'Qin=${point.vazaoEntradaLs.toStringAsFixed(3)} L/s · '
                              'Qout=${point.vazaoSaidaLs.toStringAsFixed(3)} L/s',
                        ),
                    ],
                    if (state.hipoteseRecessao ==
                        HipoteseRecessao.medidaPorEstaca)
                      for (final (index, point)
                          in state.medicoesRecessao.indexed)
                        _AuditRow(
                          'Recessão medida ${index + 1}',
                          '${point.distanciaM.toStringAsFixed(2)} m · ${point.instanteRecessaoMin.toStringAsFixed(2)} min',
                        ),
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
                if (state.metodo == MetodoIrrigacao.sulco)
                  _AuditableSection(
                    title: 'Avanço e infiltração',
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
                          'Tempo de avanço em X',
                          '${(result.metricas['Tempo Tx calculado em X'] ?? result.tempoAvanco).toStringAsFixed(2)} min',
                          detail:
                              'X = ${(result.metricas['Distância X de referência'] ?? state.distanciaReferenciaAvancoM).toStringAsFixed(2)} m',
                        ),
                        _AuditRow(
                          'Tempo de fornecimento (Ti/Tt)',
                          result.tempoFornecimentoMin == null
                              ? 'Não calculado'
                              : '${result.tempoFornecimentoMin!.toStringAsFixed(0)} min (${(result.tempoFornecimentoMin! / 60).toStringAsFixed(2)} h)',
                          detail: 'Calculado pela aplicação',
                        ),
                        _AuditRow(
                          'Avanço até metade',
                          '${tempoAvancoNaMetade.toStringAsFixed(2)} min',
                          detail:
                              'Na estaca mais próxima da metade do comprimento',
                        ),
                        _AuditRow(
                          'Avanço até o final',
                          '${result.tempoAvanco.toStringAsFixed(1)} min',
                          detail: 'Calculado pela aplicação',
                        ),
                        _AuditRow(
                          'Origem e ajuste do avanço',
                          '${result.origemCurvaAvanco ?? 'Não registrado'} · '
                              '${result.metodoCurvaAvanco ?? 'método indisponível'}',
                        ),
                        if (result.metricas['Coeficiente da curva de avanço']
                            case final advanceK?)
                          _AuditRow(
                            'Curva ajustada Tx = k·xᵇ',
                            'k = ${advanceK.toStringAsPrecision(6)}; '
                                'b = ${(result.metricas['Expoente da curva de avanço'] ?? 0).toStringAsPrecision(5)}',
                          ),
                        if (result.metricas['R² log da curva de avanço']
                            case final advanceR2?)
                          _AuditRow(
                            'Ajuste da regressão de avanço',
                            'R² log = ${advanceR2.toStringAsFixed(5)}',
                          ),
                        _AuditRow(
                          'Origem da infiltração',
                          result.origemCurvaInfiltracao ?? 'Não registrada',
                        ),
                        if (result.metricas['Coeficiente VI ajustado']
                            case final viK?)
                          _AuditRow(
                            'Curva de taxa ajustada',
                            'VI = ${viK.toStringAsPrecision(5)} · '
                                'T^${(result.metricas['Expoente VI ajustado'] ?? 0).toStringAsFixed(4)} mm/h',
                            detail: 'Integrada com fator 1/60 para infiltração acumulada.',
                          ),
                        if (result.metricas['Coeficiente acumulado ajustado']
                            case final infiltrationK?)
                          _AuditRow(
                            'Equação acumulada ajustada',
                            'I(T) = ${infiltrationK.toStringAsPrecision(6)} · '
                                'T^${(result.metricas['Expoente acumulado ajustado'] ?? 0).toStringAsFixed(5)} mm',
                            detail: 'Curva que alimenta o perfil de infiltração; k em mm/minⁿ e T em minutos.',
                          ),
                        if (state.origemCurvaInfiltracao ==
                            OrigemCurvaInfiltracao.equacaoAcumuladaInformada)
                          _AuditRow(
                            'Curva acumulada informada',
                            'I = ${state.k} · T^${state.a} mm',
                            detail: 'Coeficiente em mm/minⁿ; tempo em minutos.',
                          ),
                        _AuditRow(
                          'Hipótese de recessão',
                          result.hipoteseRecessao ?? 'Não registrada',
                        ),
                        if (result.extrapolouAvanco)
                          const _AuditRow(
                            'Cobertura do ensaio',
                            'Curva extrapolada além da maior estaca medida',
                            isWarning: true,
                          ),
                      ],
                    ],
                  ),
                const SizedBox(height: 16),
                _AuditableSection(
                  title: 'Aplicação e desempenho',
                  icon: AppIcons.waterDrop,
                  children: [
                    _AuditRow(
                      result.balancoSulco == null
                          ? 'Eficiência de aplicação (Ea)'
                          : 'Ea slide (Lf/Lm; não fecha balanço)',
                      '${result.eficiencia.toStringAsFixed(2)}%',
                      detail: result.classificacaoEa,
                    ),
                    if (result.balancoSulco case final balanco?) ...[
                      _AuditRow(
                        'Ea integral (Lútil/Lm)',
                        '${balanco.eaIntegral.toStringAsFixed(2)}%',
                        detail:
                            'Usada nos critérios de avaliação; perfil de 0 a L',
                      ),
                      _AuditRow(
                        'Pp slide (Lmi−IRN)/Lm',
                        balanco.ppSlide == null
                            ? 'Não aplicável sob déficit'
                            : '${balanco.ppSlide!.toStringAsFixed(2)}%',
                      ),
                      _AuditRow(
                        'Déficit espacial',
                        '${balanco.deficitMm.toStringAsFixed(2)} mm',
                        detail: 'IRN = lâmina útil + déficit',
                      ),
                    ],
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
                    if (result.eficienciaDistribuicaoEd != null)
                      _AuditRow(
                        'Eficiência de distribuição (Ed)',
                        '${result.eficienciaDistribuicaoEd!.toStringAsFixed(2)}%',
                        detail: 'Lf / [(Li + Lf) / 2] × 100',
                      ),
                    if (result.adequacaoUtilGa != null)
                      _AuditRow(
                        'Adequação útil (GA)',
                        '${result.adequacaoUtilGa!.toStringAsFixed(2)}%',
                        detail: 'Lâmina útil limitada à requerida; máximo 100%',
                      ),
                    _AuditRow(
                      'Lâmina média infiltrada (Lmi)',
                      '${(result.laminaMedia * 1000).toStringAsFixed(2)} mm',
                    ),
                    _AuditRow(
                      'Tempo de avanço',
                      '${result.tempoAvanco.toStringAsFixed(2)} min',
                    ),
                    _AuditRow(
                      result.balancoSulco == null
                          ? 'Perda por percolação'
                          : 'Percolação integral',
                      '${result.perdaPercolacao.toStringAsFixed(2)}%',
                    ),
                    _AuditRow(
                      result.balancoSulco == null
                          ? 'Perda por escoamento'
                          : state.manejoSulco == ManejoSulco.reduzida &&
                                state.metodo == MetodoIrrigacao.sulco
                          ? 'Escoamento residual (cenário condicionado)'
                          : 'Escoamento integral',
                      '${result.perdaEscoamento.toStringAsFixed(2)}%',
                      detail:
                          state.metodo == MetodoIrrigacao.sulco &&
                              state.manejoSulco == ManejoSulco.reduzida
                          ? 'Pe = (Lm − Lmi) / Lm × 100; resíduo do balanço sob a hipótese de cobertura, não previsão hidráulica.'
                          : 'Pe integral = (Lm − Lmi) / Lm × 100; balanço válido',
                    ),
                    if (state.metodo == MetodoIrrigacao.sulco &&
                        state.manejoSulco == ManejoSulco.reduzida) ...[
                      _AuditRow(
                        'Tempo com vazão inicial',
                        '${result.metricas['Tempo com vazão inicial']?.toStringAsFixed(1) ?? 'Não calculado'}${result.metricas['Tempo com vazão inicial'] == null ? '' : ' min'}',
                        detail: 'Inclui avanço e atraso informado após Ta',
                      ),
                      _AuditRow(
                        'Tempo com vazão reduzida',
                        '${result.metricas['Tempo com vazão reduzida']?.toStringAsFixed(1) ?? 'Não calculado'}${result.metricas['Tempo com vazão reduzida'] == null ? '' : ' min'}',
                        detail: 'As duas fases somam Ti/Tt',
                      ),
                    ],
                    _AuditRow(
                      'Eficiência de requerimento (Er)',
                      '${result.eficienciaRequerimento.toStringAsFixed(2)}%',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _AuditableSection(
                  title: 'Necessidade hídrica',
                  icon: AppIcons.projetoClima,
                  children: [
                    if (state.laminaRequeridaResultado != null) ...[
                      _AuditRow(
                        'IRN',
                        '${state.laminaRequeridaResultado!.irnMm.toStringAsFixed(2)} mm',
                      ),
                      _AuditRow(
                        'Demanda líquida',
                        '${state.laminaRequeridaResultado!.demandaLiquidaMmDia.toStringAsFixed(2)} mm/dia',
                      ),
                      _AuditRow(
                        'Turno de rega (TR)',
                        '${state.laminaRequeridaResultado!.turnoCalculadoDias.toStringAsFixed(2)} dias (operacional: ${state.laminaRequeridaResultado!.turnoOperacionalDias} dias)',
                      ),
                    ] else ...[
                      const _AuditRow('IRN', 'Não calculada'),
                      const _AuditRow('Demanda líquida', 'Não calculada'),
                      const _AuditRow('Turno de rega (TR)', 'Não calculado'),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                if (state.metodo == MetodoIrrigacao.sulco) ...[
                  _FurrowDetailsSection(state: state, result: result),
                  const SizedBox(height: 16),
                  if (result.planejamentoOperacional != null) ...[
                    _OperationalPlanningSection(
                      planejamento: result.planejamentoOperacional!,
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
                _AuditableSection(
                  title: 'Fórmulas utilizadas',
                  icon: Icons.functions_rounded,
                  children: [
                    _FormulaCard(
                      formula: result.balancoSulco == null
                          ? 'Ea = (Lf / Lm) × 100'
                          : 'Ea slide = (Lf / Lm) × 100',
                      description: result.balancoSulco == null
                          ? 'Eficiência de aplicação: lâmina infiltrada no final (Lf) sobre lâmina média aplicada (Lm).'
                          : 'Indicador didático pelo final do sulco; não representa o fechamento volumétrico.',
                    ),
                    if (state.metodo == MetodoIrrigacao.sulco) ...[
                      const _FormulaCard(
                        formula: 'NTS = área / (C × E); NSD = NTS / período',
                        description: 'Número total de sulcos e sulcos que precisam ser irrigados por dia.',
                      ),
                      const _FormulaCard(
                        formula:
                            'TIP = Ti + tmudParcela; NPD = piso(jornada / TIP)',
                        description: 'Ti/Tt é o fornecimento por sulco; tmudParcela é o intervalo entre parcelas, separado do atraso de redução de vazão.',
                      ),
                      const _FormulaCard(
                        formula:
                            'NSP = NSD / NPD; Qprojeto = NSP × qi + perdas',
                        description: 'A operação verifica lotes parciais no período, vazão disponível e se TIP cabe na jornada.',
                      ),
                      const _FormulaCard(
                        formula: 'Ed = Lf / [(Li + Lf) / 2] × 100',
                        description: 'Eficiência de distribuição pelos extremos do perfil; não é a DU.',
                      ),
                      const _FormulaCard(
                        formula: 'GA útil = média[min(Li(x), IRN)] / IRN × 100',
                        description: 'Adequação limitada a 100%; o excesso fica contabilizado como percolação.',
                      ),
                      const _FormulaCard(
                        formula: 'Ea integral = Lútil/Lm; Pp integral = Lpercolada/Lm; Pe integral = (Lm−Lmi)/Lm',
                        description: 'Médias espaciais por trapézios de 0 a L: Lmi = Lútil + Lpercolada; IRN = Lútil + déficit. Balanço inconsistente impede o resultado.',
                      ),
                      _FormulaCard(
                        formula: state.manejoSulco == ManejoSulco.reduzida
                            ? 'Lm = [qi·tInicial + qr·tReduzido] × 60 / (C·E)'
                            : 'Lm = q·Tt × 60 / (C·E)',
                        description: 'Vazão em L/s, tempos em min, comprimento e espaçamento em m; lâmina em mm.',
                      ),
                    ],
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
                    if (state.metodo == MetodoIrrigacao.sulco &&
                        state.origemCurvaInfiltracao ==
                            OrigemCurvaInfiltracao.equacaoAcumuladaInformada)
                      const _FormulaCard(
                        formula: 'I(To) = aI × Toⁿ',
                        description: 'Equação acumulada informada; aI em mm/minⁿ e To em min.',
                      ),
                    if (state.metodo == MetodoIrrigacao.sulco &&
                        state.origemCurvaInfiltracao ==
                            OrigemCurvaInfiltracao.ensaioEntradaSaida) ...[
                      const _FormulaCard(
                        formula: 'VI(T) = K × Tⁿ',
                        description:
                            'Taxa ajustada ao ensaio; K em mm/h e T em min.',
                      ),
                      const _FormulaCard(
                        formula: 'I(T) = [K/(60×(n+1))] × T^(n+1)',
                        description: 'Integração da taxa para formar a lâmina acumulada em mm.',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
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
        (result.balancoSulco?.eaIntegral ?? result.eficiencia) >= 85 &&
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
                  'Q = ${state.vazao.toStringAsFixed(2)} L/s por ${(result.tempoFornecimentoMin ?? state.tempoAplicacao).toStringAsFixed(0)} min. '
                  '${result.balancoSulco == null ? 'Ea' : 'Ea integral'} = ${(result.balancoSulco?.eaIntegral ?? result.eficiencia).toStringAsFixed(1)}%, CUC = ${result.cuc.toStringAsFixed(1)}%.\n$message',
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
        result.balancoSulco == null ? 'Eficiência Ea' : 'Ea integral',
        '${(result.balancoSulco?.eaIntegral ?? result.eficiencia).toStringAsFixed(1)}%',
        result.classificacaoEaIntegral,
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
        'Infiltrada (Lmi)',
      ),
      (
        'Tempo de avanço',
        '${result.tempoAvanco.toStringAsFixed(0)} min',
        'Até o final',
      ),
      (
        'Er',
        '${result.eficienciaRequerimento.toStringAsFixed(1)}%',
        'Eficiência de requerimento',
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
    return IrrigationAuditSection(title: title, icon: icon, children: children);
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
  Widget build(BuildContext context) =>
      IrrigationAuditRow(label, value, detail: detail, isWarning: isWarning);
}

// ──────────────────────── Formula Card ────────────────────────

class _FormulaCard extends StatelessWidget {
  const _FormulaCard({required this.formula, required this.description});
  final String formula;
  final String description;

  @override
  Widget build(BuildContext context) =>
      IrrigationFormulaCard(formula: formula, description: description);
}

// ──────────────────────── Alert Banner ────────────────────────

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => IrrigationAlertBanner(message: message);
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

class _OperationalPlanningSection extends StatelessWidget {
  const _OperationalPlanningSection({required this.planejamento});

  final PlanejamentoOperacionalResultado planejamento;

  @override
  Widget build(BuildContext context) {
    final p = planejamento;
    final viable = p.agendaViavel && p.vazaoDisponivelSuficiente;
    return _AuditableSection(
      title: 'Planejamento operacional por parcela',
      icon: Icons.calendar_month_rounded,
      children: [
        _AuditRow(
          'Área efetiva',
          '${p.areaTotalM2.toStringAsFixed(0)} m² (${p.areaHectares.toStringAsFixed(2)} ha)',
        ),
        _AuditRow(
          'Sulcos totais (NTS)',
          '${p.ntsOperacional} (teórico ${p.ntsTeorico.toStringAsFixed(2)})',
        ),
        _AuditRow(
          'Sulcos por dia (NSD)',
          '${p.nsdOperacional} (teórico ${p.nsdTeorico.toStringAsFixed(2)})',
          detail: 'Sulcos a irrigar por dia para cumprir o turno de rega.',
        ),
        _AuditRow(
          'Tempo por parcela (TIP)',
          '${p.tipH.toStringAsFixed(4)} h (${(p.tipH * 60).toStringAsFixed(1)} min)',
          detail: 'Ti/Tt + tempo entre parcelas',
        ),
        _AuditRow(
          'Parcelas completas por dia (NPD)',
          p.npdOperacional == 0
              ? 'Nenhuma'
              : '${p.npdOperacional} (teórico ${p.npdTeorico.toStringAsFixed(2)})',
          detail: 'Grupos operacionais na jornada, não frequência agronômica.',
        ),
        _AuditRow(
          'Sulcos simultâneos (NSP)',
          '${p.nspOperacional} (teórico ${p.nspTeorico.toStringAsFixed(2)})',
        ),
        _AuditRow(
          'Dias necessários',
          '${p.diasNecessariosOperacional} de ${p.periodoIrrigacaoDias} dias',
          isWarning: !p.agendaViavel,
        ),
        _AuditRow(
          'Vazão de projeto',
          '${p.qProjetoOperacional.toStringAsFixed(2)} L/s (teórico ${p.qProjetoTeorico.toStringAsFixed(2)} L/s)',
          isWarning: !p.vazaoDisponivelSuficiente,
          detail: p.vazaoDisponivelLs == null
              ? null
              : 'Disponível: ${p.vazaoDisponivelLs!.toStringAsFixed(2)} L/s',
        ),
        _AuditRow(
          'Viabilidade operacional',
          viable ? 'Viável no período e na vazão disponível' : 'Inviável',
          detail: p.motivoInviabilidade,
          isWarning: !viable,
        ),
      ],
    );
  }
}

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
                    '${result.metricas['Vazão reduzida']?.toStringAsFixed(3) ?? 'Não calculada'} L/s',
                    detail: switch (state.origemVazaoReduzida) {
                      OrigemVazaoReduzida.informada => 'Valor informado',
                      OrigemVazaoReduzida.taxaFinalDaCurva =>
                        state.vazaoReduzidaLs > 0
                            ? 'Valor informado (cenário legado)'
                            : 'Estimativa pela derivada no fim da oportunidade',
                      OrigemVazaoReduzida.vib =>
                        'F23 · VIB em mm/h${state.fator11Vib ? ' × 1,1' : ' sem fator 1,1'}',
                      OrigemVazaoReduzida.somatorioEspacial =>
                        'F24 · somatório espacial das estacas medidas (p.96)',
                    },
                  ),
                  if (state.origemVazaoReduzida == OrigemVazaoReduzida.vib)
                    _AuditRow(
                      'VIB usada em F23',
                      '${result.metricas['VIB usada na redução']?.toStringAsFixed(2) ?? '—'} mm/h',
                    ),
                  if (result.metricas['Demanda espacial no instante da troca']
                      case final demanda?)
                    _AuditRow(
                      'Demanda espacial na troca',
                      '${demanda.toStringAsFixed(3)} L/s',
                      detail:
                          'F24 (p.96), taxas integradas nas estacas do ensaio.',
                    ),
                  _AuditRow(
                    'Atraso após avanço',
                    '${state.tempoMudancaMin.toStringAsFixed(0)} min',
                  ),
                  const _AuditRow(
                    'Hipótese hidráulica',
                    'Perfil condicionado à cobertura após a redução',
                    detail: 'Sem nova curva medida, a redução não prevê o avanço nem o escoamento hidráulico (§6.7).',
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
                if (state.ensaioErosao case final ensaio?)
                  _AuditRow(
                    'Ensaio de erosão (${ensaio.vazaoLs.toStringAsFixed(2)} L/s)',
                    ensaio.erosaoObservada
                        ? 'Erosão observada'
                        : 'Erosão não observada',
                    detail: ensaio.condicoes,
                    isWarning: ensaio.erosaoObservada,
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
                            ? 'Atende à regra orientativa de Criddle (≤ 0,25)'
                            : 'Acima da regra orientativa de Criddle')
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
    'entrada;desnível transversal;${state.desnivelTransversalM};m',
    'entrada;distância transversal;${state.distanciaTransversalM};m',
    'entrada;textura solo;${state.texturaSolo.displayName};',
    'entrada;coeficiente infiltração k;${state.k};',
    'entrada;expoente a;${state.a};',
    if (state.metodo == MetodoIrrigacao.sulco &&
        state.origemAvanco == OrigemAvanco.estimativa) ...[
      'entrada;coeficiente de avanço k;${state.coeficienteAvancoK};min/m^b',
      'entrada;expoente de avanço b;${state.expoenteAvancoB};',
      'entrada;distância X de referência;${state.distanciaReferenciaAvancoM};m',
    ],
    'entrada;vazão;${state.vazao};L/s',
    'entrada;tempo de oportunidade final;${state.tempoAplicacao};min',
    'entrada;lâmina requerida;${state.laminaRequerida};mm',
    'entrada;tipo de sulco;${state.tipoSulco?.name ?? 'não aplicável'};',
    'entrada;manejo de sulco;${state.manejoSulco.name};',
    if (state.manejoSulco == ManejoSulco.reduzida) ...[
      'entrada;origem da vazão reduzida;${state.origemVazaoReduzida.name};',
      if (state.origemVazaoReduzida == OrigemVazaoReduzida.informada)
        'entrada;vazão reduzida informada;${state.vazaoReduzidaLs};L/s',
      if (state.origemVazaoReduzida == OrigemVazaoReduzida.vib) ...[
        'entrada;VIB para F23;${state.vib};m/min',
        'entrada;fator F23;${state.fator11Vib ? 1.1 : 1.0};',
      ],
      'entrada;atraso da redução após Ta;${state.tempoMudancaMin};min',
    ],
    if (state.manejoSulco == ManejoSulco.surtir) ...[
      'entrada;duração do ciclo surtir;${state.cicloSurtirMin};min',
      'entrada;pausa do ciclo surtir;${state.tempoMudancaMin};min',
    ],
    if (state.metodo == MetodoIrrigacao.sulco) ...[
      'entrada;área efetiva;${state.areaHectares};ha',
      'entrada;período de irrigação;${state.periodoIrrigacaoDias};dias',
      'entrada;tempo entre parcelas;${state.tempoMudancaParcelaMin};min',
      'entrada;jornada diária;${state.jornadaDiariaH};h/dia',
      'entrada;vazão disponível;${state.vazaoDisponivelLps};L/s',
      'entrada;perdas de condução;${state.perdasConducaoLs};L/s',
    ],
    'entrada;Manning n;${state.manningN};',
    'entrada;sigma Z;${state.sigmaZ};',
    'entrada;origem avanço;${state.origemAvanco.name};',
    if (state.origemAvanco == OrigemAvanco.ensaio) ...[
      'ensaio avanço;vazão medida;${state.vazaoEnsaioAvancoLs ?? 'não informada'};L/s',
      'ensaio avanço;condições;${(state.condicoesEnsaioAvanco ?? '').replaceAll(';', ',').replaceAll('\n', ' ')};',
    ],
    if (state.ensaioErosao case final ensaio?) ...[
      'ensaio erosão;vazão medida;${ensaio.vazaoLs};L/s',
      'ensaio erosão;condições;${ensaio.condicoes.replaceAll(';', ',').replaceAll('\n', ' ')};',
      'ensaio erosão;erosão observada;${ensaio.erosaoObservada};',
    ],
    'entrada;método curva avanço;${state.metodoCurvaAvanco.name};',
    'entrada;origem infiltração;${state.origemCurvaInfiltracao.name};',
    if (state.origemCurvaInfiltracao ==
        OrigemCurvaInfiltracao.ensaioEntradaSaida) ...[
      'entrada;comprimento do ensaio de infiltração;${state.distanciaEnsaioInfiltracaoM};m',
      'entrada;espaçamento do ensaio de infiltração;${state.espacamentoEnsaioInfiltracaoM};m',
    ],
    'entrada;hipótese recessão;${state.hipoteseRecessao.name};',
    'resultado;${result.balancoSulco == null ? 'eficiência de aplicação' : 'Ea slide (Lf/Lm)'};${result.eficiencia};%',
    if (result.balancoSulco case final balanco?) ...[
      'resultado;Ea integral (Lútil/Lm);${balanco.eaIntegral};%',
      'resultado;Pp slide (Lmi−IRN)/Lm;${balanco.ppSlide?.toString() ?? 'não aplicável'};%',
      'resultado;Pp integral;${balanco.ppIntegral};%',
      'resultado;Pe integral;${balanco.peIntegral};%',
      'resultado;déficit espacial;${balanco.deficitMm};mm',
      'resultado;domínio do perfil;0 a ${state.comprimento} m (trapézios igualmente espaçados);',
    ],
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
  if (result.planejamentoOperacional case final planning?) {
    for (final entry in planning.toMap().entries) {
      rows.add('planejamento operacional;${entry.key};${entry.value};');
    }
  }
  for (var index = 0; index < state.pontosEnsaioAvanco.length; index++) {
    final point = state.pontosEnsaioAvanco[index];
    rows.add(
      'ensaio avanço;distância da observação ${index + 1};${point.distanciaM};m',
    );
    rows.add(
      'ensaio avanço;tempo da observação ${index + 1};${point.tempoMin};min',
    );
  }
  if (state.origemAvanco == OrigemAvanco.ensaio &&
      state.metodoCurvaAvanco == MetodoCurvaAvanco.doisPontos &&
      state.pontosEnsaioAvanco.isEmpty) {
    rows.add(
      'ensaio avanço;distância intermediária;${state.distanciaEnsaioIntermediariaM};m',
    );
    rows.add(
      'ensaio avanço;tempo intermediário;${state.tempoEnsaioIntermediarioMin};min',
    );
    rows.add('ensaio avanço;distância final;${state.comprimento};m');
    rows.add('ensaio avanço;tempo final;${state.tempoAvancoFinalMin};min');
  }
  for (var index = 0; index < state.medicoesEntradaSaida.length; index++) {
    final point = state.medicoesEntradaSaida[index];
    rows.add(
      'ensaio infiltração;tempo da observação ${index + 1};${point.tempoMin};min',
    );
    rows.add(
      'ensaio infiltração;vazão de entrada ${index + 1};${point.vazaoEntradaLs};L/s',
    );
    rows.add(
      'ensaio infiltração;vazão de saída ${index + 1};${point.vazaoSaidaLs};L/s',
    );
  }
  for (var index = 0; index < state.medicoesRecessao.length; index++) {
    final point = state.medicoesRecessao[index];
    rows.add(
      'ensaio recessão;distância da estaca ${index + 1};${point.distanciaM};m',
    );
    rows.add(
      'ensaio recessão;instante medido ${index + 1};${point.instanteRecessaoMin};min',
    );
  }
  for (var i = 0; i < result.curvaAvanco.length; i++) {
    final point = result.curvaAvanco[i];
    rows.add('série avanço;posição ${i + 1};${point.y};m');
    rows.add('série avanço;tempo ${i + 1};${point.x};min');
  }
  for (var i = 0; i < result.curvaOportunidade.length; i++) {
    final point = result.curvaOportunidade[i];
    rows.add('série oportunidade;distância ${i + 1};${point.x};m');
    rows.add('série oportunidade;tempo ${i + 1};${point.y};min');
  }
  for (var i = 0; i < result.perfilLongitudinal.length; i++) {
    rows.add(
      'série infiltração;ponto ${i + 1};${result.perfilLongitudinal[i] * 1000};mm',
    );
  }
  return rows.join('\n');
}
