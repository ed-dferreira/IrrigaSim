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
import androidx.compose.ui.unit.dp
import com.irrigasim.domain.indicadores.IndicadoresDesempenho

/**
 * Gráfico do Perfil Longitudinal da Lâmina Infiltrada (Comprimento × Lâmina mm).
 * Exibe a linha de referência LN (Lâmina Necessária) e destaca zonas de excesso/déficit.
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
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "💧 Perfil Longitudinal Infiltrado",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = "LN = ${laminaRequerida.toInt()} mm",
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.secondary
                )
            }

            Text(
                text = "CUC = ${cuc.toInt()}%  •  DU = ${du.toInt()}%",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(16.dp))

            if (perfil.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxWidth().height(180.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text("Sem dados de perfil", color = MaterialTheme.colorScheme.outline)
                }
                return@Column
            }

            val primaryColor = MaterialTheme.colorScheme.primary
            val targetLineColor = MaterialTheme.colorScheme.secondary
            val excessColor = MaterialTheme.colorScheme.tertiary.copy(alpha = 0.3f)
            val gridColor = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f)

            Canvas(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp)
            ) {
                val width = size.width
                val height = size.height
                val paddingLeft = 40.dp.toPx()
                val paddingBottom = 25.dp.toPx()
                val paddingTop = 15.dp.toPx()
                val paddingRight = 15.dp.toPx()

                val chartWidth = width - paddingLeft - paddingRight
                val chartHeight = height - paddingTop - paddingBottom

                val maxZ = maxOf(perfil.maxOrNull() ?: 10.0, laminaRequerida * 1.25)

                // Draw Grid
                val stepsY = 4
                for (i in 0..stepsY) {
                    val yPos = paddingTop + chartHeight - (i.toFloat() / stepsY) * chartHeight
                    drawLine(
                        color = gridColor,
                        start = Offset(paddingLeft, yPos),
                        end = Offset(paddingLeft + chartWidth, yPos),
                        strokeWidth = 1.dp.toPx()
                    )
                }

                // Draw LN Target Line (Dashed)
                val lnYPos = paddingTop + chartHeight - (laminaRequerida / maxZ).toFloat() * chartHeight
                drawLine(
                    color = targetLineColor,
                    start = Offset(paddingLeft, lnYPos),
                    end = Offset(paddingLeft + chartWidth, lnYPos),
                    strokeWidth = 2.dp.toPx(),
                    pathEffect = PathEffect.dashPathEffect(floatArrayOf(10f, 10f), 0f)
                )

                // Draw Profile Bars/Area
                val path = Path()
                val bgPath = Path()

                perfil.forEachIndexed { i, z ->
                    val xFrac = i.toFloat() / (perfil.size - 1)
                    val xPos = paddingLeft + xFrac * chartWidth
                    val yPos = paddingTop + chartHeight - (z / maxZ).toFloat() * chartHeight

                    if (i == 0) {
                        path.moveTo(xPos, yPos)
                        bgPath.moveTo(xPos, paddingTop + chartHeight)
                        bgPath.lineTo(xPos, yPos)
                    } else {
                        path.lineTo(xPos, yPos)
                        bgPath.lineTo(xPos, yPos)
                    }

                    if (i == perfil.lastIndex) {
                        bgPath.lineTo(xPos, paddingTop + chartHeight)
                        bgPath.close()
                    }
                }

                // Fill Area
                drawPath(
                    path = bgPath,
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            primaryColor.copy(alpha = 0.4f),
                            primaryColor.copy(alpha = 0.05f)
                        ),
                        startY = paddingTop,
                        endY = paddingTop + chartHeight
                    )
                )

                // Draw Profile Stroke
                drawPath(
                    path = path,
                    color = primaryColor,
                    style = Stroke(width = 3.dp.toPx(), cap = StrokeCap.Round)
                )
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("Cabeceira (0 m)", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.outline)
                Text("--- LN Requerida", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.secondary)
                Text("Fim do Terreno", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.outline)
            }
        }
    }
}
