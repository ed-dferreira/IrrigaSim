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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.irrigasim.domain.MetodoIrrigacao
import com.irrigasim.domain.Parametros
import com.irrigasim.domain.Resultado
import com.irrigasim.ui.components.GraficoAvanco
import com.irrigasim.ui.components.GraficoBalancoHidrico
import com.irrigasim.ui.components.GraficoLaminaLongitudinal
import com.irrigasim.ui.components.KpiCard
import com.irrigasim.ui.viewmodel.ResultadoViewModel
import com.irrigasim.ui.viewmodel.rememberViewModel

@Composable
fun ResultadoScreen(
    resultado: Resultado,
    metodo: MetodoIrrigacao,
    parametros: Parametros,
    onVoltar: () -> Unit,
    onSalvarCenario: (String) -> Unit
) {
    val viewModel = rememberViewModel { ResultadoViewModel(metodo, parametros) }
    val state by viewModel.state.collectAsState()

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
                selectedTabIndex = state.abaSelecionada,
                containerColor = MaterialTheme.colorScheme.surfaceVariant,
                contentColor = MaterialTheme.colorScheme.primary
            ) {
                Tab(selected = state.abaSelecionada == 0, onClick = { viewModel.selecionarAba(0) }, text = { Text("Balanço Hídrico", style = MaterialTheme.typography.labelLarge) })
                Tab(selected = state.abaSelecionada == 1, onClick = { viewModel.selecionarAba(1) }, text = { Text("Curva Avanço", style = MaterialTheme.typography.labelLarge) })
                Tab(selected = state.abaSelecionada == 2, onClick = { viewModel.selecionarAba(2) }, text = { Text("Perfil Lâmina", style = MaterialTheme.typography.labelLarge) })
            }

            when (state.abaSelecionada) {
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
                    if (state.cenarioSalvo) {
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
                            value = state.nomeCenario,
                            onValueChange = { viewModel.atualizarNomeCenario(it) },
                            label = { Text("Nome do Cenário") },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            shape = RoundedCornerShape(12.dp)
                        )
                        Button(
                            onClick = { viewModel.salvarCenario(onSalvarCenario) },
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
