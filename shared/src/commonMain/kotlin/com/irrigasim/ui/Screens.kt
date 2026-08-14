package com.irrigasim.ui

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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.irrigasim.domain.*
import com.irrigasim.ui.components.GraficoAvanco
import com.irrigasim.ui.components.GraficoBalancoHidrico
import com.irrigasim.ui.components.GraficoLaminaLongitudinal

@Composable
fun MetodoScreen(userName: String = "Usuário", onSelecionar: (MetodoIrrigacao) -> Unit) {
    val metodos = listOf(
        MetodoIrrigacao.SULCO to "Sulcos - Canais paralelos com sulcos de infiltração",
        MetodoIrrigacao.FAIXA to "Faixa (Border) - Lâmina contínua em declive",
        MetodoIrrigacao.INUNDACAO to "Inundação / Bacia - Talhões nivelados de grande volume"
    )
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(24.dp)) {
        Text(
            "Olá, ${userName.split(" ").firstOrNull() ?: userName} 👋",
            style = MaterialTheme.typography.headlineLarge,
            color = MaterialTheme.colorScheme.onBackground
        )
        Text(
            "Escolha o método de irrigação por superfície",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(Modifier.height(24.dp))
        metodos.forEach { (metodo, desc) ->
            Card(
                Modifier.fillMaxWidth().padding(vertical = 8.dp).clickable { onSelecionar(metodo) },
                shape = RoundedCornerShape(16.dp),
                elevation = CardDefaults.cardElevation(2.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Row(Modifier.padding(20.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        Modifier.size(56.dp).clip(RoundedCornerShape(16.dp))
                            .background(MaterialTheme.colorScheme.primaryContainer),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            when (metodo) {
                                MetodoIrrigacao.SULCO -> "🌾"
                                MetodoIrrigacao.FAIXA -> "📐"
                                MetodoIrrigacao.INUNDACAO -> "💧"
                            },
                            fontSize = 28.sp
                        )
                    }
                    Spacer(Modifier.width(20.dp))
                    Column {
                        Text(metodo.nome, style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.onSurface)
                        Text(desc, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
        }
    }
}

@Composable
fun ParametrosScreen(metodo: MetodoIrrigacao, onSimular: (Parametros) -> Unit, onVoltar: () -> Unit) {
    var comprimento by remember { mutableStateOf("100") }
    var declividade by remember { mutableStateOf("0.5") }
    var larguraOuEspacamento by remember { mutableStateOf(if (metodo == MetodoIrrigacao.SULCO) "0.75" else "0.8") }
    var k by remember { mutableStateOf("45") }
    var a by remember { mutableStateOf("0.55") }
    var vib by remember { mutableStateOf("2.0") }
    var vazao by remember { mutableStateOf(if (metodo == MetodoIrrigacao.INUNDACAO) "15.0" else "0.6") }
    var tempo by remember { mutableStateOf("90") }
    var lamina by remember { mutableStateOf("50") }
    var manningN by remember { mutableStateOf("0.04") }

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
            Campo("Declividade (%)", declividade) { declividade = it }
            Campo(
                if (metodo == MetodoIrrigacao.SULCO) "Espaçamento entre sulcos (m)" else "Largura (m)",
                larguraOuEspacamento
            ) { larguraOuEspacamento = it }

            Text("Solo — Modelo Kostiakov-Lewis", style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.primary, modifier = Modifier.padding(top = 8.dp))
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
                            comprimento = comprimento.toDoubleOrNull() ?: 100.0,
                            declividade = declividade.toDoubleOrNull() ?: 0.5,
                            larguraOuEspacamento = larguraOuEspacamento.toDoubleOrNull() ?: 0.8,
                            k = k.toDoubleOrNull() ?: 45.0,
                            a = a.toDoubleOrNull() ?: 0.55,
                            vib = vib.toDoubleOrNull() ?: 2.0,
                            vazao = vazao.toDoubleOrNull() ?: 0.6,
                            tempoAplicacao = tempo.toDoubleOrNull() ?: 90.0,
                            laminaRequerida = lamina.toDoubleOrNull() ?: 50.0,
                            manningN = manningN.toDoubleOrNull() ?: 0.04
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
fun ResultadoScreen(resultado: Resultado, onVoltar: () -> Unit) {
    var abaSelecionada by remember { mutableStateOf(0) }

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
                Tab(
                    selected = abaSelecionada == 0,
                    onClick = { abaSelecionada = 0 },
                    text = { Text("Balanço Hídrico", style = MaterialTheme.typography.labelLarge) }
                )
                Tab(
                    selected = abaSelecionada == 1,
                    onClick = { abaSelecionada = 1 },
                    text = { Text("Curva Avanço", style = MaterialTheme.typography.labelLarge) }
                )
                Tab(
                    selected = abaSelecionada == 2,
                    onClick = { abaSelecionada = 2 },
                    text = { Text("Perfil Lâmina", style = MaterialTheme.typography.labelLarge) }
                )
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
                    laminaRequerida = 50.0,
                    cuc = resultado.cuc,
                    du = resultado.du
                )
            }

            // Card de Recomendação Didática
            val bom = resultado.eficiencia >= 75 && resultado.cuc >= 80
            Card(
                Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = if (bom) MaterialTheme.colorScheme.secondaryContainer else MaterialTheme.colorScheme.errorContainer
                )
            ) {
                Row(Modifier.padding(20.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        if (bom) "🏆" else "⚠️",
                        fontSize = 32.sp,
                        color = if (bom) MaterialTheme.colorScheme.secondary else MaterialTheme.colorScheme.error
                    )
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
        }
    }
}

@Composable
fun KpiCard(label: String, value: String, color: androidx.compose.ui.graphics.Color, modifier: Modifier = Modifier) {
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
fun HistoricoScreen() {
    Column(Modifier.fillMaxSize().padding(24.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Text("Cenários Salvos", style = MaterialTheme.typography.headlineLarge, color = MaterialTheme.colorScheme.onBackground)
        Spacer(Modifier.height(8.dp))
        Text("Histórico de simulações realizadas", style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(Modifier.height(48.dp))
        Box(Modifier.size(80.dp).clip(CircleShape).background(MaterialTheme.colorScheme.primaryContainer), contentAlignment = Alignment.Center) { Text("📋", fontSize = 36.sp) }
        Spacer(Modifier.height(16.dp))
        Text("Nenhum cenário salvo", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text("Execute uma simulação para\nver os resultados aqui", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.outline, modifier = Modifier.padding(top = 8.dp))
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
