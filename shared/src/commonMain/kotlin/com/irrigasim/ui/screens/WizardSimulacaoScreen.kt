package com.irrigasim.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.irrigasim.domain.MetodoIrrigacao
import com.irrigasim.domain.Parametros
import com.irrigasim.ui.components.Campo
import com.irrigasim.ui.components.CustomChip
import com.irrigasim.ui.components.CustomProgressBar
import com.irrigasim.ui.theme.AppIcons

/**
 * Wizard Didático em 4 Etapas (Primeiro Acesso / Tutorial).
 */
@Composable
fun WizardSimulacaoScreen(
    userName: String = "Usuário",
    metodoInicial: MetodoIrrigacao = MetodoIrrigacao.SULCO,
    onSimular: (MetodoIrrigacao, Parametros) -> Unit,
    onIrParaModoDireto: () -> Unit
) {
    var etapa by remember { mutableStateOf(1) }
    var metodo by remember { mutableStateOf(metodoInicial) }

    var tipoSoloPreset by remember { mutableStateOf("franco") }
    var k by remember { mutableStateOf("45.0") }
    var a by remember { mutableStateOf("0.55") }
    var vib by remember { mutableStateOf("2.0") }
    var lamina by remember { mutableStateOf("50.0") }

    var comprimento by remember { mutableStateOf("100") }
    var desnivelM by remember { mutableStateOf("0.50") }
    var distanciaHorizontalM by remember { mutableStateOf("100") }
    var larguraOuEspacamento by remember { mutableStateOf("0.8") }

    var vazao by remember { mutableStateOf("0.6") }
    var tempo by remember { mutableStateOf("90") }
    var manningN by remember { mutableStateOf("0.04") }

    val desnivelVal = desnivelM.toDoubleOrNull() ?: 0.0
    val distanciaVal = distanciaHorizontalM.toDoubleOrNull() ?: 1.0
    val declividadeCalculada = if (distanciaVal > 0) (desnivelVal / distanciaVal) * 100.0 else 0.0

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
        // Barra Superior do Tutorial
        Surface(color = MaterialTheme.colorScheme.primaryContainer, shadowElevation = 2.dp) {
            Column(Modifier.padding(16.dp)) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        "Guia Didático — Aula 5",
                        style = MaterialTheme.typography.labelLarge,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                    TextButton(onClick = onIrParaModoDireto) {
                        Icon(
                            imageVector = AppIcons.PularTutorial,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(Modifier.width(4.dp))
                        Text("Pular Tutorial", color = MaterialTheme.colorScheme.primary, style = MaterialTheme.typography.labelMedium)
                    }
                }
                Text(
                    "Etapa $etapa de 4: ${
                        when (etapa) {
                            1 -> "Método de Irrigação (Superfície)"
                            2 -> "Solo & Requerimento de Água"
                            3 -> "Geometria & Topografia"
                            else -> "Manejo Hidráulico & Operação"
                        }
                    }",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
                Spacer(Modifier.height(8.dp))
                CustomProgressBar(progress = etapa / 4f)
            }
        }

        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            when (etapa) {
                1 -> {
                    Text("Fundamentos da Aula 5 — Irrigação por Superfície", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
                    Text(
                        "A água é aplicada diretamente no solo, escoando por gravidade ao longo do terreno.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    val metodosList = listOf(
                        Triple(MetodoIrrigacao.SULCO, "🌾 Sulcos (Furrow)", "Água escoa em canais paralelos entre as fileiras da cultura."),
                        Triple(MetodoIrrigacao.FAIXA, "📐 Faixa (Border)", "Água escoa em lâmina contínua em faixas delimitadas."),
                        Triple(MetodoIrrigacao.INUNDACAO, "💧 Inundação / Bacia", "Talhões nivelados cercados por taipas (ex.: arroz irrigado).")
                    )

                    metodosList.forEach { (m, titulo, desc) ->
                        val selected = metodo == m
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    metodo = m
                                    if (m == MetodoIrrigacao.SULCO && larguraOuEspacamento == "0.8") larguraOuEspacamento = "0.75"
                                },
                            shape = RoundedCornerShape(16.dp),
                            border = if (selected) BorderStroke(2.dp, MaterialTheme.colorScheme.primary) else null,
                            colors = CardDefaults.cardColors(
                                containerColor = if (selected) MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f) else MaterialTheme.colorScheme.surface
                            )
                        ) {
                            Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                                RadioButton(selected = selected, onClick = { metodo = m })
                                Spacer(Modifier.width(12.dp))
                                Column {
                                    Text(titulo, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
                                    Text(desc, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                }
                            }
                        }
                    }

                    Spacer(Modifier.height(8.dp))
                    Button(
                        onClick = { etapa = 2 },
                        modifier = Modifier.fillMaxWidth().height(52.dp),
                        shape = RoundedCornerShape(14.dp)
                    ) {
                        Text("Avançar: Solo & Cultura →", style = MaterialTheme.typography.titleMedium)
                    }
                }

                2 -> {
                    Text("Etapa 2 — Solo & Requerimento da Cultura", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
                    Text(
                        "Selecione um perfil de solo ou insira os parâmetros do modelo Kostiakov-Lewis.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    Text("Presets de Solo Agrícola", style = MaterialTheme.typography.labelLarge)
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        CustomChip(
                            selected = tipoSoloPreset == "arenoso",
                            onClick = { tipoSoloPreset = "arenoso"; k = "65.0"; a = "0.65"; vib = "5.0" },
                            label = "⏳ Arenoso"
                        )
                        CustomChip(
                            selected = tipoSoloPreset == "franco",
                            onClick = { tipoSoloPreset = "franco"; k = "45.0"; a = "0.55"; vib = "2.0" },
                            label = "🧱 Franco"
                        )
                        CustomChip(
                            selected = tipoSoloPreset == "argiloso",
                            onClick = { tipoSoloPreset = "argiloso"; k = "30.0"; a = "0.45"; vib = "0.8" },
                            label = "🪨 Argiloso"
                        )
                    }

                    Campo("Coeficiente k (mm/hᵃ)", k) { k = it; tipoSoloPreset = "custom" }
                    Campo("Expoente a (0 < a < 1)", a) { a = it; tipoSoloPreset = "custom" }
                    Campo("Taxa de Infiltração Básica VIB (mm/h)", vib) { vib = it; tipoSoloPreset = "custom" }

                    Box(Modifier.fillMaxWidth().padding(vertical = 4.dp).height(1.dp).background(MaterialTheme.colorScheme.outlineVariant))

                    Campo("Lâmina Líquida Requerida LN (mm)", lamina) { lamina = it }

                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        OutlinedButton(onClick = { etapa = 1 }, Modifier.weight(1f).height(52.dp), shape = RoundedCornerShape(14.dp)) { Text("← Voltar") }
                        Button(onClick = { etapa = 3 }, Modifier.weight(1f).height(52.dp), shape = RoundedCornerShape(14.dp)) { Text("Avançar →") }
                    }
                }

                3 -> {
                    Text("Etapa 3 — Geometria & Declividade do Terreno", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
                    Text(
                        "Meça o desnível vertical e a distância horizontal entre pontos para o cálculo exato da declividade.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    Campo("Comprimento do terreno L (m)", comprimento) { comprimento = it }

                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Column(Modifier.weight(1f)) { Campo("Desnível ΔH (m)", desnivelM) { desnivelM = it } }
                        Column(Modifier.weight(1f)) { Campo("Distância horiz. L (m)", distanciaHorizontalM) { distanciaHorizontalM = it } }
                    }

                    Card(
                        Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)
                    ) {
                        Row(Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                            Text("📐", fontSize = 24.sp)
                            Spacer(Modifier.width(12.dp))
                            Column {
                                Text("Declividade S₀ = ${"%.3f".format(declividadeCalculada)}%", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onPrimaryContainer)
                                Text("Fórmula: (ΔH / L) × 100 = (${"%.2f".format(desnivelVal)} / ${"%.0f".format(distanciaVal)}) × 100", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.8f))
                            }
                        }
                    }

                    Campo(if (metodo == MetodoIrrigacao.SULCO) "Espaçamento entre sulcos (m)" else "Largura (m)", larguraOuEspacamento) { larguraOuEspacamento = it }

                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        OutlinedButton(onClick = { etapa = 2 }, Modifier.weight(1f).height(52.dp), shape = RoundedCornerShape(14.dp)) { Text("← Voltar") }
                        Button(onClick = { etapa = 4 }, Modifier.weight(1f).height(52.dp), shape = RoundedCornerShape(14.dp)) { Text("Avançar →") }
                    }
                }

                4 -> {
                    Text("Etapa 4 — Manejo Hidráulico & Operação", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)

                    Campo(
                        when (metodo) {
                            MetodoIrrigacao.SULCO -> "Vazão por sulco Q (L/s)"
                            MetodoIrrigacao.FAIXA -> "Vazão unitária qu (L/s/m)"
                            MetodoIrrigacao.INUNDACAO -> "Vazão total da bacia Q (L/s)"
                        },
                        vazao
                    ) { vazao = it }

                    Campo("Tempo de aplicação Tap (min)", tempo) { tempo = it }
                    Campo("Coeficiente de Manning n", manningN) { manningN = it }

                    Card(
                        Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(14.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                    ) {
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text("📋 Resumo da Configuração", style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.primary)
                            Text("• Método: ${metodo.nome}", style = MaterialTheme.typography.bodyMedium)
                            Text("• Terreno: ${comprimento}m de extensão, S₀ = ${"%.2f".format(declividadeCalculada)}%", style = MaterialTheme.typography.bodyMedium)
                            Text("• Solo: k=${k}, a=${a}, VIB=${vib} mm/h", style = MaterialTheme.typography.bodyMedium)
                            Text("• Operação: Q = ${vazao} L/s por ${tempo} min | LN = ${lamina} mm", style = MaterialTheme.typography.bodyMedium)
                        }
                    }

                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        OutlinedButton(onClick = { etapa = 3 }, Modifier.weight(1f).height(54.dp), shape = RoundedCornerShape(14.dp)) { Text("← Voltar") }
                        Button(
                            onClick = {
                                onSimular(
                                    metodo,
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
                            Modifier.weight(1.5f).height(54.dp),
                            shape = RoundedCornerShape(14.dp)
                        ) {
                            Text("🚀 Executar Simulação", style = MaterialTheme.typography.titleMedium)
                        }
                    }
                }
            }
        }
    }
}
