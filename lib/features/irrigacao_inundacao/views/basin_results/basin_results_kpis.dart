// KPIs do resultado de inundação (Fase 6). Espelha a migração de faixas:
// `border_results_kpis.dart`. Os itens preservam os rótulos da tela original
// e o acento usa a cor da paleta de inundação.
import 'package:flutter/material.dart';
import 'package:irrigasim/core/theme/app_icons.dart';
import 'package:irrigasim/core/theme/app_colors.dart';
import 'package:irrigasim/features/irrigacao_inundacao/models/projeto_inundacao.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/shared/irrigacao/widgets/irrigation_kpi.dart';

/// Formatador comum das linhas auditáveis e dos KPIs de inundação.
String f(double? v, {int casas = 2}) => v == null ? '—' : v.toStringAsFixed(casas);

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

/// Indicadores principais do resultado de inundação, acento na cor da paleta.
class BasinKpis extends StatelessWidget {
  const BasinKpis({super.key, required this.project, required this.result});

  final ProjetoInundacao project;
  final SimulationResult result;

  @override
  Widget build(BuildContext context) {
    final r = result;
    return Builder(
      builder: (context) {
        String unidade(String chave, String padrao) =>
            r.unidadesMetricas[chave] ?? padrao;
        final values = <IrrigationKpiItem>[
          IrrigationKpiItem(
            titulo: 'Eficiência Ea',
            valor: f(r.eficiencia),
            unidade: '%',
            subtitulo: 'Água aplicada aproveitada',
            icon: AppIcons.indicadores,
          ),
          IrrigationKpiItem(
            titulo: 'Eficiência Er',
            valor: f(r.eficienciaRequerimento),
            unidade: '%',
            subtitulo: 'Atendimento da lâmina requerida',
            icon: AppIcons.indicadores,
          ),
          IrrigationKpiItem(
            titulo: 'Percolação Pp',
            valor: f(r.perdaPercolacao),
            unidade: '%',
            subtitulo: 'Perda profunda',
            icon: AppIcons.balancoHidrico,
          ),
          IrrigationKpiItem(
            titulo: 'Escoamento Pe',
            valor: f(r.perdaEscoamento),
            unidade: '%',
            subtitulo: 'Perda superficial',
            icon: AppIcons.balancoHidrico,
          ),
          IrrigationKpiItem(
            titulo: 'Tempo de avanço ta',
            valor: f(r.tempoAvanco),
            unidade: 'min',
            subtitulo: 'Até o final do tabuleiro',
            icon: AppIcons.curvaAvanco,
          ),
          IrrigationKpiItem(
            titulo: 'Tempo de oportunidade ti',
            valor: f(r.metricas['Tempo de oportunidade']),
            unidade: unidade('Tempo de oportunidade', 'min'),
            subtitulo: 'Corte da irrigação',
            icon: AppIcons.curvaAvanco,
          ),
          IrrigationKpiItem(
            titulo: 'Lâmina aplicada',
            valor: f(r.metricas['Lâmina aplicada']),
            unidade: unidade('Lâmina aplicada', 'mm'),
            subtitulo: 'Informada ao tabuleiro',
            icon: AppIcons.projetoSolo,
          ),
          IrrigationKpiItem(
            titulo: 'Lâmina média infiltrada',
            valor: f(r.metricas['Lâmina média infiltrada']),
            unidade: unidade('Lâmina média infiltrada', 'mm'),
            subtitulo: 'Média ao longo do tabuleiro',
            icon: AppIcons.projetoSolo,
          ),
        ];
        if (project.regime == TipoInundacao.intermitente) {
          values
            ..add(
              IrrigationKpiItem(
                titulo: 'Vazão total aplicada',
                valor: f(r.metricas['Vazão total']),
                unidade: unidade('Vazão total', 'L/s'),
                subtitulo: 'No tabuleiro',
                icon: AppIcons.inundacao,
              ),
            )
            ..add(
              IrrigationKpiItem(
                titulo: 'Vazão não-erosiva Q0max',
                valor: f(r.metricas['Vazão total máxima']),
                unidade: unidade('Vazão total máxima', 'L/s'),
                subtitulo: 'Limite de erosão',
                icon: AppIcons.inundacao,
              ),
            );
        } else {
          values
            ..add(
              IrrigationKpiItem(
                titulo: 'Turno de rega',
                valor: f(r.metricas['Turno de rega']),
                unidade: unidade('Turno de rega', 'dias'),
                subtitulo: 'PI do regime contínuo',
                icon: AppIcons.inundacao,
              ),
            )
            ..add(
              IrrigationKpiItem(
                titulo: 'Eficiência de condução',
                valor: f(r.metricas['Eficiência de condução']),
                unidade: unidade('Eficiência de condução', '%'),
                subtitulo: 'Chegada da lâmina ao tabuleiro',
                icon: AppIcons.indicadores,
              ),
            );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(
              title: 'Indicadores principais',
              icon: AppIcons.indicadores,
            ),
            IrrigationKpiGrid(
              items: [
                for (final item in values)
                  IrrigationKpiItem(
                    titulo: item.titulo,
                    valor: item.valor,
                    unidade: item.unidade,
                    color: AppColors.inundacao,
                    subtitulo: item.subtitulo,
                    icon: item.icon,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
