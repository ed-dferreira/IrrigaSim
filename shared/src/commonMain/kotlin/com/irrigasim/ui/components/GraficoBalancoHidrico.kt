package com.irrigasim.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp

/**
 * Gráfico Donut para o Balanço Hídrico (Aproveitado / Percolação / Escoamento).
 */
@Composable
fun GraficoBalancoHidrico(
    eficienciaAproveitada: Double,
    perdaPercolacao: Double,
    perdaEscoamento: Double,
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
                text = "📊 Balanço Hídrico Volumétrico",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface
            )

            Spacer(modifier = Modifier.height(16.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceAround
            ) {
                // Donut Canvas
                val usefulColor = MaterialTheme.colorScheme.primary
                val percColor = MaterialTheme.colorScheme.tertiary
                val runoffColor = MaterialTheme.colorScheme.error

                Box(
                    modifier = Modifier.size(140.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Canvas(modifier = Modifier.fillMaxSize()) {
                        val strokeWidth = 24.dp.toPx()
                        val diameter = size.minDimension - strokeWidth
                        val topLeft = Offset(strokeWidth / 2, strokeWidth / 2)
                        val arcSize = Size(diameter, diameter)

                        val total = (eficienciaAproveitada + perdaPercolacao + perdaEscoamento).coerceAtLeast(1.0)
                        val usefulSweep = (eficienciaAproveitada / total * 360.0).toFloat()
                        val percSweep = (perdaPercolacao / total * 360.0).toFloat()
                        val runoffSweep = (perdaEscoamento / total * 360.0).toFloat()

                        var startAngle = -90f

                        // Useful Arc
                        drawArc(
                            color = usefulColor,
                            startAngle = startAngle,
                            sweepAngle = usefulSweep,
                            useCenter = false,
                            topLeft = topLeft,
                            size = arcSize,
                            style = Stroke(width = strokeWidth)
                        )
                        startAngle += usefulSweep

                        // Percolacao Arc
                        drawArc(
                            color = percColor,
                            startAngle = startAngle,
                            sweepAngle = percSweep,
                            useCenter = false,
                            topLeft = topLeft,
                            size = arcSize,
                            style = Stroke(width = strokeWidth)
                        )
                        startAngle += percSweep

                        // Escoamento Arc
                        drawArc(
                            color = runoffColor,
                            startAngle = startAngle,
                            sweepAngle = runoffSweep,
                            useCenter = false,
                            topLeft = topLeft,
                            size = arcSize,
                            style = Stroke(width = strokeWidth)
                        )
                    }

                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = "${eficienciaAproveitada.toInt()}%",
                            style = MaterialTheme.typography.titleLarge,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Text(
                            text = "Aproveitado",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                // Legend Column
                Column(
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    LegendaItem(
                        cor = usefulColor,
                        label = "Aproveitado (Ea)",
                        valor = "${eficienciaAproveitada.toInt()}%"
                    )
                    LegendaItem(
                        cor = percColor,
                        label = "Percolação Profunda",
                        valor = "${perdaPercolacao.toInt()}%"
                    )
                    LegendaItem(
                        cor = runoffColor,
                        label = "Escoamento Superficial",
                        valor = "${perdaEscoamento.toInt()}%"
                    )
                }
            }
        }
    }
}

@Composable
private fun LegendaItem(cor: Color, label: String, valor: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(
            modifier = Modifier
                .size(12.dp)
                .clip(CircleShape)
                .background(cor)
        )
        Spacer(modifier = Modifier.width(8.dp))
        Column {
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = valor,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
    }
}
