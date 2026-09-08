import 'dart:math';
import 'package:flutter/material.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/app/theme/app_text_styles.dart';
import 'package:irrigasim/features/irrigation/domain/entities/simulation_result.dart';

class WaterBalanceChart extends StatelessWidget {
  final SimulationResult resultado;

  const WaterBalanceChart({super.key, required this.resultado});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Balanço Hídrico', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: CustomPaint(
                size: const Size(200, 200),
                painter: _WaterBalancePainter(
                  eficiencia: resultado.eficiencia,
                  perdaPercolacao: resultado.perdaPercolacao,
                  perdaEscoamento: resultado.perdaEscoamento,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _legendItem(
          color: AppColors.success,
          label: 'Armazenado',
          value: '${resultado.eficiencia.toStringAsFixed(1)}%',
        ),
        _legendItem(
          color: AppColors.warning,
          label: 'Percolação',
          value: '${resultado.perdaPercolacao.toStringAsFixed(1)}%',
        ),
        _legendItem(
          color: AppColors.error,
          label: 'Escoamento',
          value: '${resultado.perdaEscoamento.toStringAsFixed(1)}%',
        ),
      ],
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTextStyles.bodySmall),
            Text(value, style: AppTextStyles.label),
          ],
        ),
      ],
    );
  }
}

class _WaterBalancePainter extends CustomPainter {
  final double eficiencia;
  final double perdaPercolacao;
  final double perdaEscoamento;

  _WaterBalancePainter({
    required this.eficiencia,
    required this.perdaPercolacao,
    required this.perdaEscoamento,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 20;

    final colors = [AppColors.success, AppColors.warning, AppColors.error];
    final values = [eficiencia, perdaPercolacao, perdaEscoamento];
    final total = values.fold(0.0, (sum, v) => sum + v);

    if (total == 0) return;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40
      ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * 2 * pi;
      strokePaint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        strokePaint,
      );
      startAngle += sweepAngle;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${eficiencia.toStringAsFixed(1)}%',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'Ea',
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(
      canvas,
      Offset(
        center.dx - labelPainter.width / 2,
        center.dy - labelPainter.height / 2 + 20,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _WaterBalancePainter oldDelegate) {
    return oldDelegate.eficiencia != eficiencia ||
        oldDelegate.perdaPercolacao != perdaPercolacao ||
        oldDelegate.perdaEscoamento != perdaEscoamento;
  }
}
