// Gráficos do resultado de inundação (Fase 6), em abas. Espelha a migração
// de faixas: gráficos genéricos do `shared/irrigacao/widgets/charts` com a
// aba opcional de comparação de cenários (primeira vs terceira irrigação).
import 'package:material_ui/material_ui.dart';
import 'package:irrigasim/core/theme/app_icons.dart';
import 'package:irrigasim/features/irrigacao_inundacao/viewmodels/basin_project_controller.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_chart_section.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/advance_chart.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/infiltration_chart.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/performance_bars_chart.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/scenario_comparison_chart.dart';
import 'package:irrigasim/shared/irrigacao/widgets/charts/water_balance_chart.dart';

/// Abas de gráficos do resultado de inundação.
class BasinCharts extends StatefulWidget {
  const BasinCharts({super.key, required this.result, this.comparison});

  final SimulationResult result;
  final BasinScenarioComparison? comparison;

  @override
  State<BasinCharts> createState() => _BasinChartsState();
}

class _BasinChartsState extends State<BasinCharts> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final comparison = widget.comparison;
    final tabs = <IrrigationChartTab>[
      const IrrigationChartTab(
        label: 'Avanço',
        icon: AppIcons.curvaAvanco,
      ),
      const IrrigationChartTab(
        label: 'Infiltração',
        icon: AppIcons.projetoSolo,
      ),
      const IrrigationChartTab(
        label: 'Balanço',
        icon: AppIcons.balancoHidrico,
      ),
      const IrrigationChartTab(
        label: 'Indicadores',
        icon: AppIcons.indicadores,
      ),
      if (comparison != null)
        const IrrigationChartTab(
          label: 'Comparação',
          icon: AppIcons.comparar,
        ),
    ];
    final charts = <Widget>[
      AdvanceChart(resultado: widget.result),
      InfiltrationChart(resultado: widget.result),
      WaterBalanceChart(resultado: widget.result),
      PerformanceBarsChart(resultado: widget.result),
      if (comparison != null)
        ScenarioComparisonChart(
          resultadoA: comparison.primeira,
          resultadoB: comparison.terceira,
          labelA: 'Primeira irrigação',
          labelB: 'Terceira irrigação',
        ),
    ];
    return IrrigationChartSection(
      title: 'Gráficos',
      tabs: tabs,
      selectedIndex: _selectedIndex,
      onTabSelected: (index) => setState(() => _selectedIndex = index),
      children: charts,
    );
  }
}
