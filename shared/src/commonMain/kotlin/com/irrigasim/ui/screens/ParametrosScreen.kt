package com.irrigasim.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.irrigasim.domain.MetodoIrrigacao
import com.irrigasim.domain.Parametros
import com.irrigasim.ui.components.Campo
import com.irrigasim.ui.theme.AppIcons

/**
 * Tela de Entrada de Parâmetros Direta (Modo Rápido).
 */
@Composable
fun ParametrosScreen(
    metodo: MetodoIrrigacao,
    onSimular: (Parametros) -> Unit,
    onVoltar: () -> Unit
) {
    var comprimento by remember { mutableStateOf("100") }
    var desnivelM by remember { mutableStateOf("0.50") }
    var distanciaHorizontalM by remember { mutableStateOf("100") }
    var larguraOuEspacamento by remember { mutableStateOf(if (metodo == MetodoIrrigacao.SULCO) "0.75" else "0.8") }
    var k by remember { mutableStateOf("45.0") }
    var a by remember { mutableStateOf("0.55") }
    var vib by remember { mutableStateOf("2.0") }
    var vazao by remember { mutableStateOf(if (metodo == MetodoIrrigacao.INUNDACAO) "15.0" else "0.6") }
    var tempo by remember { mutableStateOf("90") }
    var lamina by remember { mutableStateOf("50") }
    var manningN by remember { mutableStateOf("0.04") }

    val desnivelVal = desnivelM.toDoubleOrNull() ?: 0.0
    val distanciaVal = distanciaHorizontalM.toDoubleOrNull() ?: 1.0
    val declividadeCalculada = if (distanciaVal > 0) (desnivelVal / distanciaVal) * 100.0 else 0.0

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
        Surface(color = MaterialTheme.colorScheme.primary, shadowElevation = 4.dp) {
            Row(
                Modifier.fillMaxWidth().padding(16.dp).height(48.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    "←",
                    style = MaterialTheme.typography.headlineLarge,
                    color = MaterialTheme.colorScheme.onPrimary,
                    modifier = Modifier.clickable { onVoltar() }.padding(end = 16.dp)
                )
                Text(metodo.nome, style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.onPrimary)
            }
        }
        Column(Modifier.padding(24.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Text("Geometria do Terreno", style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.primary)
            Campo("Comprimento do terreno (m)", comprimento) { comprimento = it }

            Text("Declividade (2 Medidas)", style = MaterialTheme.typography.labelLarge)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Column(Modifier.weight(1f)) { Campo("Desnível ΔH (m)", desnivelM) { desnivelM = it } }
                Column(Modifier.weight(1f)) { Campo("Distância L (m)", distanciaHorizontalM) { distanciaHorizontalM = it } }
            }

            Card(
                Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)
            ) {
                Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = AppIcons.Declividade,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onPrimaryContainer,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(Modifier.width(8.dp))
                    Text(
                        "Declividade S₀: ${"%.3f".format(declividadeCalculada)}%",
                        style = MaterialTheme.typography.titleSmall,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }
            }

            Campo(
                if (metodo == MetodoIrrigacao.SULCO) "Espaçamento entre sulcos (m)" else "Largura (m)",
                larguraOuEspacamento
            ) { larguraOuEspacamento = it }

            Text("Solo — Kostiakov-Lewis", style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.primary, modifier = Modifier.padding(top = 8.dp))
            Campo("Coeficiente k (mm/hᵃ)", k) { k = it }
            Campo("Expoente a (0 < a < 1)", a) { a = it }
            Campo("Taxa básica de infiltração VIB (mm/h)", vib) { vib = it }

            Text("Manejo & Hidráulica", style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.primary, modifier = Modifier.padding(top = 8.dp))
            Campo(
                when (metodo) {
                    MetodoIrrigacao.SULCO -> "Vazão por sulco (L/s)"
                    MetodoIrrigacao.FAIXA -> "Vazão unitária (L/s/m)"
                    MetodoIrrigacao.INUNDACAO -> "Vazão total da bacia (L/s)"
                },
                vazao
            ) { vazao = it }
            Campo("Tempo de aplicação (min)", tempo) { tempo = it }
            Campo("Lâmina líquida requerida LN (mm)", lamina) { lamina = it }
            Campo("Rugosidade de Manning n", manningN) { manningN = it }

            Spacer(Modifier.height(8.dp))
            Button(
                onClick = {
                    onSimular(
                        Parametros(
                            comprimento = (comprimento.toDoubleOrNull() ?: 100.0).coerceAtLeast(10.0),
                            declividade = declividadeCalculada.coerceAtLeast(0.001),
                            larguraOuEspacamento = (larguraOuEspacamento.toDoubleOrNull() ?: 0.8).coerceAtLeast(0.1),
                            k = (k.toDoubleOrNull() ?: 45.0).coerceAtLeast(1.0),
                            a = (a.toDoubleOrNull() ?: 0.55).coerceIn(0.01, 0.99),
                            vib = (vib.toDoubleOrNull() ?: 2.0).coerceAtLeast(0.1),
                            vazao = (vazao.toDoubleOrNull() ?: 0.6).coerceAtLeast(0.01),
                            tempoAplicacao = (tempo.toDoubleOrNull() ?: 90.0).coerceAtLeast(1.0),
                            laminaRequerida = (lamina.toDoubleOrNull() ?: 50.0).coerceAtLeast(1.0),
                            manningN = (manningN.toDoubleOrNull() ?: 0.04).coerceAtLeast(0.01)
                        )
                    )
                },
                modifier = Modifier.fillMaxWidth().height(56.dp),
                shape = RoundedCornerShape(16.dp)
            ) {
                Text("Executar Simulação →", style = MaterialTheme.typography.titleMedium)
            }
        }
    }
}
