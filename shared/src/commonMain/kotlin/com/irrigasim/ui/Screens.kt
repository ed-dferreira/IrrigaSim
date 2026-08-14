package com.irrigasim.ui

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.irrigasim.domain.*
import com.irrigasim.ui.components.GraficoAvanco
import com.irrigasim.ui.components.GraficoBalancoHidrico
import com.irrigasim.ui.components.GraficoLaminaLongitudinal

/**
 * Componente de Chip Customizado à prova de falhas de versão Compose.
 */
@Composable
fun CustomChip(selected: Boolean, label: String, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(20.dp),
        color = if (selected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant,
        border = if (selected) androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.primary) else null
    ) {
        Text(
            text = label,
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
            style = MaterialTheme.typography.labelMedium,
            color = if (selected) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

/**
 * Barra de progresso visual customizada à prova de falhas Compose.
 */
@Composable
fun CustomProgressBar(progress: Float) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(8.dp)
            .clip(CircleShape)
            .background(MaterialTheme.colorScheme.surfaceVariant)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth(fraction = progress.coerceIn(0.01f, 1f))
                .fillMaxHeight()
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.primary)
        )
    }
}

/**
 * Tela Inicial Rápida de Seleção de Método (Para uso frequente).
 */
@Composable
fun MetodoScreen(
    userName: String = "Usuário",
    onSelecionar: (MetodoIrrigacao) -> Unit,
    onAbrirTutorial: () -> Unit
) {
    val metodos = listOf(
        Triple(MetodoIrrigacao.SULCO, "Sulcos (Furrow)", "🌾 Canais paralelos entre fileiras de cultivo"),
        Triple(MetodoIrrigacao.FAIXA, "Faixa (Border)", "📐 Lâmina contínua em declive delimitada"),
        Triple(MetodoIrrigacao.INUNDACAO, "Inundação / Bacia", "💧 Talhões nivelados cercados por taipas")
    )

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(24.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Column {
                Text(
                    "Olá, ${userName.split(" ").firstOrNull() ?: userName} 👋",
                    style = MaterialTheme.typography.headlineMedium,
                    color = MaterialTheme.colorScheme.onBackground
                )
                Text(
                    "Escolha o método de irrigação por superfície",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        // Card de Tutorial / Guia Didático
        Card(
            modifier = Modifier.fillMaxWidth().clickable { onAbrirTutorial() },
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)
        ) {
            Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                Text("📚", fontSize = 32.sp)
                Spacer(Modifier.width(16.dp))
                Column(Modifier.weight(1f)) {
                    Text("Guia Didático da Aula 5", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onPrimaryContainer)
                    Text("Passo a passo fundamentado em 4 etapas", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.8f))
                }
                Text("→", fontSize = 24.sp, color = MaterialTheme.colorScheme.primary)
            }
        }

        Text("Métodos de Superfície Rápido", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)

        metodos.forEach { (m, titulo, desc) ->
            Card(
                Modifier.fillMaxWidth().clickable { onSelecionar(m) },
                shape = RoundedCornerShape(16.dp),
                elevation = CardDefaults.cardElevation(2.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Row(Modifier.padding(20.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        Modifier.size(52.dp).clip(RoundedCornerShape(14.dp))
                            .background(MaterialTheme.colorScheme.secondaryContainer),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            when (m) {
                                MetodoIrrigacao.SULCO -> "🌾"
                                MetodoIrrigacao.FAIXA -> "📐"
                                MetodoIrrigacao.INUNDACAO -> "💧"
                            },
                            fontSize = 26.sp
                        )
                    }
                    Spacer(Modifier.width(16.dp))
                    Column(Modifier.weight(1f)) {
                        Text(titulo, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
                        Text(desc, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    Text("⚡ Simular", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary)
                }
            }
        }
    }
}

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
                    Text("📐", fontSize = 20.sp)
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
                        Text("Pular Tutorial ⚡", color = MaterialTheme.colorScheme.primary, style = MaterialTheme.typography.labelMedium)
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
                            border = if (selected) androidx.compose.foundation.BorderStroke(2.dp, MaterialTheme.colorScheme.primary) else null,
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

@Composable
fun Campo(label: String, value: String, onChange: (String) -> Unit) {
    OutlinedTextField(
        value = value,
        onValueChange = onChange,
        label = { Text(label) },
        modifier = Modifier.fillMaxWidth(),
        singleLine = true,
        shape = RoundedCornerShape(12.dp)
    )
}

@Composable
fun ResultadoScreen(
    resultado: Resultado,
    metodo: MetodoIrrigacao,
    parametros: Parametros,
    onVoltar: () -> Unit,
    onSalvarCenario: (String) -> Unit
) {
    var abaSelecionada by remember { mutableStateOf(0) }
    var cenarioSalvo by remember { mutableStateOf(false) }
    var nomeCenario by remember { mutableStateOf("${metodo.nome} — ${parametros.comprimento.toInt()}m (${parametros.vazao} L/s)") }

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
                Text("Resultados da Simulação", style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.onPrimary)
            }
        }

        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            // Cards de KPIs principais
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                KpiCard("Eficiência Ea", "${resultado.eficiencia.toInt()}%", MaterialTheme.colorScheme.secondary, Modifier.weight(1f))
                KpiCard("Requerimento Er", "${resultado.eficienciaRequerimento.toInt()}%", MaterialTheme.colorScheme.primary, Modifier.weight(1f))
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                KpiCard("Uniform. CUC", "${resultado.cuc.toInt()}%", MaterialTheme.colorScheme.tertiary, Modifier.weight(1f))
                KpiCard("Distr. DU", "${resultado.du.toInt()}%", MaterialTheme.colorScheme.outline, Modifier.weight(1f))
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                KpiCard("Lâmina Média", "${"%.1f".format(resultado.laminaMedia)} mm", MaterialTheme.colorScheme.primary, Modifier.weight(1f))
                KpiCard("Tempo Avanço", "${resultado.tempoAvanco.toInt()} min", MaterialTheme.colorScheme.secondary, Modifier.weight(1f))
            }

            // Abas de Gráficos Descritivos
            TabRow(
                selectedTabIndex = abaSelecionada,
                containerColor = MaterialTheme.colorScheme.surfaceVariant,
                contentColor = MaterialTheme.colorScheme.primary
            ) {
                Tab(selected = abaSelecionada == 0, onClick = { abaSelecionada = 0 }, text = { Text("Balanço Hídrico", style = MaterialTheme.typography.labelLarge) })
                Tab(selected = abaSelecionada == 1, onClick = { abaSelecionada = 1 }, text = { Text("Curva Avanço", style = MaterialTheme.typography.labelLarge) })
                Tab(selected = abaSelecionada == 2, onClick = { abaSelecionada = 2 }, text = { Text("Perfil Lâmina", style = MaterialTheme.typography.labelLarge) })
            }

            when (abaSelecionada) {
                0 -> GraficoBalancoHidrico(
                    eficienciaAproveitada = resultado.eficiencia,
                    perdaPercolacao = resultado.perdaPercolacao,
                    perdaEscoamento = resultado.perdaEscoamento
                )
                1 -> GraficoAvanco(
                    pontos = resultado.curvaAvanco,
                    comprimentoMax = resultado.curvaAvanco.maxOfOrNull { it.y } ?: 100.0,
                    tempoAvanco = resultado.tempoAvanco
                )
                2 -> GraficoLaminaLongitudinal(
                    perfil = resultado.perfilLongitudinal,
                    laminaRequerida = parametros.laminaRequerida,
                    cuc = resultado.cuc,
                    du = resultado.du
                )
            }

            // Recomendação Didática
            val bom = resultado.eficiencia >= 75 && resultado.cuc >= 80
            Card(
                Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = if (bom) MaterialTheme.colorScheme.secondaryContainer else MaterialTheme.colorScheme.errorContainer)
            ) {
                Row(Modifier.padding(20.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(if (bom) "🏆" else "⚠️", fontSize = 32.sp)
                    Spacer(Modifier.width(16.dp))
                    Column {
                        Text(
                            text = if (bom) "Desempenho Didático Excelente!" else "Atenção: Otimização Recomendada",
                            style = MaterialTheme.typography.titleMedium,
                            color = if (bom) MaterialTheme.colorScheme.onSecondaryContainer else MaterialTheme.colorScheme.onErrorContainer
                        )
                        Spacer(Modifier.height(4.dp))
                        Text(
                            text = resultado.resumoTextual.ifBlank {
                                if (bom) "Os parâmetros configurados resultam em alta eficiência de aplicação e boa uniformidade."
                                else "A eficiência ou uniformidade está abaixo do ideal. Ajuste a vazão ou o tempo de aplicação."
                            },
                            style = MaterialTheme.typography.bodyMedium,
                            color = if (bom) MaterialTheme.colorScheme.onSecondaryContainer else MaterialTheme.colorScheme.onErrorContainer
                        )
                    }
                }
            }

            // Bloco de Salvamento de Cenário
            Card(
                Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                elevation = CardDefaults.cardElevation(2.dp)
            ) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("💾 Salvar este Cenário", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
                    if (cenarioSalvo) {
                        Surface(
                            color = MaterialTheme.colorScheme.secondaryContainer,
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Row(Modifier.fillMaxWidth().padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                                Text("✅", fontSize = 24.sp)
                                Spacer(Modifier.width(12.dp))
                                Column {
                                    Text("Cenário salvo com sucesso!", style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.onSecondaryContainer)
                                    Text("Disponível na aba 'Cenários' para consulta futura.", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSecondaryContainer.copy(alpha = 0.8f))
                                }
                            }
                        }
                    } else {
                        OutlinedTextField(
                            value = nomeCenario,
                            onValueChange = { nomeCenario = it },
                            label = { Text("Nome do Cenário") },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            shape = RoundedCornerShape(12.dp)
                        )
                        Button(
                            onClick = {
                                if (nomeCenario.isNotBlank()) {
                                    onSalvarCenario(nomeCenario)
                                    cenarioSalvo = true
                                }
                            },
                            modifier = Modifier.fillMaxWidth().height(48.dp),
                            shape = RoundedCornerShape(12.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondary)
                        ) {
                            Text("Salvar na Minha Conta 💾", style = MaterialTheme.typography.titleMedium)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun KpiCard(label: String, value: String, color: Color, modifier: Modifier = Modifier) {
    Card(
        modifier,
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        elevation = CardDefaults.cardElevation(2.dp)
    ) {
        Column(Modifier.padding(14.dp)) {
            Text(label, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(Modifier.height(4.dp))
            Text(value, style = MaterialTheme.typography.titleLarge, color = color)
        }
    }
}

@Composable
fun HistoricoScreen(
    cenarios: List<CenarioSalvo>,
    onVisualizarCenario: (CenarioSalvo) -> Unit,
    onExcluirCenario: (String) -> Unit,
    onNovoCenario: () -> Unit
) {
    Column(Modifier.fillMaxSize().padding(20.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Column {
                Text("Cenários Salvos", style = MaterialTheme.typography.headlineMedium, color = MaterialTheme.colorScheme.onBackground)
                Text("${cenarios.size} simulação(ões) registrada(s)", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (cenarios.isNotEmpty()) {
                IconButton(onClick = onNovoCenario) {
                    Text("➕", fontSize = 24.sp)
                }
            }
        }

        Spacer(Modifier.height(16.dp))

        if (cenarios.isEmpty()) {
            Column(
                Modifier.fillMaxSize(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Box(Modifier.size(80.dp).clip(CircleShape).background(MaterialTheme.colorScheme.primaryContainer), contentAlignment = Alignment.Center) { Text("📋", fontSize = 36.sp) }
                Spacer(Modifier.height(16.dp))
                Text("Nenhum cenário salvo ainda", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text("Execute uma simulação e clique em 'Salvar'\npara registrar seus testes aqui.", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.outline, modifier = Modifier.padding(top = 8.dp))
                Spacer(Modifier.height(24.dp))
                Button(onClick = onNovoCenario, shape = RoundedCornerShape(14.dp)) {
                    Text("Criar Nova Simulação 🚀")
                }
            }
        } else {
            Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                cenarios.forEach { cenario ->
                    Card(
                        Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp),
                        elevation = CardDefaults.cardElevation(2.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                    ) {
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                                Text(cenario.titulo, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
                                Surface(
                                    color = MaterialTheme.colorScheme.primaryContainer,
                                    shape = RoundedCornerShape(8.dp)
                                ) {
                                    Text(cenario.metodo.nome, Modifier.padding(horizontal = 8.dp, vertical = 4.dp), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onPrimaryContainer)
                                }
                            }

                            Text(
                                "📅 Salvo em: ${cenario.dataHora}",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.outline
                            )

                            Box(Modifier.fillMaxWidth().height(1.dp).background(MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)))

                            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                Column {
                                    Text("Eficiência (Ea)", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.outline)
                                    Text("${cenario.resultado.eficiencia.toInt()}%", style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.secondary)
                                }
                                Column {
                                    Text("Uniformidade (CUC)", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.outline)
                                    Text("${cenario.resultado.cuc.toInt()}%", style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.tertiary)
                                }
                                Column {
                                    Text("Lâmina Média", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.outline)
                                    Text("${"%.1f".format(cenario.resultado.laminaMedia)} mm", style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.primary)
                                }
                            }

                            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                OutlinedButton(
                                    onClick = { onVisualizarCenario(cenario) },
                                    modifier = Modifier.weight(1f).height(44.dp),
                                    shape = RoundedCornerShape(10.dp)
                                ) {
                                    Text("👁️ Visualizar")
                                }
                                IconButton(
                                    onClick = { onExcluirCenario(cenario.id) }
                                ) {
                                    Text("🗑️", fontSize = 18.sp)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun PerfilScreen(usuario: Usuario?, isDarkTheme: Boolean, onToggleDarkTheme: (Boolean) -> Unit, onLogout: () -> Unit) {
    var editando by remember { mutableStateOf(false) }
    var nome by remember { mutableStateOf(usuario?.nome ?: "") }
    var instituicao by remember { mutableStateOf(usuario?.instituicao ?: "") }
    var curso by remember { mutableStateOf(usuario?.curso ?: "") }

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(24.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("Meu Perfil", style = MaterialTheme.typography.headlineLarge, color = MaterialTheme.colorScheme.onBackground)

        Card(Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp), elevation = CardDefaults.cardElevation(2.dp)) {
            Column(Modifier.padding(20.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Box(Modifier.size(72.dp).clip(CircleShape).background(MaterialTheme.colorScheme.primaryContainer), contentAlignment = Alignment.Center) {
                    Text(usuario?.nome?.firstOrNull()?.uppercase() ?: "?", style = MaterialTheme.typography.headlineLarge, color = MaterialTheme.colorScheme.primary)
                }
                Spacer(Modifier.height(12.dp))
                if (editando) {
                    OutlinedTextField(nome, { nome = it }, label = { Text("Nome") }, modifier = Modifier.fillMaxWidth(), singleLine = true, shape = RoundedCornerShape(12.dp))
                    OutlinedTextField(instituicao, { instituicao = it }, label = { Text("Instituição") }, modifier = Modifier.fillMaxWidth(), singleLine = true, shape = RoundedCornerShape(12.dp))
                    OutlinedTextField(curso, { curso = it }, label = { Text("Curso") }, modifier = Modifier.fillMaxWidth(), singleLine = true, shape = RoundedCornerShape(12.dp))
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        OutlinedButton({ editando = false }, Modifier.weight(1f), shape = RoundedCornerShape(12.dp)) { Text("Cancelar") }
                        Button({ editando = false }, Modifier.weight(1f), shape = RoundedCornerShape(12.dp)) { Text("Salvar") }
                    }
                } else {
                    Text(usuario?.nome ?: "Usuário", style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.onSurface)
                    Text(usuario?.email ?: "", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    if (!usuario?.instituicao.isNullOrBlank()) Text("${usuario?.instituicao} • ${usuario?.curso}", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.height(8.dp))
                    TextButton({ editando = true }) { Text("✏️ Editar perfil", color = MaterialTheme.colorScheme.primary, style = MaterialTheme.typography.titleMedium) }
                }
            }
        }

        Text("Acessibilidade", style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.onBackground, modifier = Modifier.padding(top = 8.dp))
        Card(Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp), elevation = CardDefaults.cardElevation(2.dp)) {
            Column {
                Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 16.dp), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                    Column { Text("Tema escuro", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface); Text("Reduz o brilho da tela", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant) }
                    Switch(isDarkTheme, onToggleDarkTheme)
                }
            }
        }

        Text("Sobre", style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.onBackground, modifier = Modifier.padding(top = 8.dp))
        Card(Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp), elevation = CardDefaults.cardElevation(2.dp)) {
            Column(Modifier.padding(20.dp)) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) { Text("Versão", style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurface); Text("1.0.0", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant) }
                Spacer(Modifier.height(12.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) { Text("Desenvolvido por", style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurface); Text("UFLA/DEG", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant) }
                Spacer(Modifier.height(12.dp))
                Text("Modelos: Kostiakov-Lewis + Balanço de Volume", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }

        Spacer(Modifier.height(8.dp))
        OutlinedButton(onLogout, Modifier.fillMaxWidth().height(54.dp), shape = RoundedCornerShape(12.dp), border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.error)) {
            Text("Sair da conta", color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.titleMedium)
        }
        Spacer(Modifier.height(16.dp))
    }
}
