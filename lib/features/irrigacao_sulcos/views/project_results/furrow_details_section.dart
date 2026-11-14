import 'package:material_ui/material_ui.dart';
import 'package:irrigasim/core/theme/app_icons.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';
import 'package:irrigasim/features/irrigacao_sulcos/views/project_results/detail_sub_section.dart';

/// Seção "Dados do sulco": manejo, vazão/erosão, fases hidráulicas e lâminas.
class FurrowDetailsSection extends StatelessWidget {
  const FurrowDetailsSection({
    super.key,
    required this.state,
    required this.result,
  });
  final EstadoParametrosSulco state;
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
            DetailSubSection(
              title: 'Manejo',
              rows: [
                IrrigationAuditRow(
                  'Tipo de manejo',
                  state.manejoSulco.displayName,
                ),
                if (state.manejoSulco == ManejoSulco.reduzida) ...[
                  IrrigationAuditRow(
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
                    IrrigationAuditRow(
                      'VIB usada em F23',
                      '${result.metricas['VIB usada na redução']?.toStringAsFixed(2) ?? '—'} mm/h',
                    ),
                  if (result.metricas['Demanda espacial no instante da troca']
                      case final demanda?)
                    IrrigationAuditRow(
                      'Demanda espacial na troca',
                      '${demanda.toStringAsFixed(3)} L/s',
                      detail:
                          'F24 (p.96), taxas integradas nas estacas do ensaio.',
                    ),
                  IrrigationAuditRow(
                    'Atraso após avanço',
                    '${state.tempoMudancaMin.toStringAsFixed(0)} min',
                  ),
                  const IrrigationAuditRow(
                    'Hipótese hidráulica',
                    'Perfil condicionado à cobertura após a redução',
                    detail: 'Sem nova curva medida, a redução não prevê o avanço nem o escoamento hidráulico (§6.7).',
                  ),
                ],
                if (state.manejoSulco == ManejoSulco.surtir) ...[
                  IrrigationAuditRow(
                    'Ciclo de surtirção',
                    '${state.cicloSurtirMin.toStringAsFixed(0)} min',
                  ),
                  IrrigationAuditRow(
                    'Pausa',
                    '${state.tempoMudancaMin.toStringAsFixed(0)} min',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Vazão e erosão
            DetailSubSection(
              title: 'Vazão e erosão',
              rows: [
                IrrigationAuditRow(
                  'Vazão aplicada',
                  '${state.vazao.toStringAsFixed(2)} L/s',
                ),
                IrrigationAuditRow(
                  'Vazão máxima não erosiva',
                  qmaxMetric != null
                      ? '${qmaxMetric.toStringAsFixed(3)} L/s'
                      : '—',
                  detail:
                      'Textura: ${state.texturaSolo.displayName} — qmax = C / S0^a',
                ),
                IrrigationAuditRow(
                  'Status da vazão',
                  state.vazao <= (qmaxMetric ?? double.infinity)
                      ? 'Dentro do limite'
                      : 'Erosiva (excede qmax)',
                  isWarning: state.vazao > (qmaxMetric ?? double.infinity),
                ),
                if (state.ensaioErosao case final ensaio?)
                  IrrigationAuditRow(
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
            DetailSubSection(
              title: 'Fases hidráulicas',
              rows: [
                IrrigationAuditRow(
                  'Tempo de avanço (ta)',
                  '${ta.toStringAsFixed(1)} min',
                  detail: 'Até o final do sulco',
                ),
                IrrigationAuditRow(
                  'Tempo de infiltração (ti)',
                  '${ti.toStringAsFixed(1)} min',
                  detail: 'Reposição após avanço',
                ),
                IrrigationAuditRow(
                  'Tempo de oportunidade (To)',
                  '${to.toStringAsFixed(0)} min',
                  detail: 'No final do sulco',
                ),
                IrrigationAuditRow(
                  'Tempo total de aplicação (Tt)',
                  '${(appTime ?? (ta + to)).toStringAsFixed(0)} min',
                  detail: 'Ta + To',
                ),
                IrrigationAuditRow(
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
            DetailSubSection(
              title: 'Lâminas',
              rows: [
                IrrigationAuditRow(
                  'Lâmina requerida',
                  '${state.laminaRequerida.toStringAsFixed(0)} mm',
                ),
                IrrigationAuditRow(
                  'Lâmina aplicada (média)',
                  laminaAplicada != null
                      ? '${laminaAplicada.toStringAsFixed(1)} mm'
                      : '—',
                ),
                IrrigationAuditRow(
                  'Lâmina infiltrada (início)',
                  '${laminaInicio.toStringAsFixed(1)} mm',
                  detail: laminaInicio > state.laminaRequerida * 1.2
                      ? 'Excesso no início'
                      : null,
                  isWarning: laminaInicio > state.laminaRequerida * 1.2,
                ),
                IrrigationAuditRow(
                  'Lâmina infiltrada (final)',
                  '${laminaFinal.toStringAsFixed(1)} mm',
                  detail: laminaFinal < state.laminaRequerida * 0.8
                      ? 'Déficit no final'
                      : null,
                  isWarning: laminaFinal < state.laminaRequerida * 0.8,
                ),
                IrrigationAuditRow(
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
