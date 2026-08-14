package com.irrigasim.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Gráfico do Perfil Longitudinal da Lâmina Infiltrada (Posição × Lâmina mm).
 * Com eixos rotulados, valores nos ticks, linha tracejada LN, e valores nos pontos.
 */
@Composable
fun GraficoLaminaLongitudinal(
    perfil: List<Double>,
    laminaRequerida: Double,
    cuc: Double,
    du: Double,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "💧 Perfil Longitudinal da Lâmina Infiltrada",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = "Distribuição da lâmina ao longo do terreno",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(4.dp))

            // KPIs inline
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Text("CUC = ${cuc.toInt()}%", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
                Text("DU = ${du.toInt()}%", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.secondary)
                Text("LN = ${laminaRequerida.toInt()} mm", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.tertiary)
            }

            Spacer(modifier = Modifier.height(8.dp))

            if (perfil.isEmpty()) {
                Box(Modifier.fillMaxWidth().height(220.dp), contentAlignment = Alignment.Center) {
                    Text("Sem dados de perfil", color = MaterialTheme.colorScheme.outline)
                }
                return@Column
            }

            val primaryColor = MaterialTheme.colorScheme.primary
            val targetColor = MaterialTheme.colorScheme.tertiary
            val gridColor = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f)
            val labelColor = MaterialTheme.colorScheme.onSurfaceVariant
            val textMeasurer = rememberTextMeasurer()

            Canvas(
                modifier = Modifier.fillMaxWidth().height(240.dp)
            ) {
                val width = size.width
                val height = size.height
                val paddingLeft = 55.dp.toPx()
                val paddingBottom = 40.dp.toPx()
                val paddingTop = 15.dp.toPx()
                val paddingRight = 15.dp.toPx()

                val chartWidth = width - paddingLeft - paddingRight
                val chartHeight = height - paddingTop - paddingBottom

                val maxZ = maxOf(perfil.maxOrNull() ?: 10.0, laminaRequerida * 1.3).coerceAtLeast(1.0)

                // Eixos
                drawLine(labelColor, Offset(paddingLeft, paddingTop), Offset(paddingLeft, paddingTop + chartHeight), 1.5.dp.toPx())
                drawLine(labelColor, Offset(paddingLeft, paddingTop + chartHeight), Offset(paddingLeft + chartWidth, paddingTop + chartHeight), 1.5.dp.toPx())

                // Eixo Y (Lâmina mm)
                val stepsY = 5
                for (i in 0..stepsY) {
                    val yVal = (maxZ / stepsY) * i
                    val yPos = paddingTop + chartHeight - (i.toFloat() / stepsY) * chartHeight
                    drawLine(gridColor, Offset(paddingLeft, yPos), Offset(paddingLeft + chartWidth, yPos), 0.5.dp.toPx())
                    drawLine(labelColor, Offset(paddingLeft - 5.dp.toPx(), yPos), Offset(paddingLeft, yPos), 1.dp.toPx())
                    val label = "${"%.0f".format(yVal)}"
                    val measured = textMeasurer.measure(label, TextStyle(fontSize = 9.sp, color = labelColor))
                    drawText(textLayoutResult = measured, topLeft = Offset(paddingLeft - measured.size.width - 6.dp.toPx(), yPos - measured.size.height / 2f))
                }

                // Eixo X (posição %)
                val stepsX = 4
                for (i in 0..stepsX) {
                    val pct = (100.0 / stepsX) * i
                    val xPos = paddingLeft + (i.toFloat() / stepsX) * chartWidth
                    drawLine(labelColor, Offset(xPos, paddingTop + chartHeight), Offset(xPos, paddingTop + chartHeight + 5.dp.toPx()), 1.dp.toPx())
                    val label = "${pct.toInt()}%"
                    val measured = textMeasurer.measure(label, TextStyle(fontSize = 9.sp, color = labelColor))
                    drawText(textLayoutResult = measured, topLeft = Offset(xPos - measured.size.width / 2f, paddingTop + chartHeight + 7.dp.toPx()))
                }

                // Título Eixo X
                val xTitle = textMeasurer.measure("Posição no terreno (%)", TextStyle(fontSize = 10.sp, color = labelColor))
                drawText(textLayoutResult = xTitle, topLeft = Offset(paddingLeft + chartWidth / 2 - xTitle.size.width / 2f, height - 6.dp.toPx()))

                // Linha de meta LN (tracejada)
                val lnYPos = paddingTop + chartHeight - (laminaRequerida / maxZ).toFloat() * chartHeight
                drawLine(targetColor, Offset(paddingLeft, lnYPos), Offset(paddingLeft + chartWidth, lnYPos), 2.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(12f, 8f)))
                val lnLabel = textMeasurer.measure("LN = ${laminaRequerida.toInt()} mm", TextStyle(fontSize = 9.sp, color = targetColor))
                drawText(textLayoutResult = lnLabel, topLeft = Offset(paddingLeft + chartWidth - lnLabel.size.width - 4.dp.toPx(), lnYPos - lnLabel.size.height - 4.dp.toPx()))

                // Perfil e gradiente
                val curvePath = Path()
                val bgPath = Path()
                val divisor = if (perfil.size > 1) (perfil.size - 1).toFloat() else 1f

                perfil.forEachIndexed { i, z ->
                    val xFrac = i.toFloat() / divisor
                    val xPos = paddingLeft + xFrac * chartWidth
                    val yPos = paddingTop + chartHeight - (z / maxZ).toFloat() * chartHeight
                    if (i == 0) {
                        curvePath.moveTo(xPos, yPos); bgPath.moveTo(xPos, paddingTop + chartHeight); bgPath.lineTo(xPos, yPos)
                    } else {
                        curvePath.lineTo(xPos, yPos); bgPath.lineTo(xPos, yPos)
                    }
                    if (i == perfil.lastIndex) { bgPath.lineTo(xPos, paddingTop + chartHeight); bgPath.close() }
                }

                drawPath(bgPath, Brush.verticalGradient(listOf(primaryColor.copy(alpha = 0.35f), primaryColor.copy(alpha = 0.03f)), paddingTop, paddingTop + chartHeight))
                drawPath(curvePath, primaryColor, style = Stroke(2.5.dp.toPx(), cap = StrokeCap.Round))

                // Rótulos de valor nos pontos
                val step = maxOf(1, perfil.size / 5)
                perfil.forEachIndexed { i, z ->
                    val xFrac = i.toFloat() / divisor
                    val xPos = paddingLeft + xFrac * chartWidth
                    val yPos = paddingTop + chartHeight - (z / maxZ).toFloat() * chartHeight
                    drawCircle(primaryColor, 2.5.dp.toPx(), Offset(xPos, yPos))
                    if (i % step == 0 || i == perfil.lastIndex) {
                        val valLabel = textMeasurer.measure("${"%.0f".format(z)}", TextStyle(fontSize = 8.sp, color = primaryColor))
                        drawText(textLayoutResult = valLabel, topLeft = Offset(xPos - valLabel.size.width / 2f, yPos - valLabel.size.height - 3.dp.toPx()))
                    }
                }
            }

            // Legenda
            Row(Modifier.fillMaxWidth().padding(top = 4.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("━━ Lâmina infiltrada (mm)", style = MaterialTheme.typography.labelSmall, color = primaryColor)
                Text("┈┈ LN requerida", style = MaterialTheme.typography.labelSmall, color = targetColor)
            }
        }
    }
}
