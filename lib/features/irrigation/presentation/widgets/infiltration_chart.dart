import 'dart:math';
import 'package:flutter/material.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/app/theme/app_text_styles.dart';
import 'package:irrigasim/features/irrigation/domain/entities/simulation_result.dart';

class InfiltrationChart extends StatelessWidget {
  final SimulationResult resultado;

  const InfiltrationChart({super.key, required this.resultado});

  @override
  Widget build(BuildContext context) {
    if (resultado.perfilLongitudinal.isEmpty) {
      return const Center(child: Text('Sem dados de perfil longitudinal'));
    }

    final maxLamina =
        resultado.perfilLongitudinal.reduce((a, b) => a > b ? a : b);
    final maxLaminaMm = maxLamina * 1000;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Perfil Longitudinal', style: AppTextStyles.heading3),
              _buildIndicators(),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: _InfiltrationPainter(
                laminas: resultado.perfilLongitudinal,
                laminaRequerida: resultado.laminaRequerida,
                maxLamina: maxLaminaMm,
                cuc: resultado.cuc,
                du: resultado.du,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _indicator(
          label: 'CUC',
          value: '${resultado.cuc.toStringAsFixed(1)}%',
          color: _classificationColor(resultado.classificacaoCuc),
        ),
        const SizedBox(width: 12),
        _indicator(
          label: 'DU',
          value: '${resultado.du.toStringAsFixed(1)}%',
          color: _classificationColor(resultado.classificacaoDu),
        ),
      ],
    );
  }

  Widget _indicator({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(value, style: AppTextStyles.label.copyWith(color: color)),
      ],
    );
  }

  Color _classificationColor(String classificacao) {
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
}

class _InfiltrationPainter extends CustomPainter {
  final List<double> laminas;
  final double laminaRequerida;
  final double maxLamina;
  final double cuc;
  final double du;

  _InfiltrationPainter({
    required this.laminas,
    required this.laminaRequerida,
    required this.maxLamina,
    required this.cuc,
    required this.du,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (laminas.isEmpty || maxLamina == 0) return;

    const padding = EdgeInsets.only(left: 50, bottom: 40, top: 20, right: 20);
    final chartWidth = size.width - padding.left - padding.right;
    final chartHeight = size.height - padding.top - padding.bottom;

    _drawGrid(canvas, size, padding, chartHeight);

    final laminaRequeridaMm = laminaRequerida * 1000;
    _drawDashedLine(
      canvas: canvas,
      x1: padding.left,
      y1: padding.top + (1 - laminaRequeridaMm / maxLamina) * chartHeight,
      x2: size.width - padding.right,
      y2: padding.top + (1 - laminaRequeridaMm / maxLamina) * chartHeight,
      color: AppColors.error,
      strokeWidth: 1.5,
    );

    _drawLabel(
      canvas,
      text: 'LN: ${laminaRequeridaMm.toStringAsFixed(1)} mm',
      x: size.width - padding.right - 80,
      y: padding.top + (1 - laminaRequeridaMm / maxLamina) * chartHeight - 18,
      color: AppColors.error,
    );

    final fillPaint = Paint()
      ..color = AppColors.success.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final fillPath = Path();
    fillPath.moveTo(padding.left, padding.top + chartHeight);

    for (int i = 0; i < laminas.length; i++) {
      final x = padding.left + (i / (laminas.length - 1)) * chartWidth;
      final laminaMm = laminas[i] * 1000;
      final y = padding.top + (1 - laminaMm / maxLamina) * chartHeight;
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(padding.left + chartWidth, padding.top + chartHeight);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.success
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    for (int i = 0; i < laminas.length; i++) {
      final x = padding.left + (i / (laminas.length - 1)) * chartWidth;
      final laminaMm = laminas[i] * 1000;
      final y = padding.top + (1 - laminaMm / maxLamina) * chartHeight;
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }
    canvas.drawPath(linePath, linePaint);

    _drawAxisLabels(canvas, size, padding, chartWidth, chartHeight);
  }

  void _drawGrid(
    Canvas canvas,
    Size size,
    EdgeInsets padding,
    double chartHeight,
  ) {
    final gridPaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 5; i++) {
      final y = padding.top + chartHeight * (1 - i / 5);
      canvas.drawLine(
        Offset(padding.left, y),
        Offset(size.width - padding.right, y),
        gridPaint,
      );
    }
  }

  void _drawDashedLine({
    required Canvas canvas,
    required double x1,
    required double y1,
    required double x2,
    required double y2,
    required Color color,
    required double strokeWidth,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 4.0;
    final dx = x2 - x1;
    final dy = y2 - y1;
    final distance = sqrt(dx * dx + dy * dy);
    final normalizedDx = dx / distance;
    final normalizedDy = dy / distance;

    double currentDistance = 0;
    while (currentDistance < distance) {
      final startX = x1 + normalizedDx * currentDistance;
      final startY = y1 + normalizedDy * currentDistance;
      final endX = x1 + normalizedDx * min(currentDistance + dashWidth, distance);
      final endY = y1 + normalizedDy * min(currentDistance + dashWidth, distance);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      currentDistance += dashWidth + dashSpace;
    }
  }

  void _drawLabel(
    Canvas canvas, {
    required String text,
    required double x,
    required double y,
    required Color color,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 10, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(x, y));
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
      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(padding.left - 5, size.height - 35));

    textPainter.text = TextSpan(
      text: '${(laminas.length - 1)} m',
      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
      text: '0',
      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(padding.left - 5, size.height - 25));

    textPainter.text = TextSpan(
      text: '${maxLamina.toStringAsFixed(0)} mm',
      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(0, padding.top - 5));

    textPainter.text = TextSpan(
      text: 'Lâmina (mm)',
      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(0, padding.top + chartHeight / 2 - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _InfiltrationPainter oldDelegate) {
    return oldDelegate.laminas != laminas ||
        oldDelegate.laminaRequerida != laminaRequerida ||
        oldDelegate.maxLamina != maxLamina ||
        oldDelegate.cuc != cuc ||
        oldDelegate.du != du;
  }
}
