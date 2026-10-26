// Tela de resultado do projeto de inundação (Fase 6). Espelha
// lib/views/irrigation/faixas/border_results_screen.dart: banner de status,
// gráficos genéricos, seções auditáveis, exportação CSV e salvamento de
// cenário, com anexos exclusivos do regime (planejamento em parcelas,
// seleção de vazão e volumes do arroz).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/router/app_routes.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/core/widgets/kpi_card.dart';
import 'package:irrigasim/shared/irrigacao/models/comum/clima_demanda.dart';
import 'package:irrigasim/shared/irrigacao/models/validacao_superficie.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/basin_project.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/features/irrigacao_inundacao/services/basin_csv.dart';
import 'package:irrigasim/features/irrigacao_inundacao/viewmodels/basin_project_controller.dart';
import 'package:irrigasim/shared/cenarios/controllers/salvar_cenario_controller.dart';
import 'package:irrigasim/features/irrigacao_inundacao/views/basin_reference_panel.dart';
import 'package:irrigasim/shared/irrigacao/widgets/terrain/terrain_view.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/advance_chart.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/infiltration_chart.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_project_components.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/performance_bars_chart.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/scenario_comparison_chart.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/water_balance_chart.dart';

/// Ícone por status do impedimento do modelo (G1/G2/G9).
IconData iconeStatusBasin(BorderStatus status) => switch (status) {
  BorderStatus.validoNoModelo => AppIcons.sucesso,
  BorderStatus.avisoOrientativo => AppIcons.atencao,
  _ => AppIcons.statusBloqueio,
};

/// Texto humano por status; o código canônico fica na seção de auditoria.
String textoStatusBasin(BorderStatus status) => switch (status) {
  BorderStatus.validoNoModelo =>
    'Cálculo concluído dentro do modelo da Aula 8; nenhuma ressalva.',
  BorderStatus.avisoOrientativo =>
    'Cálculo concluído; há recomendação orientativa de referência.',
  BorderStatus.entradaInvalida =>
    'Há entrada pendente ou inválida; complete os dados faltantes.',
  BorderStatus.foraDoDominio =>
    'Geometria ou regime fora do domínio aceito pelo modelo.',
  _ => 'Há ressalva registrada pelo modelo; trate o resultado com cautela.',
};

class BasinResultsScreen extends ConsumerWidget {
  const BasinResultsScreen({
    super.key,
    this.projectOverride,
    this.resultOverride,
  });

  final BasinProject? projectOverride;
  final SimulationResult? resultOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = resultOverride ?? ref.watch(basinProjectResultProvider);
    final BasinProject project =
        projectOverride ?? ref.watch(basinProjectProvider);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultado de inundação')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.inundacao,
                    size: 48,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum cálculo de inundação disponível',
                    style: text.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Volte ao projeto para revisar os dados e calcular a irrigação.',
                    style: text.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(AppIcons.etapasAnteriores),
                    label: const Text('Voltar ao projeto'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final r = result;
    final status = project.impedimento?.status ?? BorderStatus.validoNoModelo;
    final comparison = projectOverride == null
        ? ref.watch(basinScenarioComparisonProvider)
        : null;
    final save = ref.watch(resultsProvider);
    String f(double? v, {int casas = 2}) =>
        v == null ? '—' : v.toStringAsFixed(casas);
    String m(String chave) {
      final v = r.metricas[chave];
      if (v == null) return '—';
      final unidade = r.unidadesMetricas[chave];
      return unidade == null || unidade.isEmpty ? f(v) : '${f(v)} $unidade';
    }

    Widget row(
      String label,
      String value, {
      String? detail,
      bool warning = false,
      String? pagina,
    }) => IrrigationAuditRow(
      label,
      value,
      detail: detail,
      isWarning: warning,
      pagina: pagina,
    );
    Widget section(
      String title,
      List<Widget> children, {
      IconData? icon,
      bool advanced = false,
      String? pagina,
    }) => IrrigationAuditSection(
      title: title,
      icon: icon ?? AppIcons.relatorio,
      initiallyExpanded: !advanced,
      pagina: pagina,
      children: children,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado de inundação'),
        actions: [
          IconButton(
            tooltip: 'Referência — Aula 8',
            onPressed: () => context.push(AppRoutes.inundacaoReferencia),
            icon: const Icon(AppIcons.guiaDidatico),
          ),
          IconButton(
            tooltip: 'Exportar CSV',
            onPressed: () => _mostrarExportacao(context, basinCsv(project, r)),
            icon: const Icon(AppIcons.exportarDados),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BasinRecommendation(
                    status: status,
                    project: project,
                    result: r,
                  ),
                  const SizedBox(height: IrrigationSpacing.major),
                  _SectionTitle(title: 'Avanço', icon: AppIcons.curvaAvanco),
                  SizedBox(height: 340, child: AdvanceChart(resultado: r)),
                  const SizedBox(height: IrrigationSpacing.major),
                  _SectionTitle(
                    title: 'Infiltração',
                    icon: AppIcons.projetoSolo,
                  ),
                  SizedBox(height: 340, child: InfiltrationChart(resultado: r)),
                  const SizedBox(height: IrrigationSpacing.major),
                  _SectionTitle(
                    title: 'Balanço hídrico',
                    icon: AppIcons.balancoHidrico,
                  ),
                  SizedBox(height: 340, child: WaterBalanceChart(resultado: r)),
                  const SizedBox(height: IrrigationSpacing.major),
                  _SectionTitle(
                    title: 'Indicadores',
                    icon: AppIcons.indicadores,
                  ),
                  SizedBox(
                    height: 340,
                    child: PerformanceBarsChart(resultado: r),
                  ),
                  if (comparison != null) ...[
                    const SizedBox(height: IrrigationSpacing.major),
                    _SectionTitle(
                      title: 'Primeira × terceira irrigação',
                      icon: AppIcons.comparar,
                    ),
                    SizedBox(
                      height: 340,
                      child: ScenarioComparisonChart(
                        resultadoA: comparison.primeira,
                        resultadoB: comparison.terceira,
                        labelA: 'Primeira irrigação',
                        labelB: 'Terceira irrigação',
                      ),
                    ),
                  ],
                  const SizedBox(height: IrrigationSpacing.major),
                  TerrainView(
                    comprimentoM:
                        project.comprimentoAreaM ?? project.comprimentoM ?? 0,
                    larguraM: project.larguraAreaM ?? project.larguraM ?? 0,
                    espacamentoSulcosM: project.larguraM ?? 1,
                    declividadePercentual: (project.declividade ?? 0) * 100,
                    distributionName: 'tabuleiros',
                  ),
                  const SizedBox(height: IrrigationSpacing.major),
                  _SectionTitle(
                    title: 'Indicadores principais',
                    icon: AppIcons.indicadores,
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 720
                          ? 3
                          : constraints.maxWidth >= 480
                          ? 2
                          : 1;
                      final width =
                          (constraints.maxWidth - (columns - 1) * 12) / columns;
                      String unidade(String chave, String padrao) =>
                          r.unidadesMetricas[chave] ?? padrao;
                      final values =
                          <(String, String, String, String, IconData)>[
                            (
                              'Eficiência Ea',
                              f(r.eficiencia),
                              '%',
                              'Água aplicada aproveitada',
                              AppIcons.indicadores,
                            ),
                            (
                              'Eficiência Er',
                              f(r.eficienciaRequerimento),
                              '%',
                              'Atendimento da lâmina requerida',
                              AppIcons.indicadores,
                            ),
                            (
                              'Percolação Pp',
                              f(r.perdaPercolacao),
                              '%',
                              'Perda profunda',
                              AppIcons.balancoHidrico,
                            ),
                            (
                              'Escoamento Pe',
                              f(r.perdaEscoamento),
                              '%',
                              'Perda superficial',
                              AppIcons.balancoHidrico,
                            ),
                            (
                              'Tempo de avanço ta',
                              f(r.tempoAvanco),
                              'min',
                              'Até o final do tabuleiro',
                              AppIcons.curvaAvanco,
                            ),
                            (
                              'Tempo de oportunidade ti',
                              f(r.metricas['Tempo de oportunidade']),
                              unidade('Tempo de oportunidade', 'min'),
                              'Corte da irrigação',
                              AppIcons.curvaAvanco,
                            ),
                            (
                              'Lâmina aplicada',
                              f(r.metricas['Lâmina aplicada']),
                              unidade('Lâmina aplicada', 'mm'),
                              'Informada ao tabuleiro',
                              AppIcons.projetoSolo,
                            ),
                            (
                              'Lâmina média infiltrada',
                              f(r.metricas['Lâmina média infiltrada']),
                              unidade('Lâmina média infiltrada', 'mm'),
                              'Média ao longo do tabuleiro',
                              AppIcons.projetoSolo,
                            ),
                          ];
                      if (project.regime == TipoInundacao.intermitente) {
                        values
                          ..add((
                            'Vazão total aplicada',
                            f(r.metricas['Vazão total']),
                            unidade('Vazão total', 'L/s'),
                            'No tabuleiro',
                            AppIcons.inundacao,
                          ))
                          ..add((
                            'Vazão não-erosiva Q0max',
                            f(r.metricas['Vazão total máxima']),
                            unidade('Vazão total máxima', 'L/s'),
                            'Limite de erosão (p. 54)',
                            AppIcons.inundacao,
                          ));
                      } else {
                        values
                          ..add((
                            'Turno de rega',
                            f(r.metricas['Turno de rega']),
                            unidade('Turno de rega', 'dias'),
                            'PI do regime contínuo',
                            AppIcons.inundacao,
                          ))
                          ..add((
                            'Eficiência de condução',
                            f(r.metricas['Eficiência de condução']),
                            unidade('Eficiência de condução', '%'),
                            'Chegada da lâmina ao tabuleiro',
                            AppIcons.indicadores,
                          ));
                      }
                      return Wrap(
                        spacing: IrrigationSpacing.field,
                        runSpacing: IrrigationSpacing.field,
                        children: [
                          for (final item in values)
                            SizedBox(
                              width: width,
                              child: KpiCard(
                                titulo: item.$1,
                                valor: item.$2,
                                unidade: item.$3,
                                color: AppColors.inundacao,
                                subtitulo: item.$4,
                                icon: item.$5,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  section('Dados e hipóteses', [
                    row(
                      'Regime',
                      project.regime.displayName,
                      detail: 'Rótulo didático da Aula 8 (G8)',
                    ),
                    row(
                      'Cenário de infiltração',
                      '${project.cenarioInfiltracao.displayName} · '
                          'k = ${f(project.k, casas: 6)}, '
                          'a = ${f(project.a)}, '
                          'VIB = ${f(project.vibMMin, casas: 6)}',
                    ),
                    row(
                      'Documento de referência',
                      'Aula 8 — Irrigação por Inundação (UNIPAMPA)',
                    ),
                    row(
                      'Páginas-fonte',
                      '16, 17, 20, 34–35, 38, 45, 54–62, 64–84',
                    ),
                    row(
                      'Comprimento do tabuleiro',
                      '${f(project.comprimentoM)} m',
                    ),
                    row('Largura do tabuleiro', '${f(project.larguraM)} m'),
                    row('Área do tabuleiro', m('Área do tabuleiro')),
                    row(
                      'Declividade',
                      '${f(project.declividade, casas: 5)} m/m',
                    ),
                    row('Altura da taipa', '${f(project.alturaDiqueM)} m'),
                    row('Base da taipa', '${f(project.baseDiqueM)} m'),
                    row('Margem livre', '${f(project.margemLivreM)} m'),
                    row('k', '${f(project.k, casas: 6)} m/min^a'),
                    row('Expoente a', f(project.a, casas: 4)),
                    row('VIB', '${f(project.vibMMin, casas: 6)} m/min'),
                    row('Rugosidade de Manning n', f(project.rugosidadeN)),
                  ], icon: AppIcons.projetoArea),
                  section(
                    'Cultura e sistema radicular',
                    [
                      row(
                        'Cultura',
                        project.culturaEfetiva ?? 'Não informado',
                        detail:
                            'Nome usado pelo preset e pela demanda; vazio é '
                            'lacuna, não zero (G4).',
                        pagina: '63',
                      ),
                      row(
                        'Coeficiente da cultura Kc',
                        project.agronomia?.kc == null
                            ? 'Não informado'
                            : f(project.agronomia?.kc),
                        detail:
                            'Entra em ETc = ETo × Kc quando o método usa ETo.',
                        pagina: '63',
                      ),
                      row(
                        'Profundidade do sistema radicular z',
                        project.agronomia?.profundidadeRaizesCm == null
                            ? 'Não informado'
                            : '${f(project.agronomia?.profundidadeRaizesCm)} cm',
                        detail: 'Entra na IRN calculada (p. 63).',
                        pagina: '63',
                      ),
                      row(
                        'Fração de água disponível f',
                        project.agronomia?.fracaoDisponivel == null
                            ? 'Não informado'
                            : f(project.agronomia?.fracaoDisponivel),
                        detail: 'Entra na IRN calculada (p. 63).',
                        pagina: '63',
                      ),
                      if (project.regime == TipoInundacao.intermitente) ...[
                        row(
                          'Umidade na capacidade de campo UCC',
                          project.agronomia?.uccPercentual == null
                              ? 'Não informado'
                              : '${f(project.agronomia?.uccPercentual)} %',
                          detail: 'Entra na IRN calculada (p. 63).',
                          pagina: '63',
                        ),
                        row(
                          'Umidade no ponto de murcha UPMP',
                          project.agronomia?.upmpPercentual == null
                              ? 'Não informado'
                              : '${f(project.agronomia?.upmpPercentual)} %',
                          detail: 'Entra na IRN calculada (p. 63).',
                          pagina: '63',
                        ),
                        row(
                          'Densidade aparente Ds',
                          project.agronomia?.densidadeGcm3 == null
                              ? 'Não informado'
                              : '${f(project.agronomia?.densidadeGcm3)} g/cm³',
                          detail: 'Entra na IRN calculada (p. 63).',
                          pagina: '63',
                        ),
                      ],
                    ],
                    icon: AppIcons.projetoCultura,
                    pagina: '63',
                  ),
                  section(
                    'Clima e demanda',
                    [
                      row('Método da ETc', switch (project.metodoEtc) {
                        MetodoEtc.adotada => 'ETc adotada (digitação)',
                        MetodoEtc.etoVezesKc => 'ETo × Kc',
                        MetodoEtc.blaneyCriddle => 'Blaney–Criddle',
                      }, detail: 'Como o projeto define a demanda da cultura.'),
                      if (project.metodoEtc == MetodoEtc.etoVezesKc)
                        row(
                          'ETo',
                          project.etoMmDia == null
                              ? 'Não informado'
                              : '${f(project.etoMmDia)} mm/dia',
                          detail: 'Referência digitada; ETc = ETo × Kc.',
                        )
                      else if (project.metodoEtc == MetodoEtc.blaneyCriddle)
                        row(
                          'ETo (Blaney–Criddle)',
                          project.etoBlaneyCriddleMmDia == null
                              ? 'Não calculado'
                              : '${f(project.etoBlaneyCriddleMmDia)} mm/dia',
                          detail:
                              'Estimada com temperatura, latitude e mês; se '
                              'faltar entrada, não vira zero (G4).',
                        ),
                      row(
                        'ETc efetiva',
                        project.etcMmDia == null
                            ? 'Não calculado'
                            : '${f(project.etcMmDia)} mm/dia',
                        detail:
                            'Demanda da cultura adotada pelo balanço do '
                            'resultado.',
                      ),
                      row(
                        'Origem da precipitação',
                        switch (project.origemChuva) {
                          OrigemChuva.naoInformada => 'Não informada',
                          OrigemChuva.efetiva => 'Efetiva adotada',
                          OrigemChuva.observada => 'Efetiva observada',
                          OrigemChuva.provavel =>
                            'Provável (não convertida em efetiva)',
                        },
                        detail: project.origemChuva == OrigemChuva.provavel
                            ? 'Chuva provável registrada; não creditada como '
                                  'Pef sem método explícito.'
                            : null,
                        warning: project.origemChuva == OrigemChuva.provavel,
                      ),
                      row(
                        'Precipitação efetiva Pef',
                        project.precipitacaoEfetivaEfetivaMmDia == null
                            ? 'Não informado'
                            : '${f(project.precipitacaoEfetivaEfetivaMmDia)} '
                                  'mm/dia',
                        detail: 'Subtraída da ETc no balanço (F25–F32).',
                      ),
                      if (project.regime == TipoInundacao.intermitente) ...[
                        row(
                          'IRN efetiva '
                          '(${project.origemIrn == OrigemIrnBasin.informada ? 'informada' : 'calculada'})',
                          project.irnEfetivaMm == null
                              ? (project.origemIrn == OrigemIrnBasin.informada
                                    ? 'Não informado'
                                    : 'Não calculado')
                              : '${f(project.irnEfetivaMm)} mm',
                          detail:
                              'A informada prevalece sobre a calculada; a '
                              'origem é sempre exibida (G14).',
                          pagina: '63',
                        ),
                        if (project.laminaRequeridaMm != null &&
                            project.irnCalculadaMm != null &&
                            (project.laminaRequeridaMm! -
                                        project.irnCalculadaMm!)
                                    .abs() >
                                1e-6) ...[
                          row(
                            'IRN informada (prevalece, G14)',
                            '${f(project.laminaRequeridaMm)} mm',
                            detail:
                                'As duas IRNs são exibidas; nenhuma '
                                'sobrescreve a outra em silêncio.',
                            pagina: '63',
                          ),
                          row(
                            'IRN calculada (auditoria, G14)',
                            '${f(project.irnCalculadaMm)} mm',
                            detail: 'Somente auditoria nesta situação.',
                            pagina: '63',
                          ),
                        ],
                        row(
                          'TR = IRN / (ETc − Pef)',
                          project.turnoRegaIrnDias == null
                              ? 'Não calculado'
                              : '${f(project.turnoRegaIrnDias, casas: 1)} dias',
                          detail:
                              'Turno de rega pela demanda líquida; compare '
                              'com o intervalo (G12).',
                          pagina: '63',
                        ),
                      ] else ...[
                        row(
                          'IRN',
                          'Não aplicável',
                          detail:
                              'O regime contínuo não usa a lâmina requerida '
                              'intermitente (G8).',
                        ),
                        row(
                          'TR (turno de rega contínuo)',
                          r.metricas['Turno de rega'] == null
                              ? 'Não calculado'
                              : '${f(r.metricas['Turno de rega'], casas: 1)} '
                                    'dias',
                          detail:
                              'TR = DTA · Z · f / ETc; a ETc vem do clima e '
                              'os campos de camada estão na etapa de Cultura.',
                          pagina: '67',
                        ),
                      ],
                    ],
                    icon: AppIcons.projetoClima,
                    pagina: '63',
                  ),
                  if (project.regime == TipoInundacao.intermitente)
                    section('Operação intermitente', [
                      row(
                        'Lâmina requerida',
                        '${f(project.laminaRequeridaMm)} mm',
                      ),
                      row(
                        'Vazão total aplicada',
                        '${f(project.vazaoAplicadaLs)} L/s',
                      ),
                      row(
                        'Origem da vazão',
                        project.vazaoTotalLs == null
                            ? 'Q0max do p. 54 (sem candidata explícita)'
                            : 'Vazão informada no projeto',
                      ),
                      row(
                        'Vazão erosiva Vmax',
                        '${f(project.vmaxMMin, casas: 4)} m/min',
                      ),
                      row(
                        'ET do intervalo',
                        '${f(project.etIntermitenteMmDia)} mm/dia',
                      ),
                      row(
                        'Intervalo entre irrigações',
                        '${f(project.intervaloDias?.toDouble())} dias',
                      ),
                      if (project.candidatasVazaoLs.isNotEmpty)
                        row(
                          'Candidatas (p. 60)',
                          project.candidatasVazaoLs.map((v) => f(v)).join(', '),
                        ),
                    ], icon: AppIcons.projetoOperacao)
                  else
                    section('Operação contínua', [
                      row('Área irrigada', '${f(project.areaHectares)} ha'),
                      row('Porosidade', f(project.porosidade)),
                      row(
                        'Profundidade da camada',
                        '${f(project.profundidadeCamadaMm)} mm',
                      ),
                      row(
                        'Condutividade K0',
                        '${f(project.condutividadeHidraulicaMmDia)} mm/dia',
                      ),
                      row('DTA', '${f(project.dtaMmCm)} mm/cm'),
                      row(
                        'Fator de disponibilidade',
                        f(project.fatorDisponibilidade),
                      ),
                      row(
                        'Evapotranspiração',
                        '${f(project.evapotranspiracaoMmDia)} mm/dia',
                      ),
                      row(
                        'Lâmina superficial',
                        '${f(project.laminaSuperficialMm)} mm',
                      ),
                      row(
                        'Período de atendimento PI',
                        '${project.periodoDias} dias',
                      ),
                    ], icon: AppIcons.projetoOperacao),
                  if (r.checagemOperacional != null)
                    BasinOperationalCheckSection(
                      checagem: r.checagemOperacional!,
                      icon: AppIcons.projetoOperacao,
                    ),
                  if (r.planejamentoParcelas != null)
                    section('Planejamento em parcelas', [
                      row(
                        'Tempo por parcela TPP',
                        '${f(r.planejamentoParcelas!.tppMin)} min',
                      ),
                      row(
                        'NPD teórico',
                        '${f(r.planejamentoParcelas!.npdTeorico)} parcelas/dia',
                      ),
                      row(
                        'NPD adotado',
                        '${r.planejamentoParcelas!.npdInteiro} parcelas/dia',
                      ),
                      row(
                        'Área por parcela APP',
                        '${f(r.planejamentoParcelas!.appM2)} m²',
                      ),
                      row(
                        'Largura útil do tabuleiro w0',
                        '${f(r.planejamentoParcelas!.larguraTabuleiroM)} m',
                      ),
                      row(
                        'Tabuleiros na parcela (NTP)',
                        '${r.planejamentoParcelas!.tabuleirosPorParcela}',
                      ),
                      row(
                        'Total de tabuleiros NTT',
                        '${r.planejamentoParcelas!.ntt}',
                      ),
                      row(
                        'Vazão total Q',
                        '${f(r.planejamentoParcelas!.qTotalLS)} L/s',
                      ),
                    ], icon: AppIcons.projetoOperacao),
                  if (r.selecaoVazao != null)
                    section('Seleção de vazão (p. 60)', [
                      row(
                        'Vazão escolhida',
                        '${f(r.selecaoVazao!.vazaoEscolhidaLs)} L/s',
                      ),
                      row(
                        'Q0 da escolhida',
                        '${f(r.selecaoVazao!.q0M3MinM, casas: 4)} m³/(min·m)',
                      ),
                      row(
                        'Eficiência obtida',
                        '${f(r.selecaoVazao!.eficienciaPercent)}%',
                      ),
                      row(
                        'Candidatas avaliadas',
                        '${r.selecaoVazao!.candidatasAvaliadas}',
                      ),
                      row(
                        'Candidatas rejeitadas',
                        '${r.selecaoVazao!.candidatasRejeitadas}',
                        detail:
                            'Rejeição por erosão, geometria ou eficiência '
                            'abaixo da melhor opção',
                      ),
                    ], icon: AppIcons.comparar),
                  if (r.volumesArroz != null)
                    section('Volumes de água do arroz (p. 84)', [
                      row(
                        'Umidade do ponto de torrão PT',
                        f(r.volumesArroz!.volumes.pt),
                      ),
                      row(
                        'Umidade da saturação US',
                        f(r.volumesArroz!.volumes.us),
                      ),
                      row(
                        'V1 (sem dados gravimétricos)',
                        r.volumesArroz!.volumes.v1M3Ha == null
                            ? '—'
                            : '${f(r.volumesArroz!.volumes.v1M3Ha)} m³/ha',
                      ),
                      row('V2', '${f(r.volumesArroz!.volumes.v2M3Ha)} m³/ha'),
                      row('V3', '${f(r.volumesArroz!.volumes.v3M3Ha)} m³/ha'),
                      row('V4', '${f(r.volumesArroz!.volumes.v4M3Ha)} m³/ha'),
                      row(
                        'V5 (MS do saco)',
                        r.volumesArroz!.volumes.v5M3Ha == null
                            ? '—'
                            : '${f(r.volumesArroz!.volumes.v5M3Ha)} m³/ha',
                      ),
                      row(
                        'Volume total Vt',
                        r.volumesArroz!.volumes.vtM3Ha == null
                            ? '—'
                            : '${f(r.volumesArroz!.volumes.vtM3Ha)} m³/ha',
                      ),
                      row(
                        'Matéria seca total',
                        r.volumesArroz!.volumes.materiaSecaTotalKgHa == null
                            ? '—'
                            : '${f(r.volumesArroz!.volumes.materiaSecaTotalKgHa)} kg/ha',
                      ),
                      row(
                        'Vazão de enchimento Q1',
                        r.volumesArroz!.volumes.q1M3S == null
                            ? '—'
                            : '${f(r.volumesArroz!.volumes.q1M3S)} m³/s',
                        detail: r.volumesArroz!.volumes.q1M3S == null
                            ? 'Dado ausente na fonte; não presumido (G4).'
                            : 'Vazão calculada pelo método do arroz.',
                        warning: r.volumesArroz!.volumes.q1M3S == null,
                      ),
                      row(
                        'Vazão de manutenção Q2',
                        r.volumesArroz!.volumes.q2M3S == null
                            ? '—'
                            : '${f(r.volumesArroz!.volumes.q2M3S)} m³/s',
                        detail: r.volumesArroz!.volumes.q2M3S == null
                            ? 'Dado ausente na fonte; não presumido (G4).'
                            : 'Vazão calculada pelo método do arroz.',
                        warning: r.volumesArroz!.volumes.q2M3S == null,
                      ),
                      for (final ausente
                          in r.volumesArroz!.volumes.dadosAusentes)
                        row(
                          'Dado ausente na fonte',
                          ausente,
                          warning: true,
                          detail:
                              'Não presumido (G4); lacuna preservada da p. 84',
                        ),
                    ], icon: AppIcons.balancoHidrico),
                  BasinReferencePanel(projeto: project),
                  section(
                    'Métricas completas',
                    [
                      for (final chave in r.metricas.keys.toList()..sort())
                        row(chave, m(chave)),
                      if (r.alertaVazaoExcedida != null)
                        row(
                          'Alerta de vazão',
                          r.alertaVazaoExcedida!,
                          warning: true,
                        ),
                      if (r.alertaInfiltracao != null)
                        row(
                          'Alerta de infiltração',
                          r.alertaInfiltracao!,
                          warning: true,
                        ),
                    ],
                    icon: AppIcons.relatorio,
                    advanced: true,
                  ),
                  if (projectOverride == null &&
                      project.regime == TipoInundacao.intermitente &&
                      (project.dadosPrimeira != null ||
                          project.dadosTerceira != null))
                    section(
                      'Comparar cenários de infiltração',
                      [
                        Text(
                          'Simula separadamente a primeira e a terceira '
                          'irrigação com k, a e VIB próprios, pelo mesmo '
                          'motor da Aula 8.',
                          style: text.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            try {
                              final c = calcularComparacaoCenarios(project);
                              ref
                                      .read(
                                        basinScenarioComparisonProvider
                                            .notifier,
                                      )
                                      .state =
                                  c;
                            } on FormatException catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.message)),
                              );
                            }
                          },
                          icon: const Icon(AppIcons.comparar),
                          label: const Text('Comparar cenários'),
                        ),
                      ],
                      icon: AppIcons.comparar,
                      advanced: true,
                    ),
                  section('Salvar este projeto', [
                    TextField(
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Nome do cenário',
                        hintText:
                            'Inundação · ${project.regime.displayName} · '
                            'Ea ${f(r.eficiencia, casas: 1)}%',
                      ),
                      onChanged: ref
                          .read(resultsProvider.notifier)
                          .setNomeCenario,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed:
                          save.salvando || save.nomeCenario.trim().isEmpty
                          ? null
                          : () async {
                              await ref
                                  .read(resultsProvider.notifier)
                                  .salvarCenario(
                                    metodo: MetodoIrrigacao.inundacao,
                                    parametros: project.toCompatParameters(),
                                    resultado: r,
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ref.read(resultsProvider).erro ??
                                          'Cenário salvo.',
                                    ),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(AppIcons.salvarCenario),
                      label: Text(
                        save.salvando ? 'Salvando…' : 'Salvar cenário',
                      ),
                    ),
                  ], icon: AppIcons.salvarCenario),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(title, style: text.titleMedium),
        ],
      ),
    );
  }
}

class _BasinRecommendation extends StatelessWidget {
  const _BasinRecommendation({
    required this.status,
    required this.project,
    required this.result,
  });

  final BorderStatus status;
  final BasinProject project;
  final SimulationResult result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final blocked = status.bloqueia;
    final advisory = status == BorderStatus.avisoOrientativo;
    final background = blocked
        ? colors.errorContainer
        : advisory
        ? colors.tertiaryContainer
        : colors.primaryContainer;
    final foreground = blocked
        ? colors.onErrorContainer
        : advisory
        ? colors.onTertiaryContainer
        : colors.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconeStatusBasin(status), color: foreground, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blocked
                      ? 'Revise as ressalvas do modelo'
                      : advisory
                      ? 'Resultado com recomendações orientativas'
                      : 'Simulação concluída',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${project.regime.displayName} · '
                  'Ea = ${result.eficiencia.toStringAsFixed(1)}% · '
                  'ta = ${result.tempoAvanco.toStringAsFixed(1)} min · '
                  'Perfil com ${result.perfilLongitudinal.length} pontos.\n'
                  '${textoStatusBasin(status)}',
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

Future<void> _mostrarExportacao(BuildContext context, String csv) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Prévia do CSV da inundação',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .5,
              ),
              child: SingleChildScrollView(child: SelectableText(csv)),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: csv));
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(AppIcons.exportarDados),
              label: const Text('Copiar CSV'),
            ),
          ],
        ),
      ),
    ),
  );
}
