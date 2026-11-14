import 'package:material_ui/material_ui.dart';
import 'package:irrigasim/shared/irrigacao/services/operational_planning.dart';
import 'package:irrigasim/shared/irrigacao/widgets/auditable_widgets.dart';

/// Planejamento operacional por parcela (NTS/NSD/TIP/NPD/NSP).
class OperationalPlanningSection extends StatelessWidget {
  const OperationalPlanningSection({super.key, required this.planejamento});

  final PlanejamentoOperacionalResultado planejamento;

  @override
  Widget build(BuildContext context) {
    final p = planejamento;
    final viable = p.agendaViavel && p.vazaoDisponivelSuficiente;
    return IrrigationAuditSection(
      title: 'Planejamento operacional por parcela',
      icon: Icons.calendar_month_rounded,
      children: [
        IrrigationAuditRow(
          'Área efetiva',
          '${p.areaTotalM2.toStringAsFixed(0)} m² (${p.areaHectares.toStringAsFixed(2)} ha)',
        ),
        IrrigationAuditRow(
          'Sulcos totais (NTS)',
          '${p.ntsOperacional} (teórico ${p.ntsTeorico.toStringAsFixed(2)})',
        ),
        IrrigationAuditRow(
          'Sulcos por dia (NSD)',
          '${p.nsdOperacional} (teórico ${p.nsdTeorico.toStringAsFixed(2)})',
          detail: 'Sulcos a irrigar por dia para cumprir o turno de rega.',
        ),
        IrrigationAuditRow(
          'Tempo por parcela (TIP)',
          '${p.tipH.toStringAsFixed(4)} h (${(p.tipH * 60).toStringAsFixed(1)} min)',
          detail: 'Ti/Tt + tempo entre parcelas',
        ),
        IrrigationAuditRow(
          'Parcelas completas por dia (NPD)',
          p.npdOperacional == 0
              ? 'Nenhuma'
              : '${p.npdOperacional} (teórico ${p.npdTeorico.toStringAsFixed(2)})',
          detail: 'Grupos operacionais na jornada, não frequência agronômica.',
        ),
        IrrigationAuditRow(
          'Sulcos simultâneos (NSP)',
          '${p.nspOperacional} (teórico ${p.nspTeorico.toStringAsFixed(2)})',
        ),
        IrrigationAuditRow(
          'Dias necessários',
          '${p.diasNecessariosOperacional} de ${p.periodoIrrigacaoDias} dias',
          isWarning: !p.agendaViavel,
        ),
        IrrigationAuditRow(
          'Vazão de projeto',
          '${p.qProjetoOperacional.toStringAsFixed(2)} L/s (teórico ${p.qProjetoTeorico.toStringAsFixed(2)} L/s)',
          isWarning: !p.vazaoDisponivelSuficiente,
          detail: p.vazaoDisponivelLs == null
              ? null
              : 'Disponível: ${p.vazaoDisponivelLs!.toStringAsFixed(2)} L/s',
        ),
        IrrigationAuditRow(
          'Viabilidade operacional',
          viable ? 'Viável no período e na vazão disponível' : 'Inviável',
          detail: p.motivoInviabilidade,
          isWarning: !viable,
        ),
      ],
    );
  }
}
