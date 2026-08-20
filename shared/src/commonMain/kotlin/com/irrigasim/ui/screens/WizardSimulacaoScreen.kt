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
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
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
import com.irrigasim.ui.viewmodel.WizardViewModel
import com.irrigasim.ui.viewmodel.rememberViewModel

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
    val viewModel = rememberViewModel { WizardViewModel(metodoInicial) }
    val state by viewModel.state.collectAsState()

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
                    "Etapa ${state.etapa} de 4: ${
                        when (state.etapa) {
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
                CustomProgressBar(progress = state.etapa / 4f)
            }
        }

        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            when (state.etapa) {
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
                        val selected = state.metodo == m
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { viewModel.selecionarMetodo(m) },
                            shape = RoundedCornerShape(16.dp),
                            border = if (selected) BorderStroke(2.dp, MaterialTheme.colorScheme.primary) else null,
                            colors = CardDefaults.cardColors(
                                containerColor = if (selected) MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f) else MaterialTheme.colorScheme.surface
                            )
                        ) {
                            Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                                RadioButton(selected = selected, onClick = { viewModel.selecionarMetodo(m) })
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
                        onClick = { viewModel.avancarEtapa() },
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
                            selected = state.tipoSoloPreset == "arenoso",
                            onClick = { viewModel.aplicarPresetSolo("arenoso") },
                            label = "⏳ Arenoso"
                        )
                        CustomChip(
                            selected = state.tipoSoloPreset == "franco",
                            onClick = { viewModel.aplicarPresetSolo("franco") },
                            label = "🧱 Franco"
                        )
                        CustomChip(
                            selected = state.tipoSoloPreset == "argiloso",
                            onClick = { viewModel.aplicarPresetSolo("argiloso") },
                            label = "🪨 Argiloso"
                        )
                    }

                    Campo("Coeficiente k (mm/hᵃ)", state.k) { viewModel.atualizarK(it) }
                    Campo("Expoente a (0 < a < 1)", state.a) { viewModel.atualizarA(it) }
                    Campo("Taxa de Infiltração Básica VIB (mm/h)", state.vib) { viewModel.atualizarVib(it) }

                    Box(Modifier.fillMaxWidth().padding(vertical = 4.dp).height(1.dp).background(MaterialTheme.colorScheme.outlineVariant))

                    Campo("Lâmina Líquida Requerida LN (mm)", state.lamina) { viewModel.atualizarLamina(it) }

                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        OutlinedButton(onClick = { viewModel.voltarEtapa() }, Modifier.weight(1f).height(52.dp), shape = RoundedCornerShape(14.dp)) { Text("← Voltar") }
                        Button(onClick = { viewModel.avancarEtapa() }, Modifier.weight(1f).height(52.dp), shape = RoundedCornerShape(14.dp)) { Text("Avançar →") }
                    }
                }

                3 -> {
                    Text("Etapa 3 — Geometria & Declividade do Terreno", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
                    Text(
                        "Meça o desnível vertical e a distância horizontal entre pontos para o cálculo exato da declividade.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    Campo("Comprimento do terreno L (m)", state.comprimento) { viewModel.atualizarComprimento(it) }

                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Column(Modifier.weight(1f)) { Campo("Desnível ΔH (m)", state.desnivelM) { viewModel.atualizarDesnivel(it) } }
                        Column(Modifier.weight(1f)) { Campo("Distância horiz. L (m)", state.distanciaHorizontalM) { viewModel.atualizarDistanciaHorizontal(it) } }
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
                                Text("Declividade S₀ = ${"%.3f".format(state.declividadeCalculada)}%", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onPrimaryContainer)
                                Text("Fórmula: (ΔH / L) × 100 = (${"%.2f".format(state.desnivelValor)} / ${"%.0f".format(state.distanciaValor)}) × 100", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.8f))
                            }
                        }
                    }

                    Campo(if (state.metodo == MetodoIrrigacao.SULCO) "Espaçamento entre sulcos (m)" else "Largura (m)", state.larguraOuEspacamento) { viewModel.atualizarLarguraOuEspacamento(it) }

                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        OutlinedButton(onClick = { viewModel.voltarEtapa() }, Modifier.weight(1f).height(52.dp), shape = RoundedCornerShape(14.dp)) { Text("← Voltar") }
                        Button(onClick = { viewModel.avancarEtapa() }, Modifier.weight(1f).height(52.dp), shape = RoundedCornerShape(14.dp)) { Text("Avançar →") }
                    }
                }

                4 -> {
                    Text("Etapa 4 — Manejo Hidráulico & Operação", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)

                    Campo(
                        when (state.metodo) {
                            MetodoIrrigacao.SULCO -> "Vazão por sulco Q (L/s)"
                            MetodoIrrigacao.FAIXA -> "Vazão unitária qu (L/s/m)"
                            MetodoIrrigacao.INUNDACAO -> "Vazão total da bacia Q (L/s)"
                        },
                        state.vazao
                    ) { viewModel.atualizarVazao(it) }

                    Campo("Tempo de aplicação Tap (min)", state.tempo) { viewModel.atualizarTempo(it) }
                    Campo("Coeficiente de Manning n", state.manningN) { viewModel.atualizarManningN(it) }

                    Card(
                        Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(14.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                    ) {
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text("📋 Resumo da Configuração", style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.primary)
                            Text("• Método: ${state.metodo.nome}", style = MaterialTheme.typography.bodyMedium)
                            Text("• Terreno: ${state.comprimento}m de extensão, S₀ = ${"%.2f".format(state.declividadeCalculada)}%", style = MaterialTheme.typography.bodyMedium)
                            Text("• Solo: k=${state.k}, a=${state.a}, VIB=${state.vib} mm/h", style = MaterialTheme.typography.bodyMedium)
                            Text("• Operação: Q = ${state.vazao} L/s por ${state.tempo} min | LN = ${state.lamina} mm", style = MaterialTheme.typography.bodyMedium)
                        }
                    }

                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        OutlinedButton(onClick = { viewModel.voltarEtapa() }, Modifier.weight(1f).height(54.dp), shape = RoundedCornerShape(14.dp)) { Text("← Voltar") }
                        Button(
                            onClick = { onSimular(state.metodo, viewModel.construirParametros()) },
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
