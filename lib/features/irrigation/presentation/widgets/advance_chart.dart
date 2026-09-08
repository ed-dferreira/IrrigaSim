import 'package:flutter/material.dart';
import 'package:irrigasim/app/theme/app_text_styles.dart';
import 'package:irrigasim/features/irrigation/domain/entities/simulation_result.dart';

class AdvanceChart extends StatelessWidget {
  final SimulationResult resultado;

  const AdvanceChart({super.key, required this.resultado});

  @override
  Widget build(BuildContext context) {
    if (resultado.curvaAvanco.isEmpty) {
      return const Center(child: Text('Sem dados de avanço'));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final maxDistancia = resultado.curvaAvanco
        .map((p) => p.y)
        .reduce((a, b) => a > b ? a : b);
    final maxTempo = resultado.curvaAvanco
        .map((p) => p.x)
        .reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Curva de Avanço', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(
            'Tempo total: ${resultado.tempoAvanco.toStringAsFixed(0)} min',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: _AdvancePainter(
                pontos: resultado.curvaAvanco,
                maxDistancia: maxDistancia,
                maxTempo: maxTempo,
                primaryColor: colorScheme.primary,
                gridColor: colorScheme.outlineVariant,
                textColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancePainter extends CustomPainter {
  final List<PontoGrafico> pontos;
  final double maxDistancia;
  final double maxTempo;
  final Color primaryColor;
  final Color gridColor;
  final Color textColor;

  _AdvancePainter({
    required this.pontos,
    required this.maxDistancia,
    required this.maxTempo,
    required this.primaryColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pontos.isEmpty || maxTempo == 0 || maxDistancia == 0) return;

    const padding = EdgeInsets.only(left: 50, bottom: 40, top: 20, right: 20);
    final chartWidth = size.width - padding.left - padding.right;
    final chartHeight = size.height - padding.top - padding.bottom;

    _drawGrid(canvas, size, padding);

    final fillPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final fillPath = Path();
    fillPath.moveTo(
      padding.left,
      padding.top + chartHeight,
    );

    for (int i = 0; i < pontos.length; i++) {
      final x = padding.left + (pontos[i].x / maxTempo) * chartWidth;
      final y = padding.top + (1 - pontos[i].y / maxDistancia) * chartHeight;
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(
      padding.left + (pontos.last.x / maxTempo) * chartWidth,
      padding.top + chartHeight,
    );
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    for (int i = 0; i < pontos.length; i++) {
      final x = padding.left + (pontos[i].x / maxTempo) * chartWidth;
      final y = padding.top + (1 - pontos[i].y / maxDistancia) * chartHeight;
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < pontos.length; i++) {
      final x = padding.left + (pontos[i].x / maxTempo) * chartWidth;
      final y = padding.top + (1 - pontos[i].y / maxDistancia) * chartHeight;
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }

    _drawAxisLabels(canvas, size, padding, chartWidth, chartHeight);
  }

  void _drawGrid(Canvas canvas, Size size, EdgeInsets padding) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    final chartHeight = size.height - padding.top - padding.bottom;

    for (int i = 0; i <= 5; i++) {
      final y = padding.top + chartHeight * (1 - i / 5);
      canvas.drawLine(
        Offset(padding.left, y),
        Offset(size.width - padding.right, y),
        gridPaint,
      );
    }
  }

  void _drawAxisLabels(
    Canvas canvas,
    Size size,
    EdgeInsets padding,
    double chartWidth,
    double chartHeight,
  ) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: '0',
      style: TextStyle(fontSize: 10, color: textColor),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(padding.left - 5, size.height - 35));

    textPainter.text = TextSpan(
      text: '${maxTempo.toStringAsFixed(0)} min',
      style: TextStyle(fontSize: 10, color: textColor),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        padding.left + chartWidth - textPainter.width,
        size.height - 35,
      ),
    );

    textPainter.text = TextSpan(
      text: '${maxDistancia.toStringAsFixed(0)} m',
      style: TextStyle(fontSize: 10, color: textColor),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(0, padding.top - 5));

    textPainter.text = TextSpan(
      text: 'Distância (m)',
      style: TextStyle(fontSize: 10, color: textColor),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(0, padding.top + chartHeight / 2 - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _AdvancePainter oldDelegate) {
    return oldDelegate.pontos != pontos ||
        oldDelegate.maxDistancia != maxDistancia ||
        oldDelegate.maxTempo != maxTempo ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.gridColor != gridColor;
  }
}
