import 'package:flutter/material.dart';
import 'package:irrigasim/core/theme/app_colors.dart';
import 'package:irrigasim/core/theme/app_icons.dart';
import 'package:irrigasim/features/irrigacao_sulcos/models/indicadores_balanco.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/advance_chart.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/infiltration_chart.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/water_balance_chart.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/opportunity_time_chart.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/performance_bars_chart.dart';
import 'package:irrigasim/features/irrigacao_sulcos/views/widgets/depth_along_furrow_chart.dart';
import 'package:irrigasim/features/irrigacao_sulcos/views/project_results/scenario_comparison.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_chart_section.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_feedback.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_kpi.dart';

/// Banner de recomendação de desempenho do sulco.
class RecommendationBanner extends StatelessWidget {
  const RecommendationBanner({
    super.key,
    required this.state,
    required this.result,
  });
  final EstadoParametrosSulco state;
  final SimulationResult result;

  @override
  Widget build(BuildContext context) {
    final good =
        result.alertaVazaoExcedida == null &&
        (result.balancoSulco?.eficienciaAplicacaoIntegralPercentual ??
                result.eficiencia) >=
            85 &&
        result.cuc >= 80 &&
        result.du >= 65;

    final title = good ? 'Desempenho satisfatório' : 'Otimização recomendada';
    final message =
        result.alertaVazaoExcedida ??
        (good
            ? 'O dimensionamento atende a bons critérios de eficiência e uniformidade.'
            : 'Revise os parâmetros para melhorar o desempenho.');

    return IrrigationBanner(
      title: title,
      message:
          'Sulco: L = ${state.comprimento.toStringAsFixed(0)} m, '
          'Q = ${state.vazao.toStringAsFixed(2)} L/s por ${(result.tempoFornecimentoMin ?? state.tempoAplicacao).toStringAsFixed(0)} min. '
          '${result.balancoSulco == null ? 'Ea' : 'Ea integral'} = ${(result.balancoSulco?.eficienciaAplicacaoIntegralPercentual ?? result.eficiencia).toStringAsFixed(1)}%, CUC = ${result.cuc.toStringAsFixed(1)}%.\n$message',
      icon: good ? AppIcons.sucesso : AppIcons.atencao,
      tone: good
          ? IrrigationBannerTone.success
          : IrrigationBannerTone.warning,
      semanticsLabel: title,
    );
  }
}

/// Grade de KPIs do resultado do sulco.
class KpiGrid extends StatelessWidget {
  const KpiGrid({super.key, required this.result});
  final SimulationResult result;

  @override
  Widget build(BuildContext context) {
    final items = [
      IrrigationKpiItem(
        titulo: result.balancoSulco == null ? 'Eficiência Ea' : 'Ea integral',
        valor: (result.balancoSulco?.eficienciaAplicacaoIntegralPercentual ??
                result.eficiencia)
            .toStringAsFixed(1),
        unidade: '%',
        subtitulo: result.classificacaoEaIntegral,
        color: AppColors.sulco,
      ),
      IrrigationKpiItem(
        titulo: 'Uniformidade CUC',
        valor: result.cuc.toStringAsFixed(1),
        unidade: '%',
        subtitulo: result.classificacaoCuc,
        color: AppColors.sulco,
      ),
      IrrigationKpiItem(
        titulo: 'Distribuição DU',
        valor: result.du.toStringAsFixed(1),
        unidade: '%',
        subtitulo: result.classificacaoDu,
        color: AppColors.sulco,
      ),
      IrrigationKpiItem(
        titulo: 'Lâmina média',
        valor: (result.laminaMedia * 1000).toStringAsFixed(1),
        unidade: 'mm',
        subtitulo: 'Infiltrada (Lmi)',
        color: AppColors.sulco,
      ),
      IrrigationKpiItem(
        titulo: 'Tempo de avanço',
        valor: result.tempoAvanco.toStringAsFixed(0),
        unidade: 'min',
        subtitulo: 'Até o final',
        color: AppColors.sulco,
      ),
      IrrigationKpiItem(
        titulo: 'Er',
        valor: result.eficienciaRequerimento.toStringAsFixed(1),
        unidade: '%',
        subtitulo: 'Eficiência de requerimento',
        color: AppColors.sulco,
      ),
    ];
    return IrrigationKpiGrid(items: items);
  }
}

/// Abas do card de gráficos de sulcos.
const sulcoChartTabs = [
  IrrigationChartTab(label: 'Balanço', icon: AppIcons.balancoHidrico),
  IrrigationChartTab(label: 'Avanço', icon: AppIcons.curvaAvanco),
  IrrigationChartTab(label: 'Infiltração', icon: AppIcons.perfilInfiltracao),
  IrrigationChartTab(label: 'Oportunidade', icon: AppIcons.oportunidade),
  IrrigationChartTab(label: 'Desempenho', icon: AppIcons.indicadores),
  IrrigationChartTab(label: 'Lâmina', icon: AppIcons.lamina),
  IrrigationChartTab(label: 'Comparação', icon: AppIcons.comparar),
];

/// Gráficos de sulcos, na ordem das abas.
List<Widget> sulcoChartChildren(SimulationResult result) => [
  WaterBalanceChart(resultado: result),
  AdvanceChart(resultado: result),
  InfiltrationChart(resultado: result),
  OpportunityTimeChart(resultado: result),
  PerformanceBarsChart(resultado: result),
  DepthAlongFurrowChart(resultado: result),
  ScenarioComparison(resultadoAtual: result),
];
