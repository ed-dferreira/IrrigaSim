import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/models/sulcos/tipo_sulco_info.dart';

class TerrainPainter extends CustomPainter {
  TerrainPainter({
    required this.comprimentoM,
    required this.larguraM,
    required this.espacamentoSulcosM,
    required this.declividadePercentual,
    this.tipoSulco,
    this.furrowColors,
    this.flowingIndex,
  });

  final double comprimentoM;
  final double larguraM;
  final double espacamentoSulcosM;
  final double declividadePercentual;
  final TipoSulco? tipoSulco;
  final List<Color>? furrowColors;
  final int? flowingIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 40.0;
    final availableWidth = size.width - padding * 2;
    final availableHeight = size.height - padding * 2;
    final areaAspectRatio = comprimentoM > 0 && larguraM > 0
        ? comprimentoM / larguraM
        : 1.0;
    var drawWidth = availableWidth;
    var drawHeight = drawWidth / areaAspectRatio;
    if (drawHeight > availableHeight) {
      drawHeight = availableHeight;
      drawWidth = drawHeight * areaAspectRatio;
    }
    final areaRect = Rect.fromLTWH(
      (size.width - drawWidth) / 2,
      (size.height - drawHeight) / 2,
      drawWidth,
      drawHeight,
    );

    _drawTerrainBackground(canvas, areaRect);
    _drawFurrows(canvas, areaRect);
    _drawSlopeArrow(canvas, areaRect);
    _drawLabels(canvas, areaRect);
    _drawFlowDirection(canvas, areaRect);
  }

  void _drawTerrainBackground(Canvas canvas, Rect rect) {
    final bgPaint = Paint()
      ..color = AppColors.surfaceVariant
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AppColors.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      bgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      borderPaint,
    );
  }

  void _drawFurrows(Canvas canvas, Rect rect) {
    final numFurrows = (larguraM / espacamentoSulcosM).floor().clamp(1, 20);
    final spacing = rect.height / (numFurrows + 1);

    final furrowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final flowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final colors =
        furrowColors ?? List.generate(numFurrows, (_) => AppColors.sulco);
    final tipo = tipoSulco ?? TipoSulco.sulcos_comuns;

    switch (tipo) {
      case TipoSulco.sulcos_em_zigue_zague:
        for (var i = 0; i < numFurrows; i++) {
          final y = rect.top + spacing * (i + 1);
          final color = colors[i % colors.length];
          furrowPaint.color = color;
          final path = _zigzagPath(rect, y, amplitude: spacing * 0.35);
          canvas.drawPath(path, furrowPaint);
          if (flowingIndex != null && i == flowingIndex) {
            flowPaint.color = color.withValues(alpha: 0.4);
            canvas.drawPath(path, flowPaint);
          }
        }
      case TipoSulco.sulcos_contorno:
        for (var i = 0; i < numFurrows; i++) {
          final y = rect.top + spacing * (i + 1);
          final color = colors[i % colors.length];
          furrowPaint.color = color;
          final path = _contourPath(rect, y, amplitude: spacing * 0.3);
          canvas.drawPath(path, furrowPaint);
          if (flowingIndex != null && i == flowingIndex) {
            flowPaint.color = color.withValues(alpha: 0.4);
            canvas.drawPath(path, flowPaint);
          }
        }
      case TipoSulco.sulcos_nivel_tabuleiros:
        _drawBoardFurrows(
          canvas,
          rect,
          numFurrows,
          spacing,
          colors,
          furrowPaint,
          closedEnds: false,
        );
      case TipoSulco.sulcos_nivel_fechados:
        _drawBoardFurrows(
          canvas,
          rect,
          numFurrows,
          spacing,
          colors,
          furrowPaint,
          closedEnds: true,
        );
      case TipoSulco.sulcos_comuns:
      case TipoSulco.sulcos_corrugados:
        for (var i = 0; i < numFurrows; i++) {
          final y = rect.top + spacing * (i + 1);
          final color = colors[i % colors.length];
          furrowPaint.color = color;
          canvas.drawLine(
            Offset(rect.left, y),
            Offset(rect.right, y),
            furrowPaint,
          );
          if (flowingIndex != null && i == flowingIndex) {
            flowPaint.color = color.withValues(alpha: 0.4);
            canvas.drawLine(
              Offset(rect.left, y),
              Offset(rect.right, y),
              flowPaint,
            );
          }
        }
    }
  }

  Path _zigzagPath(Rect rect, double y, {required double amplitude}) {
    const segments = 8;
    final path = Path();
    for (var s = 0; s <= segments; s++) {
      final t = s / segments;
      final x = rect.left + rect.width * t;
      final dy = s.isEven ? -amplitude : amplitude;
      final py = y + (s == 0 || s == segments ? 0 : dy);
      if (s == 0) {
        path.moveTo(x, py);
      } else {
        path.lineTo(x, py);
      }
    }
    return path;
  }

  Path _contourPath(Rect rect, double y, {required double amplitude}) {
    const points = 40;
    final path = Path();
    for (var i = 0; i <= points; i++) {
      final t = i / points;
      final x = rect.left + rect.width * t;
      final py = y + math.sin(t * math.pi * 2) * amplitude;
      if (i == 0) {
        path.moveTo(x, py);
      } else {
        path.lineTo(x, py);
      }
    }
    return path;
  }

  void _drawBoardFurrows(
    Canvas canvas,
    Rect rect,
    int numFurrows,
    double spacing,
    List<Color> colors,
    Paint furrowPaint, {
    required bool closedEnds,
  }) {
    final inset = closedEnds ? 8.0 : 0.0;
    final boardRect = Rect.fromLTWH(
      rect.left + inset,
      rect.top + inset,
      math.max(0, rect.width - inset * 2),
      math.max(0, rect.height - inset * 2),
    );

    final boardPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.outline;

    final cols = math.max(2, (comprimentoM / math.max(espacamentoSulcosM, 1)).floor().clamp(2, 8));
    final boardWidth = boardRect.width / cols;
    final boardHeight = boardRect.height / (numFurrows + 1);

    for (var c = 0; c < cols; c++) {
      final left = boardRect.left + boardWidth * c;
      canvas.drawLine(
        Offset(left, boardRect.top),
        Offset(left, boardRect.bottom),
        boardPaint,
      );
    }
    canvas.drawLine(
      Offset(boardRect.right, boardRect.top),
      Offset(boardRect.right, boardRect.bottom),
      boardPaint,
    );

    for (var i = 0; i < numFurrows; i++) {
      final y = boardRect.top + boardHeight * (i + 1);
      final color = colors[i % colors.length];
      furrowPaint.color = color;

      final path = Path()
        ..moveTo(boardRect.left, y)
        ..lineTo(boardRect.right, y);
      if (closedEnds) {
        path
          ..lineTo(boardRect.right, y - boardHeight * 0.35)
          ..lineTo(boardRect.left, y - boardHeight * 0.35)
          ..close();
      }
      canvas.drawPath(path, furrowPaint);

      if (flowingIndex != null && i == flowingIndex) {
        final flowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.4);
        canvas.drawLine(
          Offset(boardRect.left, y),
          Offset(boardRect.right, y),
          flowPaint,
        );
      }
    }

    final horizontal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.outline;
    canvas.drawLine(
      Offset(boardRect.left, boardRect.top),
      Offset(boardRect.right, boardRect.top),
      horizontal,
    );
    canvas.drawLine(
      Offset(boardRect.left, boardRect.bottom),
      Offset(boardRect.right, boardRect.bottom),
      horizontal,
    );
  }

  void _drawSlopeArrow(Canvas canvas, Rect rect) {
    final arrowPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final arrowY = rect.top - 20;
    final arrowStart = Offset(rect.left + 10, arrowY);
    final arrowEnd = Offset(rect.right - 10, arrowY);

    canvas.drawLine(arrowStart, arrowEnd, arrowPaint);

    final headSize = 8.0;
    final path = Path()
      ..moveTo(arrowEnd.dx - headSize, arrowEnd.dy - headSize)
      ..lineTo(arrowEnd.dx, arrowEnd.dy)
      ..lineTo(arrowEnd.dx - headSize, arrowEnd.dy + headSize);
    canvas.drawPath(path, arrowPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Declividade: ${declividadePercentual.toStringAsFixed(2)}%',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        rect.center.dx - textPainter.width / 2,
        arrowY - textPainter.height - 4,
      ),
    );
  }

  void _drawLabels(Canvas canvas, Rect rect) {
    final titlePainter = TextPainter(
      text: TextSpan(
        text:
            '${comprimentoM.toStringAsFixed(0)} m × ${larguraM.toStringAsFixed(0)} m'
            '${tipoSulco != null ? ' · ${tipoSulco!.displayName}' : ''}',
        style: const TextStyle(
          color: AppColors.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(
      canvas,
      Offset(rect.center.dx - titlePainter.width / 2, rect.bottom + 8),
    );

    final startLabel = TextPainter(
      text: const TextSpan(
        text: 'Entrada',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    startLabel.paint(canvas, Offset(rect.left, rect.bottom + 26));

    final endLabel = TextPainter(
      text: const TextSpan(
        text: 'Final',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    endLabel.paint(
      canvas,
      Offset(rect.right - endLabel.width, rect.bottom + 26),
    );
  }

  void _drawFlowDirection(Canvas canvas, Rect rect) {
    final y = rect.center.dy;

    final dotPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 5; i++) {
      final dx = rect.left + (rect.width * 0.15) + (rect.width * 0.15 * i);
      canvas.drawCircle(Offset(dx, y), 2, dotPaint);
    }

    final arrowPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final arrowStart = Offset(rect.right - 50, y);
    final arrowEnd = Offset(rect.right - 20, y);
    canvas.drawLine(arrowStart, arrowEnd, arrowPaint);

    final headSize = 5.0;
    final path = Path()
      ..moveTo(arrowEnd.dx - headSize, arrowEnd.dy - headSize)
      ..lineTo(arrowEnd.dx, arrowEnd.dy)
      ..lineTo(arrowEnd.dx - headSize, arrowEnd.dy + headSize);
    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant TerrainPainter oldDelegate) {
    return oldDelegate.comprimentoM != comprimentoM ||
        oldDelegate.larguraM != larguraM ||
        oldDelegate.espacamentoSulcosM != espacamentoSulcosM ||
        oldDelegate.declividadePercentual != declividadePercentual ||
        oldDelegate.tipoSulco != tipoSulco ||
        oldDelegate.flowingIndex != flowingIndex;
  }
}
