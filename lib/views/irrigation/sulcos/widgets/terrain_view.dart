import 'package:flutter/material.dart';
import 'package:irrigasim/app/theme/app_icons.dart';
import 'package:irrigasim/models/sulcos/tipo_sulco_info.dart';

import 'terrain_painter.dart';

class TerrainView extends StatelessWidget {
  const TerrainView({
    super.key,
    required this.comprimentoM,
    required this.larguraM,
    required this.espacamentoSulcosM,
    required this.declividadePercentual,
    this.tipoSulco,
    this.furrowColors,
    this.flowingIndex,
    this.showTitle = true,
    this.distributionName = 'sulcos',
  });

  final double comprimentoM;
  final double larguraM;
  final double espacamentoSulcosM;
  final double declividadePercentual;
  final TipoSulco? tipoSulco;
  final List<Color>? furrowColors;
  final int? flowingIndex;
  final bool showTitle;

  /// Termo apresentado no desenho. Pode ser `faixas` no projeto de faixas.
  final String distributionName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final numSulcos = (larguraM / espacamentoSulcosM).floor().clamp(1, 20);
    final tipoLabel = tipoSulco?.displayName;

    return Semantics(
      label:
          'Representação visual do terreno. Área de ${comprimentoM.toStringAsFixed(0)} metros por ${larguraM.toStringAsFixed(0)} metros com $numSulcos $distributionName${tipoLabel != null ? ', tipo $tipoLabel' : ''} e declividade de ${declividadePercentual.toStringAsFixed(2)} por cento.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle)
            Row(
              children: [
                Icon(AppIcons.terreno, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tipoLabel != null
                        ? 'Distribuição — $tipoLabel'
                        : distributionName == 'sulcos'
                        ? 'Distribuição dos sulcos na área'
                        : 'Distribuição das $distributionName na área',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          if (showTitle) const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 200,
                    child: CustomPaint(
                      painter: TerrainPainter(
                        comprimentoM: comprimentoM,
                        larguraM: larguraM,
                        espacamentoSulcosM: espacamentoSulcosM,
                        declividadePercentual: declividadePercentual,
                        tipoSulco: tipoSulco,
                        furrowColors: furrowColors,
                        flowingIndex: flowingIndex,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TerrainLegend(
                    numSulcos: numSulcos,
                    espacamento: espacamentoSulcosM,
                    tipo: tipoSulco,
                    distributionName: distributionName,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TerrainLegend extends StatelessWidget {
  const _TerrainLegend({
    required this.numSulcos,
    required this.espacamento,
    this.tipo,
    required this.distributionName,
  });
  final int numSulcos;
  final double espacamento;
  final TipoSulco? tipo;
  final String distributionName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendDot(
          color: colors.primary,
          label: '$numSulcos $distributionName',
        ),
        _LegendDot(
          color: colors.onSurfaceVariant,
          label: 'Espaçamento: ${espacamento.toStringAsFixed(2)} m',
        ),
        if (tipo != null)
          _LegendDot(color: colors.tertiary, label: tipo!.displayName),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
