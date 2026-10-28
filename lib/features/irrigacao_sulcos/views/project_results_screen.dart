import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/medicoes_campo.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/tipo_sulco_info.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';
import 'package:irrigasim/shared/cenarios/controllers/salvar_cenario_controller.dart';
import 'package:irrigasim/shared/irrigacao/widgets/terrain/terrain_view.dart';

import 'project_results/project_results_sections.dart';
import 'project_results/project_results_widgets.dart';

class ProjectResultsScreen extends ConsumerWidget {
  const ProjectResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provedorParametrosSulco);
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
    EstadoParametrosSulco state,
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
      metodo: MetodoIrrigacao.sulco,
      parametros: state.paraParametrosIrrigacao(),
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
    EstadoParametrosSulco state,
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

  final EstadoParametrosSulco state;
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
            final leftDistance = (left.y - state.comprimento / 2).abs();
            final rightDistance = (right.y - state.comprimento / 2).abs();
            return leftDistance <= rightDistance ? left : right;
          }).x;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RecommendationBanner(state: state, result: result),
                const SizedBox(height: 20),
                ChartSection(
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
                  tipoSulco: state.tipoSulco,
                ),
                const SizedBox(height: 20),
                KpiGrid(result: result),
                const SizedBox(height: 20),
                AuditableSection(
                  title: 'Medidas de segurança',
                  icon: Icons.shield_rounded,
                  children: [
                    if (result.alertaInfiltracao case final aviso?)
                      AuditRow(
                        'Domínio da infiltração',
                        aviso,
                        isWarning: true,
                      ),
                    AuditRow(
                      'Percolação integral',
                      '${result.perdaPercolacao.toStringAsFixed(1)}%',
                      detail: result.perdaPercolacao > 15
                          ? 'Acima da referência indicativa (>15%)'
                          : 'Abaixo da referência indicativa',
                      isWarning: result.perdaPercolacao > 15,
                    ),
                    AuditRow(
                      'Escoamento integral',
                      '${result.perdaEscoamento.toStringAsFixed(1)}%',
                      detail: result.perdaEscoamento > 10
                          ? 'Acima da referência indicativa (>10%)'
                          : 'Abaixo da referência indicativa',
                      isWarning: result.perdaEscoamento > 10,
                    ),
                    AuditRow(
                      'Eficiência para avaliação (${result.balancoSulco == null ? 'Ea' : 'Ea integral'})',
                      '${(result.balancoSulco?.eficienciaAplicacaoIntegralPercentual ?? result.eficiencia).toStringAsFixed(1)}%',
                      detail:
                          (result
                                      .balancoSulco
                                      ?.eficienciaAplicacaoIntegralPercentual ??
                                  result.eficiencia) <
                              60
                          ? 'Abaixo do critério indicativo (60%)'
                          : (result
                                        .balancoSulco
                                        ?.eficienciaAplicacaoIntegralPercentual ??
                                    result.eficiencia) >=
                                75
                          ? 'Acima da referência de 75%'
                          : 'Atende ao critério indicativo',
                      isWarning:
                          (result
                                  .balancoSulco
                                  ?.eficienciaAplicacaoIntegralPercentual ??
                              result.eficiencia) <
                          60,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AuditableSection(
                  title: 'Dados de entrada',
                  icon: Icons.input_rounded,
                  children: [
                    AuditRow('Método', 'Sulco'),
                    if (state.tipoSulco != null)
                      AuditRow('Tipo de sulco', state.tipoSulco!.displayName),
                    AuditRow(
                      'Comprimento',
                      '${state.comprimento.toStringAsFixed(0)} m',
                    ),
                    AuditRow(
                      'Espaçamento',
                      '${state.larguraOuEspacamento.toStringAsFixed(2)} m',
                    ),
                    AuditRow(
                      'Declividade',
                      '${state.declividade.toStringAsFixed(6)} m/m',
                      detail:
                          '${(state.declividade * 100).toStringAsFixed(4)}%',
                    ),
                    AuditRow('Textura do solo', state.texturaSolo.displayName),
                    AuditRow('Coef. infiltração k', '${state.k}'),
                    AuditRow('Expoente a', '${state.a}'),
                    if (state.origemAvanco == OrigemAvanco.estimativa)
                      AuditRow(
                        'Curva de avanço informada',
                        'Tx = ${state.coeficienteAvancoK.toStringAsPrecision(6)} · '
                            'x^${state.expoenteAvancoB.toStringAsFixed(5)}; '
                            'X=${state.comprimento.toStringAsFixed(2)} m',
                        detail: 'k em min/mᵇ; Tx em minutos.',
                      ),
                    if (state.origemAvanco == OrigemAvanco.ensaio) ...[
                      AuditRow(
                        'Pontos originais do ensaio de avanço',
                        state.pontosEnsaioAvanco.isEmpty
                            ? '2 pontos informados nas estacas intermediária e final'
                            : '${state.pontosEnsaioAvanco.length} pontos medidos',
                      ),
                      for (final (index, point)
                          in state.pontosEnsaioAvanco.indexed)
                        AuditRow(
                          'Avanço medido ${index + 1}',
                          '${point.distanciaM.toStringAsFixed(2)} m · ${point.tempoMin.toStringAsFixed(2)} min',
                        ),
                    ],
                    if (state.origemCurvaInfiltracao ==
                        OrigemCurvaInfiltracao.ensaioEntradaSaida) ...[
                      AuditRow(
                        'Área do ensaio de infiltração',
                        '${(state.distanciaEnsaioInfiltracaoM * state.espacamentoEnsaioInfiltracaoM).toStringAsFixed(2)} m²',
                      ),
                      for (final (index, point)
                          in state.medicoesEntradaSaida.indexed)
                        AuditRow(
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
                        AuditRow(
                          'Recessão medida ${index + 1}',
                          '${point.distanciaM.toStringAsFixed(2)} m · ${point.instanteRecessaoMin.toStringAsFixed(2)} min',
                        ),
                    AuditRow(
                      'Lâmina requerida',
                      '${state.laminaRequerida.toStringAsFixed(0)} mm',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AuditableSection(
                  title: 'Avanço e infiltração',
                  icon: Icons.output_rounded,
                  children: [
                    AuditRow(
                      'Vazão por sulco',
                      '${(result.metricas['Vazão por sulco'] ?? state.vazao).toStringAsFixed(2)} L/s',
                      detail: 'Calculado pela aplicação',
                    ),
                    AuditRow(
                      'Tempo de oportunidade',
                      '${(result.metricas['Tempo de oportunidade'] ?? state.tempoAplicacao).toStringAsFixed(0)} min',
                      detail: 'Calculado pela aplicação',
                    ),
                    AuditRow(
                      'Tempo de avanço em X',
                      '${(result.metricas['Tempo Tx calculado em X'] ?? result.tempoAvanco).toStringAsFixed(2)} min',
                      detail:
                          'X = ${(result.metricas['Distância X de referência'] ?? state.distanciaReferenciaAvancoM).toStringAsFixed(2)} m',
                    ),
                    AuditRow(
                      'Tempo de fornecimento (Ti/Tt)',
                      result.tempoFornecimentoMin == null
                          ? 'Não calculado'
                          : '${result.tempoFornecimentoMin!.toStringAsFixed(0)} min (${(result.tempoFornecimentoMin! / 60).toStringAsFixed(2)} h)',
                      detail: 'Calculado pela aplicação',
                    ),
                    AuditRow(
                      'Avanço até metade',
                      '${tempoAvancoNaMetade.toStringAsFixed(2)} min',
                      detail: 'Na estaca mais próxima da metade do comprimento',
                    ),
                    AuditRow(
                      'Avanço até o final',
                      '${result.tempoAvanco.toStringAsFixed(1)} min',
                      detail: 'Calculado pela aplicação',
                    ),
                    AuditRow(
                      'Origem e ajuste do avanço',
                      '${result.origemCurvaAvanco ?? 'Não registrado'} · '
                          '${result.metodoCurvaAvanco ?? 'método indisponível'}',
                    ),
                    if (result.metricas['Coeficiente da curva de avanço']
                        case final advanceK?)
                      AuditRow(
                        'Curva ajustada Tx = k·xᵇ',
                        'k = ${advanceK.toStringAsPrecision(6)}; '
                            'b = ${(result.metricas['Expoente da curva de avanço'] ?? 0).toStringAsPrecision(5)}',
                      ),
                    if (result.metricas['R² log da curva de avanço']
                        case final advanceR2?)
                      AuditRow(
                        'Ajuste da regressão de avanço',
                        'R² log = ${advanceR2.toStringAsFixed(5)}',
                      ),
                    AuditRow(
                      'Origem da infiltração',
                      result.origemCurvaInfiltracao ?? 'Não registrada',
                    ),
                    if (result.metricas['Coeficiente VI ajustado']
                        case final viK?)
                      AuditRow(
                        'Curva de taxa ajustada',
                        'VI = ${viK.toStringAsPrecision(5)} · '
                            'T^${(result.metricas['Expoente VI ajustado'] ?? 0).toStringAsFixed(4)} mm/h',
                        detail: 'Integrada com fator 1/60 para infiltração acumulada.',
                      ),
                    if (result.metricas['Coeficiente acumulado ajustado']
                        case final infiltrationK?)
                      AuditRow(
                        'Equação acumulada ajustada',
                        'I(T) = ${infiltrationK.toStringAsPrecision(6)} · '
                            'T^${(result.metricas['Expoente acumulado ajustado'] ?? 0).toStringAsFixed(5)} mm',
                        detail: 'Curva que alimenta o perfil de infiltração; k em mm/minⁿ e T em minutos.',
                      ),
                    if (state.origemCurvaInfiltracao ==
                        OrigemCurvaInfiltracao.equacaoAcumuladaInformada)
                      AuditRow(
                        'Curva acumulada informada',
                        'I = ${state.k} · T^${state.a} mm',
                        detail: 'Coeficiente em mm/minⁿ; tempo em minutos.',
                      ),
                    AuditRow(
                      'Hipótese de recessão',
                      result.hipoteseRecessao ?? 'Não registrada',
                    ),
                    if (result.extrapolouAvanco)
                      const AuditRow(
                        'Cobertura do ensaio',
                        'Curva extrapolada além da maior estaca medida',
                        isWarning: true,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                AuditableSection(
                  title: 'Aplicação e desempenho',
                  icon: AppIcons.waterDrop,
                  children: [
                    AuditRow(
                      result.balancoSulco == null
                          ? 'Eficiência de aplicação (Ea)'
                          : 'Ea slide (Lf/Lm; não fecha balanço)',
                      '${result.eficiencia.toStringAsFixed(2)}%',
                      detail: result.classificacaoEa,
                    ),
                    if (result.balancoSulco case final balanco?) ...[
                      AuditRow(
                        'Ea integral (Lútil/Lm)',
                        '${balanco.eficienciaAplicacaoIntegralPercentual.toStringAsFixed(2)}%',
                        detail:
                            'Usada nos critérios de avaliação; perfil de 0 a L',
                      ),
                      AuditRow(
                        'Pp slide (Lmi−IRN)/Lm',
                        balanco.perdaPercolacaoSlidePercentual == null
                            ? 'Não aplicável sob déficit'
                            : '${balanco.perdaPercolacaoSlidePercentual!.toStringAsFixed(2)}%',
                      ),
                      AuditRow(
                        'Déficit espacial',
                        '${balanco.deficitMm.toStringAsFixed(2)} mm',
                        detail: 'IRN = lâmina útil + déficit',
                      ),
                    ],
                    AuditRow(
                      'Uniformidade de Christiansen (CUC)',
                      '${result.cuc.toStringAsFixed(2)}%',
                      detail: result.classificacaoCuc,
                    ),
                    AuditRow(
                      'Uniformidade de distribuição (DU)',
                      '${result.du.toStringAsFixed(2)}%',
                      detail: result.classificacaoDu,
                    ),
                    if (result.eficienciaDistribuicaoEd != null)
                      AuditRow(
                        'Eficiência de distribuição (Ed)',
                        '${result.eficienciaDistribuicaoEd!.toStringAsFixed(2)}%',
                        detail: 'Lf / [(Li + Lf) / 2] × 100',
                      ),
                    if (result.adequacaoUtilGa != null)
                      AuditRow(
                        'Adequação útil (GA)',
                        '${result.adequacaoUtilGa!.toStringAsFixed(2)}%',
                        detail: 'Lâmina útil limitada à requerida; máximo 100%',
                      ),
                    AuditRow(
                      'Lâmina média infiltrada (Lmi)',
                      '${(result.laminaMedia * 1000).toStringAsFixed(2)} mm',
                    ),
                    AuditRow(
                      'Tempo de avanço',
                      '${result.tempoAvanco.toStringAsFixed(2)} min',
                    ),
                    AuditRow(
                      result.balancoSulco == null
                          ? 'Perda por percolação'
                          : 'Percolação integral',
                      '${result.perdaPercolacao.toStringAsFixed(2)}%',
                    ),
                    AuditRow(
                      result.balancoSulco == null
                          ? 'Perda por escoamento'
                          : state.manejoSulco == ManejoSulco.reduzida
                          ? 'Escoamento residual (cenário condicionado)'
                          : 'Escoamento integral',
                      '${result.perdaEscoamento.toStringAsFixed(2)}%',
                      detail: state.manejoSulco == ManejoSulco.reduzida
                          ? 'Pe = (Lm − Lmi) / Lm × 100; resíduo do balanço sob a hipótese de cobertura, não previsão hidráulica.'
                          : 'Pe integral = (Lm − Lmi) / Lm × 100; balanço válido',
                    ),
                    if (state.manejoSulco == ManejoSulco.reduzida) ...[
                      AuditRow(
                        'Tempo com vazão inicial',
                        '${result.metricas['Tempo com vazão inicial']?.toStringAsFixed(1) ?? 'Não calculado'}${result.metricas['Tempo com vazão inicial'] == null ? '' : ' min'}',
                        detail: 'Inclui avanço e atraso informado após Ta',
                      ),
                      AuditRow(
                        'Tempo com vazão reduzida',
                        '${result.metricas['Tempo com vazão reduzida']?.toStringAsFixed(1) ?? 'Não calculado'}${result.metricas['Tempo com vazão reduzida'] == null ? '' : ' min'}',
                        detail: 'As duas fases somam Ti/Tt',
                      ),
                    ],
                    AuditRow(
                      'Eficiência de requerimento (Er)',
                      '${result.eficienciaRequerimento.toStringAsFixed(2)}%',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AuditableSection(
                  title: 'Necessidade hídrica',
                  icon: AppIcons.projetoClima,
                  children: [
                    if (state.laminaRequeridaResultado != null) ...[
                      AuditRow(
                        'IRN',
                        '${state.laminaRequeridaResultado!.irnMm.toStringAsFixed(2)} mm',
                      ),
                      AuditRow(
                        'Demanda líquida',
                        '${state.laminaRequeridaResultado!.demandaLiquidaMmDia.toStringAsFixed(2)} mm/dia',
                      ),
                      AuditRow(
                        'Turno de rega (TR)',
                        '${state.laminaRequeridaResultado!.turnoCalculadoDias.toStringAsFixed(2)} dias (operacional: ${state.laminaRequeridaResultado!.turnoOperacionalDias} dias)',
                      ),
                    ] else ...[
                      const AuditRow('IRN', 'Não calculada'),
                      const AuditRow('Demanda líquida', 'Não calculada'),
                      const AuditRow('Turno de rega (TR)', 'Não calculado'),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                FurrowDetailsSection(state: state, result: result),
                const SizedBox(height: 16),
                if (result.planejamentoOperacional != null) ...[
                  OperationalPlanningSection(
                    planejamento: result.planejamentoOperacional!,
                  ),
                  const SizedBox(height: 16),
                ],
                AuditableSection(
                  title: 'Fórmulas utilizadas',
                  icon: Icons.functions_rounded,
                  children: [
                    FormulaCard(
                      formula: result.balancoSulco == null
                          ? 'Ea = (Lf / Lm) × 100'
                          : 'Ea slide = (Lf / Lm) × 100',
                      description: result.balancoSulco == null
                          ? 'Eficiência de aplicação: lâmina infiltrada no final (Lf) sobre lâmina média aplicada (Lm).'
                          : 'Indicador didático pelo final do sulco; não representa o fechamento volumétrico.',
                    ),
                    const FormulaCard(
                      formula: 'NTS = área / (C × E); NSD = NTS / período',
                      description: 'Número total de sulcos e sulcos que precisam ser irrigados por dia.',
                    ),
                    const FormulaCard(
                      formula:
                          'TIP = Ti + tmudParcela; NPD = piso(jornada / TIP)',
                      description: 'Ti/Tt é o fornecimento por sulco; tmudParcela é o intervalo entre parcelas, separado do atraso de redução de vazão.',
                    ),
                    const FormulaCard(
                      formula: 'NSP = NSD / NPD; Qprojeto = NSP × qi + perdas',
                      description: 'A operação verifica lotes parciais no período, vazão disponível e se TIP cabe na jornada.',
                    ),
                    const FormulaCard(
                      formula: 'Ed = Lf / [(Li + Lf) / 2] × 100',
                      description: 'Eficiência de distribuição pelos extremos do perfil; não é a DU.',
                    ),
                    const FormulaCard(
                      formula: 'GA útil = média[min(Li(x), IRN)] / IRN × 100',
                      description: 'Adequação limitada a 100%; o excesso fica contabilizado como percolação.',
                    ),
                    const FormulaCard(
                      formula: 'Ea integral = Lútil/Lm; Pp integral = Lpercolada/Lm; Pe integral = (Lm−Lmi)/Lm',
                      description: 'Médias espaciais por trapézios de 0 a L: Lmi = Lútil + Lpercolada; IRN = Lútil + déficit. Balanço inconsistente impede o resultado.',
                    ),
                    FormulaCard(
                      formula: state.manejoSulco == ManejoSulco.reduzida
                          ? 'Lm = [qi·tInicial + qr·tReduzido] × 60 / (C·E)'
                          : 'Lm = q·Tt × 60 / (C·E)',
                      description: 'Vazão em L/s, tempos em min, comprimento e espaçamento em m; lâmina em mm.',
                    ),
                    FormulaCard(
                      formula: 'CUC = (1 - Σ|yi - ȳ| / (n × ȳ)) × 100',
                      description: 'Uniformidade de Christiansen baseada na média absoluta dos desvios.',
                    ),
                    FormulaCard(
                      formula: 'DU = (L25 / ȳ) × 100',
                      description: 'Uniformidade de distribuição: média dos 25% menores sobre a média.',
                    ),
                    FormulaCard(
                      formula: 'Tx = k × x^b',
                      description: 'Curva de avanço: tempo na distância x.',
                    ),
                    if (state.origemCurvaInfiltracao ==
                        OrigemCurvaInfiltracao.equacaoAcumuladaInformada)
                      const FormulaCard(
                        formula: 'I(To) = aI × Toⁿ',
                        description: 'Equação acumulada informada; aI em mm/minⁿ e To em min.',
                      ),
                    if (state.origemCurvaInfiltracao ==
                        OrigemCurvaInfiltracao.ensaioEntradaSaida) ...[
                      const FormulaCard(
                        formula: 'VI(T) = K × Tⁿ',
                        description:
                            'Taxa ajustada ao ensaio; K em mm/h e T em min.',
                      ),
                      const FormulaCard(
                        formula: 'I(T) = [K/(60×(n+1))] × T^(n+1)',
                        description: 'Integração da taxa para formar a lâmina acumulada em mm.',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                if (result.alertaVazaoExcedida != null)
                  AlertBanner(message: result.alertaVazaoExcedida!),
                const SizedBox(height: 16),
                SaveCard(
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

// ──────────────────────── CSV Builder ────────────────────────

String _buildCsv(EstadoParametrosSulco state, SimulationResult result) {
  final rows = <String>[
    'grupo;indicador;valor;unidade',
    'identificação;método;Sulco;',
    'entrada;comprimento;${state.comprimento};m',
    'entrada;declividade longitudinal;${state.declividade};m/m',
    'entrada;desnível longitudinal;${state.desnivelM};m',
    'entrada;distância longitudinal;${state.distanciaHorizontalM};m',
    'entrada;desnível transversal;${state.desnivelTransversalM};m',
    'entrada;distância transversal;${state.distanciaTransversalM};m',
    'entrada;textura solo;${state.texturaSolo.displayName};',
    'entrada;coeficiente infiltração k;${state.k};',
    'entrada;expoente a;${state.a};',
    if (state.origemAvanco == OrigemAvanco.estimativa) ...[
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
    'entrada;área efetiva;${state.areaHectares};ha',
    'entrada;período de irrigação;${state.periodoIrrigacaoDias};dias',
    'entrada;tempo entre parcelas;${state.tempoMudancaParcelaMin};min',
    'entrada;jornada diária;${state.jornadaDiariaH};h/dia',
    'entrada;vazão disponível;${state.vazaoDisponivelLps};L/s',
    'entrada;perdas de condução;${state.perdasConducaoLs};L/s',
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
      'resultado;Ea integral (Lútil/Lm);${balanco.eficienciaAplicacaoIntegralPercentual};%',
      'resultado;Pp slide (Lmi−IRN)/Lm;${balanco.perdaPercolacaoSlidePercentual?.toString() ?? 'não aplicável'};%',
      'resultado;Pp integral;${balanco.perdaPercolacaoIntegralPercentual};%',
      'resultado;Pe integral;${balanco.perdaEscoamentoIntegralPercentual};%',
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
      state.metodoCurvaAvanco == MetodoAjusteAvanco.doisPontos &&
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
