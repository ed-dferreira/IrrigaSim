import 'package:flutter/material.dart';
import 'package:irrigasim/core/widgets/kpi_card.dart';

import 'irrigation_project_components.dart';

/// Item de indicador exibido na grade comum de resultados de irrigação.
class IrrigationKpiItem {
  const IrrigationKpiItem({
    required this.titulo,
    required this.valor,
    required this.unidade,
    this.subtitulo,
    this.icon,
    this.color,
  });

  final String titulo;
  final String valor;
  final String unidade;
  final String? subtitulo;
  final IconData? icon;
  final Color? color;
}

/// Grade responsiva de KPIs compartilhada pelos métodos de irrigação.
class IrrigationKpiGrid extends StatelessWidget {
  const IrrigationKpiGrid({
    super.key,
    required this.items,
    this.spacing = IrrigationSpacing.field,
    this.maxColumns = 3,
  });

  final List<IrrigationKpiItem> items;
  final double spacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 720
          ? maxColumns.clamp(1, 3)
          : constraints.maxWidth >= 480
          ? maxColumns.clamp(1, 2)
          : 1;
      final width = (constraints.maxWidth - (columns - 1) * spacing) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final item in items)
            SizedBox(
              width: width,
              child: KpiCard(
                titulo: item.titulo,
                valor: item.valor,
                unidade: item.unidade,
                subtitulo: item.subtitulo,
                icon: item.icon,
                color: item.color,
              ),
            ),
        ],
      );
    },
  );
}
