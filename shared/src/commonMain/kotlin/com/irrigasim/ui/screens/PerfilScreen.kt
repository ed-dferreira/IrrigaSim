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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Slider
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.irrigasim.data.TamanhoFonte
import com.irrigasim.domain.MetodoIrrigacao
import com.irrigasim.domain.Usuario
import com.irrigasim.ui.theme.AppIcons
import com.irrigasim.ui.viewmodel.PerfilViewModel

private const val VERSAO_APP = "1.0.0"
private const val URL_CHANGELOG = "https://github.com/lowgue/IrrigaSim/releases"

@Composable
fun PerfilScreen(
    viewModel: PerfilViewModel,
    usuario: Usuario?,
    onLogout: () -> Unit
) {
    val state by viewModel.state.collectAsState()
    val uriHandler = LocalUriHandler.current

    // Mantém os campos sincronizados com a conta autenticada fora do modo edição
    LaunchedEffect(usuario) {
        viewModel.sincronizarCom(usuario)
    }

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(24.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("Meu perfil", style = MaterialTheme.typography.headlineLarge, color = MaterialTheme.colorScheme.onBackground)

        Card(Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp), elevation = CardDefaults.cardElevation(2.dp)) {
            Column(Modifier.padding(20.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                AvatarUsuario(
                    fotoUrl = usuario?.fotoUrl,
                    nome = usuario?.nome ?: "",
                    tamanho = 96.dp
                )
                Spacer(Modifier.height(12.dp))
                if (state.editando) {
                    OutlinedTextField(state.nome, { viewModel.atualizarNome(it) }, label = { Text("Nome") }, modifier = Modifier.fillMaxWidth(), singleLine = true, shape = RoundedCornerShape(12.dp))
                    OutlinedTextField(state.instituicao, { viewModel.atualizarInstituicao(it) }, label = { Text("Instituição") }, modifier = Modifier.fillMaxWidth(), singleLine = true, shape = RoundedCornerShape(12.dp))
                    OutlinedTextField(state.curso, { viewModel.atualizarCurso(it) }, label = { Text("Curso") }, modifier = Modifier.fillMaxWidth(), singleLine = true, shape = RoundedCornerShape(12.dp))
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        OutlinedButton({ viewModel.cancelarEdicao() }, Modifier.weight(1f), shape = RoundedCornerShape(12.dp)) { Text("Cancelar") }
                        Button({ viewModel.salvarEdicao() }, Modifier.weight(1f), shape = RoundedCornerShape(12.dp)) { Text("Salvar") }
                    }
                } else {
                    Text(usuario?.nome ?: "Usuário", style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.onSurface)
                    Text(usuario?.email ?: "", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    if (!usuario?.instituicao.isNullOrBlank()) Text("${usuario?.instituicao} • ${usuario?.curso}", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.height(8.dp))
                    TextButton({ viewModel.iniciarEdicao() }) { Text("✏️ Editar perfil", color = MaterialTheme.colorScheme.primary, style = MaterialTheme.typography.titleMedium) }
                }
            }
        }

        SecaoTitulo("Estatísticas")
        Card(Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp), elevation = CardDefaults.cardElevation(2.dp)) {
            Row(Modifier.fillMaxWidth().padding(16.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                CartaoEstatistica(
                    valor = state.totalSimulacoes.toString(),
                    rotulo = "Simulações salvas",
                    icone = AppIcons.Estatisticas,
                    modifier = Modifier.weight(1f)
                )
                CartaoEstatistica(
                    valor = state.metodoFavorito?.nome ?: "—",
                    rotulo = "Método favorito",
                    icone = iconeMetodo(state.metodoFavorito),
                    modifier = Modifier.weight(1f)
                )
            }
        }

        SecaoTitulo("Acessibilidade")
        Card(Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp), elevation = CardDefaults.cardElevation(2.dp)) {
            Column {
                ConfigSwitchRow(
                    titulo = "Tema escuro",
                    descricao = "Reduz o brilho da tela",
                    icone = AppIcons.TemaEscuro,
                    checked = state.temaEscuro,
                    onCheckedChange = { viewModel.alternarTemaEscuro(it) }
                )
                Divider(Modifier.padding(horizontal = 20.dp), color = MaterialTheme.colorScheme.outlineVariant)
                ConfigSwitchRow(
                    titulo = "Alto contraste",
                    descricao = "Maximiza o contraste de textos e superfícies",
                    icone = AppIcons.AltoContraste,
                    checked = state.altoContraste,
                    onCheckedChange = { viewModel.alternarAltoContraste(it) }
                )
                Divider(Modifier.padding(horizontal = 20.dp), color = MaterialTheme.colorScheme.outlineVariant)
                ConfigSwitchRow(
                    titulo = "Texto em negrito",
                    descricao = "Engrossa todos os textos do app",
                    icone = AppIcons.TextoNegrito,
                    checked = state.textoNegrito,
                    onCheckedChange = { viewModel.alternarTextoNegrito(it) }
                )
                Divider(Modifier.padding(horizontal = 20.dp), color = MaterialTheme.colorScheme.outlineVariant)
                ConfigSwitchRow(
                    titulo = "Animações reduzidas",
                    descricao = "Diminui transições e movimentos na tela",
                    icone = AppIcons.AnimacoesReduzidas,
                    checked = state.animacoesReduzidas,
                    onCheckedChange = { viewModel.alternarAnimacoesReduzidas(it) }
                )
                Divider(Modifier.padding(horizontal = 20.dp), color = MaterialTheme.colorScheme.outlineVariant)
                ConfigSwitchRow(
                    titulo = "Modo leitor de tela",
                    descricao = "Amplia descrições para leitores de tela",
                    icone = AppIcons.LeitorDeTela,
                    checked = state.modoLeitorTela,
                    onCheckedChange = { viewModel.alternarModoLeitorTela(it) }
                )
                Divider(Modifier.padding(horizontal = 20.dp), color = MaterialTheme.colorScheme.outlineVariant)
                ControleTamanhoFonte(
                    tamanhoSelecionado = state.tamanhoFonte,
                    onSelecionar = { viewModel.definirTamanhoFonte(it) }
                )
            }
        }

        SecaoTitulo("Sobre")
        Card(Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp), elevation = CardDefaults.cardElevation(2.dp)) {
            Column(Modifier.padding(20.dp)) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) { Text("Versão", style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurface); Text(VERSAO_APP, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant) }
                Spacer(Modifier.height(12.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) { Text("Desenvolvido por", style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurface); Text("UFLA/DEG", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant) }
                Spacer(Modifier.height(12.dp))
                Text("Modelos: Kostiakov-Lewis + Balanço de Volume", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(Modifier.height(12.dp))
                Row(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp)).clickable { uriHandler.openUri(URL_CHANGELOG) }.padding(vertical = 4.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(AppIcons.AbrirChangelog, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(18.dp))
                    Text("Novidades da versão $VERSAO_APP", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
                }
            }
        }

        Spacer(Modifier.height(8.dp))
        OutlinedButton(onLogout, Modifier.fillMaxWidth().height(54.dp), shape = RoundedCornerShape(12.dp), border = BorderStroke(1.dp, MaterialTheme.colorScheme.error)) {
            Text("Sair da conta", color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.titleMedium)
        }
        Spacer(Modifier.height(16.dp))
    }
}

/**
 * Avatar circular do usuário. Exibe a foto quando há suporte a carregamento
 * de imagens; caso contrário (ou sem foto cadastrada), usa as iniciais do nome.
 */
@Composable
private fun AvatarUsuario(fotoUrl: String?, nome: String, tamanho: Dp, modifier: Modifier = Modifier) {
    val descricao = if (fotoUrl.isNullOrBlank()) {
        "Foto de perfil com as iniciais de $nome"
    } else {
        "Foto de perfil de $nome"
    }
    Box(
        modifier
            .size(tamanho)
            .clip(CircleShape)
            .background(MaterialTheme.colorScheme.primaryContainer)
            .semantics { contentDescription = descricao },
        contentAlignment = Alignment.Center
    ) {
        IniciaisUsuario(nome)
    }
}

@Composable
private fun IniciaisUsuario(nome: String) {
    val iniciais = nome.trim()
        .split(" ")
        .filter { it.isNotBlank() }
        .take(2)
        .mapNotNull { it.firstOrNull()?.uppercaseChar() }
        .joinToString("")
        .ifEmpty { "?" }
    Text(iniciais, style = MaterialTheme.typography.headlineLarge, color = MaterialTheme.colorScheme.primary)
}

@Composable
private fun CartaoEstatistica(valor: String, rotulo: String, icone: ImageVector, modifier: Modifier = Modifier) {
    Card(modifier, shape = RoundedCornerShape(12.dp), colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))) {
        Column(Modifier.fillMaxWidth().padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Box(
                Modifier.size(40.dp).clip(CircleShape).background(MaterialTheme.colorScheme.primaryContainer),
                contentAlignment = Alignment.Center
            ) {
                Icon(icone, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(22.dp))
            }
            Spacer(Modifier.height(8.dp))
            Text(valor, style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.onSurface, maxLines = 1)
            Text(rotulo, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1)
        }
    }
}

@Composable
private fun SecaoTitulo(texto: String) {
    Text(texto, style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.onBackground, modifier = Modifier.padding(top = 8.dp))
}

@Composable
private fun ConfigSwitchRow(
    titulo: String,
    descricao: String,
    icone: ImageVector,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icone, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
        Column(Modifier.weight(1f)) {
            Text(titulo, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
            Text(descricao, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Switch(checked, onCheckedChange)
    }
}

@Composable
private fun ControleTamanhoFonte(tamanhoSelecionado: TamanhoFonte, onSelecionar: (TamanhoFonte) -> Unit) {
    val opcoes = TamanhoFonte.entries
    Column(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 14.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(AppIcons.TamanhoFonte, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
            Column {
                Text("Tamanho da fonte", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
                Text("Ajusta o texto em todo o app", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        Slider(
            value = tamanhoSelecionado.ordinal.toFloat(),
            onValueChange = { progresso ->
                val indice = progresso.toInt().coerceIn(0, opcoes.lastIndex)
                onSelecionar(opcoes[indice])
            },
            valueRange = 0f..opcoes.lastIndex.toFloat(),
            steps = opcoes.size - 2
        )
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            opcoes.forEach { opcao ->
                val ativo = opcao == tamanhoSelecionado
                Text(
                    opcao.label,
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = if (ativo) FontWeight.Bold else FontWeight.Normal,
                    color = if (ativo) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

private fun iconeMetodo(metodo: MetodoIrrigacao?): ImageVector = when (metodo) {
    MetodoIrrigacao.SULCO -> AppIcons.Sulco
    MetodoIrrigacao.FAIXA -> AppIcons.Faixa
    MetodoIrrigacao.INUNDACAO -> AppIcons.Inundacao
    null -> AppIcons.Estatisticas
}
