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
import com.irrigasim.domain.PontoGrafico

/**
 * Gráfico de Avanço da Lâmina D'água (Tempo × Distância).
 * Com eixos rotulados, valores nos ticks e anotações nos pontos-chave.
 */
@Composable
fun GraficoAvanco(
    pontos: List<PontoGrafico>,
    comprimentoMax: Double,
    tempoAvanco: Double,
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
                text = "📈 Curva de Avanço da Água",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = "Avanço da frente de escoamento ao longo do terreno",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(8.dp))

            if (pontos.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxWidth().height(220.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text("Sem dados para o gráfico", color = MaterialTheme.colorScheme.outline)
                }
                return@Column
            }

            val lineColor = MaterialTheme.colorScheme.primary
            val gridColor = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f)
            val labelColor = MaterialTheme.colorScheme.onSurfaceVariant
            val textMeasurer = rememberTextMeasurer()

            Canvas(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(240.dp)
            ) {
                val width = size.width
                val height = size.height
                val paddingLeft = 55.dp.toPx()
                val paddingBottom = 40.dp.toPx()
                val paddingTop = 15.dp.toPx()
                val paddingRight = 15.dp.toPx()

                val chartWidth = width - paddingLeft - paddingRight
                val chartHeight = height - paddingTop - paddingBottom

                val maxX = (pontos.maxOfOrNull { it.x } ?: 1.0).coerceAtLeast(1.0)
                val maxY = (pontos.maxOfOrNull { it.y } ?: 1.0).coerceAtLeast(1.0)

                // Eixos
                drawLine(color = labelColor, start = Offset(paddingLeft, paddingTop), end = Offset(paddingLeft, paddingTop + chartHeight), strokeWidth = 1.5.dp.toPx())
                drawLine(color = labelColor, start = Offset(paddingLeft, paddingTop + chartHeight), end = Offset(paddingLeft + chartWidth, paddingTop + chartHeight), strokeWidth = 1.5.dp.toPx())

                // Eixo Y (Distância m)
                val stepsY = 5
                for (i in 0..stepsY) {
                    val yVal = (maxY / stepsY) * i
                    val yPos = paddingTop + chartHeight - (i.toFloat() / stepsY) * chartHeight
                    drawLine(color = gridColor, start = Offset(paddingLeft, yPos), end = Offset(paddingLeft + chartWidth, yPos), strokeWidth = 0.5.dp.toPx())
                    drawLine(color = labelColor, start = Offset(paddingLeft - 5.dp.toPx(), yPos), end = Offset(paddingLeft, yPos), strokeWidth = 1.dp.toPx())
                    val label = "${yVal.toInt()}"
                    val measured = textMeasurer.measure(label, style = TextStyle(fontSize = 9.sp, color = labelColor))
                    drawText(textLayoutResult = measured, topLeft = Offset(paddingLeft - measured.size.width - 6.dp.toPx(), yPos - measured.size.height / 2f))
                }

                // Eixo X (Tempo min)
                val stepsX = 5
                for (i in 0..stepsX) {
                    val xVal = (maxX / stepsX) * i
                    val xPos = paddingLeft + (i.toFloat() / stepsX) * chartWidth
                    drawLine(color = labelColor, start = Offset(xPos, paddingTop + chartHeight), end = Offset(xPos, paddingTop + chartHeight + 5.dp.toPx()), strokeWidth = 1.dp.toPx())
                    val label = "${xVal.toInt()}"
                    val measured = textMeasurer.measure(label, style = TextStyle(fontSize = 9.sp, color = labelColor))
                    drawText(textLayoutResult = measured, topLeft = Offset(xPos - measured.size.width / 2f, paddingTop + chartHeight + 7.dp.toPx()))
                }

                // Título Eixo X
                val xTitle = textMeasurer.measure("Tempo (min)", style = TextStyle(fontSize = 10.sp, color = labelColor))
                drawText(textLayoutResult = xTitle, topLeft = Offset(paddingLeft + chartWidth / 2 - xTitle.size.width / 2f, height - 6.dp.toPx()))

                // Curva e área preenchida
                val bgPath = Path()
                val curvePath = Path()
                pontos.forEachIndexed { i, p ->
                    val xPos = paddingLeft + (p.x / maxX).toFloat() * chartWidth
                    val yPos = paddingTop + chartHeight - (p.y / maxY).toFloat() * chartHeight
                    if (i == 0) {
                        curvePath.moveTo(xPos, yPos); bgPath.moveTo(xPos, paddingTop + chartHeight); bgPath.lineTo(xPos, yPos)
                    } else {
                        curvePath.lineTo(xPos, yPos); bgPath.lineTo(xPos, yPos)
                    }
                    if (i == pontos.lastIndex) { bgPath.lineTo(xPos, paddingTop + chartHeight); bgPath.close() }
                }

                drawPath(bgPath, Brush.verticalGradient(listOf(lineColor.copy(alpha = 0.30f), lineColor.copy(alpha = 0.02f)), startY = paddingTop, endY = paddingTop + chartHeight))
                drawPath(curvePath, lineColor, style = Stroke(width = 2.5.dp.toPx(), cap = StrokeCap.Round))

                // Pontos com rótulos de valor
                val step = maxOf(1, pontos.size / 6)
                pontos.forEachIndexed { i, p ->
                    val xPos = paddingLeft + (p.x / maxX).toFloat() * chartWidth
                    val yPos = paddingTop + chartHeight - (p.y / maxY).toFloat() * chartHeight
                    drawCircle(lineColor, radius = 3.dp.toPx(), center = Offset(xPos, yPos))
                    if (i % step == 0 || i == pontos.lastIndex) {
                        val valLabel = textMeasurer.measure("${p.y.toInt()}m", style = TextStyle(fontSize = 8.sp, color = lineColor))
                        drawText(textLayoutResult = valLabel, topLeft = Offset(xPos - valLabel.size.width / 2f, yPos - valLabel.size.height - 4.dp.toPx()))
                    }
                }

                // Anotação tempo de avanço (ta)
                if (tempoAvanco > 0 && tempoAvanco <= maxX) {
                    val taX = paddingLeft + (tempoAvanco / maxX).toFloat() * chartWidth
                    drawLine(Color(0xFFE65100), Offset(taX, paddingTop), Offset(taX, paddingTop + chartHeight), strokeWidth = 1.5.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(8f, 6f)))
                    val taLabel = textMeasurer.measure("ta=${tempoAvanco.toInt()} min", style = TextStyle(fontSize = 9.sp, color = Color(0xFFE65100)))
                    drawText(textLayoutResult = taLabel, topLeft = Offset(taX + 4.dp.toPx(), paddingTop + 2.dp.toPx()))
                }
            }

            // Legenda
            Row(Modifier.fillMaxWidth().padding(top = 4.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("Eixo Y: Distância (m)", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.outline)
                Text("Eixo X: Tempo (min)", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.outline)
            }
        }
    }
}
