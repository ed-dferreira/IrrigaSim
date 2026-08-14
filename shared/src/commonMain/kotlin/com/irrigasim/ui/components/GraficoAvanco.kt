package com.irrigasim.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
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
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.irrigasim.domain.PontoGrafico

/**
 * Gráfico de Avanço da Lâmina D'água (Distância × Tempo).
 * Renders via Compose Canvas for 100% KMP compatibility (Android + iOS).
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
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "📈 Curva de Avanço da Água",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = "ta = ${tempoAvanco.toInt()} min",
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.primary
                )
            }

            Text(
                text = "Avanço da frente de escoamento ao longo do terreno",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(16.dp))

            if (pontos.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxWidth().height(180.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text("Sem dados para o gráfico", color = MaterialTheme.colorScheme.outline)
                }
                return@Column
            }

            val lineColor = MaterialTheme.colorScheme.primary
            val gridColor = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
            val textColor = MaterialTheme.colorScheme.onSurfaceVariant

            Canvas(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp)
            ) {
                val width = size.width
                val height = size.height
                val paddingLeft = 40.dp.toPx()
                val paddingBottom = 30.dp.toPx()
                val paddingTop = 10.dp.toPx()
                val paddingRight = 15.dp.toPx()

                val chartWidth = width - paddingLeft - paddingRight
                val chartHeight = height - paddingTop - paddingBottom

                val maxX = (pontos.maxOfOrNull { it.x } ?: 1.0).coerceAtLeast(1.0)
                val maxY = (pontos.maxOfOrNull { it.y } ?: 1.0).coerceAtLeast(1.0)

                // Draw Grid Lines (Y axis - Distance)
                val stepsY = 4
                for (i in 0..stepsY) {
                    val yVal = (maxY / stepsY) * i
                    val yPos = paddingTop + chartHeight - (i.toFloat() / stepsY) * chartHeight
                    drawLine(
                        color = gridColor,
                        start = Offset(paddingLeft, yPos),
                        end = Offset(paddingLeft + chartWidth, yPos),
                        strokeWidth = 1.dp.toPx()
                    )
                }

                // Draw Line & Gradient Area
                val path = Path()
                val bgPath = Path()

                pontos.forEachIndexed { index, p ->
                    val xPos = paddingLeft + (p.x / maxX).toFloat() * chartWidth
                    val yPos = paddingTop + chartHeight - (p.y / maxY).toFloat() * chartHeight

                    if (index == 0) {
                        path.moveTo(xPos, yPos)
                        bgPath.moveTo(xPos, paddingTop + chartHeight)
                        bgPath.lineTo(xPos, yPos)
                    } else {
                        path.lineTo(xPos, yPos)
                        bgPath.lineTo(xPos, yPos)
                    }

                    if (index == pontos.lastIndex) {
                        bgPath.lineTo(xPos, paddingTop + chartHeight)
                        bgPath.close()
                    }
                }

                // Draw Area Fill
                drawPath(
                    path = bgPath,
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            lineColor.copy(alpha = 0.35f),
                            lineColor.copy(alpha = 0.02f)
                        ),
                        startY = paddingTop,
                        endY = paddingTop + chartHeight
                    )
                )

                // Draw Curve Line
                drawPath(
                    path = path,
                    color = lineColor,
                    style = Stroke(width = 3.dp.toPx(), cap = StrokeCap.Round)
                )

                // Draw Points
                pontos.forEach { p ->
                    val xPos = paddingLeft + (p.x / maxX).toFloat() * chartWidth
                    val yPos = paddingTop + chartHeight - (p.y / maxY).toFloat() * chartHeight
                    drawCircle(
                        color = lineColor,
                        radius = 3.dp.toPx(),
                        center = Offset(xPos, yPos)
                    )
                }
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("0 min", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.outline)
                Text("Tempo (min)", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text("${(pontos.maxOfOrNull { it.x } ?: 0.0).toInt()} min", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.outline)
            }
        }
    }
}
