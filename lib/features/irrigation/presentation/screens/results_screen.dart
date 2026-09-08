import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/app/theme/app_text_styles.dart';
import 'package:irrigasim/features/irrigation/presentation/viewmodels/irrigation_view_model.dart';
import 'package:irrigasim/features/irrigation/presentation/viewmodels/parameters_view_model.dart';
import 'package:irrigasim/features/irrigation/presentation/viewmodels/results_view_model.dart';
import 'package:irrigasim/features/irrigation/presentation/widgets/water_balance_chart.dart';
import 'package:irrigasim/features/irrigation/presentation/widgets/advance_chart.dart';
import 'package:irrigasim/features/irrigation/presentation/widgets/infiltration_chart.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paramsState = ref.watch(parametersProvider);
    final resultsState = ref.watch(resultsProvider);
    final resultado = paramsState.resultado;

    if (resultado == null) {
      return const Scaffold(
        body: Center(child: Text('Execute uma simulação primeiro')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: () => _showSaveDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildKPICards(resultado),
          _buildTabs(ref, resultsState),
          Expanded(
            child: _buildChart(ref, resultsState.abaAtual, resultado),
          ),
          _buildRecommendation(resultado),
        ],
      ),
    );
  }

  Widget _buildKPICards(dynamic resultado) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.2,
        children: [
          _kpiCard('Ea', '${resultado.eficiencia.toStringAsFixed(1)}%', resultado.classificacaoEa),
          _kpiCard('Er', '${resultado.eficienciaRequerimento.toStringAsFixed(1)}%', ''),
          _kpiCard('CUC', '${resultado.cuc.toStringAsFixed(1)}%', resultado.classificacaoCuc),
          _kpiCard('DU', '${resultado.du.toStringAsFixed(1)}%', resultado.classificacaoDu),
          _kpiCard('Lâmina', '${(resultado.laminaMedia * 1000).toStringAsFixed(1)}', 'mm'),
          _kpiCard('Avanço', '${resultado.tempoAvanco.toStringAsFixed(0)}', 'min'),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, String classification) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppTextStyles.kpiLabel),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.kpiValue.copyWith(fontSize: 20)),
            if (classification.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                classification,
                style: AppTextStyles.bodySmall.copyWith(
                  color: _corClassificacao(classification),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _corClassificacao(String classificacao) {
    switch (classificacao) {
      case 'Excelente':
        return AppColors.excelent;
      case 'Bom':
        return AppColors.good;
      case 'Regular':
        return AppColors.regular;
      case 'Ruim':
        return AppColors.bad;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildTabs(WidgetRef ref, ResultsState state) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('Balanço')),
        ButtonSegment(value: 1, label: Text('Avanço')),
        ButtonSegment(value: 2, label: Text('Perfil')),
      ],
      selected: {state.abaAtual},
      onSelectionChanged: (selected) {
        ref.read(resultsProvider.notifier).setAba(selected.first);
      },
    );
  }

  Widget _buildChart(WidgetRef ref, int aba, dynamic resultado) {
    switch (aba) {
      case 0:
        return WaterBalanceChart(resultado: resultado);
      case 1:
        return AdvanceChart(resultado: resultado);
      case 2:
        return InfiltrationChart(resultado: resultado);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRecommendation(dynamic resultado) {
    String recomendacao;
    if (resultado.eficiencia >= 85 && resultado.cuc >= 80) {
      recomendacao = 'Excelente! A simulação atende aos critérios de eficiência.';
    } else if (resultado.eficiencia >= 75) {
      recomendacao = 'Bom. Considere ajustar a vazão para melhorar a uniformidade.';
    } else {
      recomendacao = 'Atenção. A eficiência está abaixo do ideal. Revise os parâmetros.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(recomendacao, style: AppTextStyles.body),
    );
  }

  void _showSaveDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final paramsState = ref.read(parametersProvider);
    final irrigationState = ref.read(irrigationProvider);
    final metodo = irrigationState.metodoSelecionado;
    final parametros = paramsState.toIrrigationParameters();
    final resultado = paramsState.resultado;

    if (metodo == null || resultado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Execute uma simulação primeiro')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salvar Cenário'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nome do cenário'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              ref.read(resultsProvider.notifier).setNomeCenario(controller.text);
              await ref.read(resultsProvider.notifier).salvarCenario(
                    metodo: metodo,
                    parametros: parametros,
                    resultado: resultado,
                  );
              if (context.mounted) {
                Navigator.pop(context);
                final erro = ref.read(resultsProvider).erro;
                if (erro != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(erro)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cenário salvo com sucesso!')),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
