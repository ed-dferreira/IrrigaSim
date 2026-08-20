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
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.irrigasim.domain.MetodoIrrigacao
import com.irrigasim.domain.Parametros
import com.irrigasim.ui.components.Campo
import com.irrigasim.ui.theme.AppIcons
import com.irrigasim.ui.viewmodel.ParametrosViewModel
import com.irrigasim.ui.viewmodel.rememberViewModel

/**
 * Tela de Entrada de Parâmetros Direta (Modo Rápido).
 */
@Composable
fun ParametrosScreen(
    metodo: MetodoIrrigacao,
    onSimular: (Parametros) -> Unit,
    onVoltar: () -> Unit
) {
    val viewModel = rememberViewModel { ParametrosViewModel(metodo) }
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
                Text(state.metodo.nome, style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.onPrimary)
            }
        }
        Column(Modifier.padding(24.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Text("Geometria do Terreno", style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.primary)
            Campo("Comprimento do terreno (m)", state.comprimento) { viewModel.atualizarComprimento(it) }

            Text("Declividade (2 Medidas)", style = MaterialTheme.typography.labelLarge)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Column(Modifier.weight(1f)) { Campo("Desnível ΔH (m)", state.desnivelM) { viewModel.atualizarDesnivel(it) } }
                Column(Modifier.weight(1f)) { Campo("Distância L (m)", state.distanciaHorizontalM) { viewModel.atualizarDistanciaHorizontal(it) } }
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
                        "Declividade S₀: ${"%.3f".format(state.declividadeCalculada)}%",
                        style = MaterialTheme.typography.titleSmall,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }
            }

            Campo(
                if (state.metodo == MetodoIrrigacao.SULCO) "Espaçamento entre sulcos (m)" else "Largura (m)",
                state.larguraOuEspacamento
            ) { viewModel.atualizarLarguraOuEspacamento(it) }

            Text("Solo — Kostiakov-Lewis", style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.primary, modifier = Modifier.padding(top = 8.dp))
            Campo("Coeficiente k (mm/hᵃ)", state.k) { viewModel.atualizarK(it) }
            Campo("Expoente a (0 < a < 1)", state.a) { viewModel.atualizarA(it) }
            Campo("Taxa básica de infiltração VIB (mm/h)", state.vib) { viewModel.atualizarVib(it) }

            Text("Manejo & Hidráulica", style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.primary, modifier = Modifier.padding(top = 8.dp))
            Campo(
                when (state.metodo) {
                    MetodoIrrigacao.SULCO -> "Vazão por sulco (L/s)"
                    MetodoIrrigacao.FAIXA -> "Vazão unitária (L/s/m)"
                    MetodoIrrigacao.INUNDACAO -> "Vazão total da bacia (L/s)"
                },
                state.vazao
            ) { viewModel.atualizarVazao(it) }
            Campo("Tempo de aplicação (min)", state.tempo) { viewModel.atualizarTempo(it) }
            Campo("Lâmina líquida requerida LN (mm)", state.lamina) { viewModel.atualizarLamina(it) }
            Campo("Rugosidade de Manning n", state.manningN) { viewModel.atualizarManningN(it) }

            Spacer(Modifier.height(8.dp))
            Button(
                onClick = { onSimular(viewModel.construirParametros()) },
                modifier = Modifier.fillMaxWidth().height(56.dp),
                shape = RoundedCornerShape(16.dp)
            ) {
                Text("Executar Simulação →", style = MaterialTheme.typography.titleMedium)
            }
        }
    }
}
