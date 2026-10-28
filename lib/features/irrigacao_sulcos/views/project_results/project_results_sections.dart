import 'package:flutter/material.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/shared/irrigacao/models/irrigation_parameters.dart';
import 'package:irrigasim/shared/irrigacao/models/simulation_result.dart';
import 'package:irrigasim/features/irrigacao_sulcos/viewmodels/controlador_parametros_sulco.dart';
import 'package:irrigasim/shared/irrigacao/services/operational_planning.dart';

import 'project_results_widgets.dart';

// ──────────────────────── Furrow Details Section ────────────────────────

class OperationalPlanningSection extends StatelessWidget {
  const OperationalPlanningSection({super.key, required this.planejamento});

  final PlanejamentoOperacionalResultado planejamento;

  @override
  Widget build(BuildContext context) {
    final p = planejamento;
    final viable = p.agendaViavel && p.vazaoDisponivelSuficiente;
    return AuditableSection(
      title: 'Planejamento operacional por parcela',
      icon: Icons.calendar_month_rounded,
      children: [
        AuditRow(
          'Área efetiva',
          '${p.areaTotalM2.toStringAsFixed(0)} m² (${p.areaHectares.toStringAsFixed(2)} ha)',
        ),
        AuditRow(
          'Sulcos totais (NTS)',
          '${p.ntsOperacional} (teórico ${p.ntsTeorico.toStringAsFixed(2)})',
        ),
        AuditRow(
          'Sulcos por dia (NSD)',
          '${p.nsdOperacional} (teórico ${p.nsdTeorico.toStringAsFixed(2)})',
          detail: 'Sulcos a irrigar por dia para cumprir o turno de rega.',
        ),
        AuditRow(
          'Tempo por parcela (TIP)',
          '${p.tipH.toStringAsFixed(4)} h (${(p.tipH * 60).toStringAsFixed(1)} min)',
          detail: 'Ti/Tt + tempo entre parcelas',
        ),
        AuditRow(
          'Parcelas completas por dia (NPD)',
          p.npdOperacional == 0
              ? 'Nenhuma'
              : '${p.npdOperacional} (teórico ${p.npdTeorico.toStringAsFixed(2)})',
          detail: 'Grupos operacionais na jornada, não frequência agronômica.',
        ),
        AuditRow(
          'Sulcos simultâneos (NSP)',
          '${p.nspOperacional} (teórico ${p.nspTeorico.toStringAsFixed(2)})',
        ),
        AuditRow(
          'Dias necessários',
          '${p.diasNecessariosOperacional} de ${p.periodoIrrigacaoDias} dias',
          isWarning: !p.agendaViavel,
        ),
        AuditRow(
          'Vazão de projeto',
          '${p.qProjetoOperacional.toStringAsFixed(2)} L/s (teórico ${p.qProjetoTeorico.toStringAsFixed(2)} L/s)',
          isWarning: !p.vazaoDisponivelSuficiente,
          detail: p.vazaoDisponivelLs == null
              ? null
              : 'Disponível: ${p.vazaoDisponivelLs!.toStringAsFixed(2)} L/s',
        ),
        AuditRow(
          'Viabilidade operacional',
          viable ? 'Viável no período e na vazão disponível' : 'Inviável',
          detail: p.motivoInviabilidade,
          isWarning: !viable,
        ),
      ],
    );
  }
}

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
                AuditRow('Tipo de manejo', state.manejoSulco.displayName),
                if (state.manejoSulco == ManejoSulco.reduzida) ...[
                  AuditRow(
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
                    AuditRow(
                      'VIB usada em F23',
                      '${result.metricas['VIB usada na redução']?.toStringAsFixed(2) ?? '—'} mm/h',
                    ),
                  if (result.metricas['Demanda espacial no instante da troca']
                      case final demanda?)
                    AuditRow(
                      'Demanda espacial na troca',
                      '${demanda.toStringAsFixed(3)} L/s',
                      detail:
                          'F24 (p.96), taxas integradas nas estacas do ensaio.',
                    ),
                  AuditRow(
                    'Atraso após avanço',
                    '${state.tempoMudancaMin.toStringAsFixed(0)} min',
                  ),
                  const AuditRow(
                    'Hipótese hidráulica',
                    'Perfil condicionado à cobertura após a redução',
                    detail: 'Sem nova curva medida, a redução não prevê o avanço nem o escoamento hidráulico (§6.7).',
                  ),
                ],
                if (state.manejoSulco == ManejoSulco.surtir) ...[
                  AuditRow(
                    'Ciclo de surtirção',
                    '${state.cicloSurtirMin.toStringAsFixed(0)} min',
                  ),
                  AuditRow(
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
                AuditRow(
                  'Vazão aplicada',
                  '${state.vazao.toStringAsFixed(2)} L/s',
                ),
                AuditRow(
                  'Vazão máxima não erosiva',
                  qmaxMetric != null
                      ? '${qmaxMetric.toStringAsFixed(3)} L/s'
                      : '—',
                  detail:
                      'Textura: ${state.texturaSolo.displayName} — qmax = C / S0^a',
                ),
                AuditRow(
                  'Status da vazão',
                  state.vazao <= (qmaxMetric ?? double.infinity)
                      ? 'Dentro do limite'
                      : 'Erosiva (excede qmax)',
                  isWarning: state.vazao > (qmaxMetric ?? double.infinity),
                ),
                if (state.ensaioErosao case final ensaio?)
                  AuditRow(
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
                AuditRow(
                  'Tempo de avanço (ta)',
                  '${ta.toStringAsFixed(1)} min',
                  detail: 'Até o final do sulco',
                ),
                AuditRow(
                  'Tempo de infiltração (ti)',
                  '${ti.toStringAsFixed(1)} min',
                  detail: 'Reposição após avanço',
                ),
                AuditRow(
                  'Tempo de oportunidade (To)',
                  '${to.toStringAsFixed(0)} min',
                  detail: 'No final do sulco',
                ),
                AuditRow(
                  'Tempo total de aplicação (Tt)',
                  '${(appTime ?? (ta + to)).toStringAsFixed(0)} min',
                  detail: 'Ta + To',
                ),
                AuditRow(
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
                AuditRow(
                  'Lâmina requerida',
                  '${state.laminaRequerida.toStringAsFixed(0)} mm',
                ),
                AuditRow(
                  'Lâmina aplicada (média)',
                  laminaAplicada != null
                      ? '${laminaAplicada.toStringAsFixed(1)} mm'
                      : '—',
                ),
                AuditRow(
                  'Lâmina infiltrada (início)',
                  '${laminaInicio.toStringAsFixed(1)} mm',
                  detail: laminaInicio > state.laminaRequerida * 1.2
                      ? 'Excesso no início'
                      : null,
                  isWarning: laminaInicio > state.laminaRequerida * 1.2,
                ),
                AuditRow(
                  'Lâmina infiltrada (final)',
                  '${laminaFinal.toStringAsFixed(1)} mm',
                  detail: laminaFinal < state.laminaRequerida * 0.8
                      ? 'Déficit no final'
                      : null,
                  isWarning: laminaFinal < state.laminaRequerida * 0.8,
                ),
                AuditRow(
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

class DetailSubSection extends StatelessWidget {
  const DetailSubSection({super.key, required this.title, required this.rows});
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

// ──────────────────────── Save Card ────────────────────────

class SaveCard extends StatelessWidget {
  const SaveCard({
    super.key,
    required this.state,
    required this.saving,
    required this.onNameChanged,
    required this.onSave,
  });
  final EstadoParametrosSulco state;
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
                    'Sulco - ${state.comprimento.toStringAsFixed(0)} m (${state.vazao.toStringAsFixed(2)} L/s)',
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
