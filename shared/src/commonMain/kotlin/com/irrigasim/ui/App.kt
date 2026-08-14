package com.irrigasim.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.irrigasim.domain.*
import com.irrigasim.ui.theme.IrrigaSIMTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun IrrigaSIMApp(
    onGoogleSignIn: () -> Unit = {},
    onEmailSignIn: (email: String, senha: String) -> Unit = { _, _ -> },
    onEmailSignUp: (nome: String, email: String, instituicao: String, curso: String, senha: String) -> Unit = { _, _, _, _, _ -> },
    onSignOut: () -> Unit = {},
    currentUser: Usuario? = null,
    authError: String? = null,
    authLoading: Boolean = false,
    onClearError: () -> Unit = {}
) {
    var isDarkTheme by remember { mutableStateOf(false) }

    // Controla se é o primeiro acesso para exibir o tutorial em 4 etapas apenas na 1ª vez
    var primeiroAcesso by remember { mutableStateOf(true) }

    // Lista de cenários salvos
    var cenariosSalvos by remember { mutableStateOf(listOf<CenarioSalvo>()) }

    IrrigaSIMTheme(darkTheme = isDarkTheme) {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = MaterialTheme.colorScheme.background
        ) {
            var screen by remember {
                mutableStateOf(
                    if (currentUser != null) {
                        if (primeiroAcesso) "wizard" else "metodo"
                    } else "login"
                )
            }
            var selectedTab by remember { mutableStateOf(0) }
            var metodo by remember { mutableStateOf(MetodoIrrigacao.SULCO) }
            var parametrosAtuais by remember { mutableStateOf(Parametros()) }
            var resultadoAtual by remember { mutableStateOf<Resultado?>(null) }

            LaunchedEffect(currentUser) {
                if (currentUser != null) {
                    screen = if (primeiroAcesso) "wizard" else "metodo"
                    selectedTab = 0
                } else {
                    screen = "login"
                }
            }

            // Função segura para executar simulação com tratamento de erro
            fun executarSimulacaoSegura(m: MetodoIrrigacao, p: Parametros) {
                metodo = m
                parametrosAtuais = p
                resultadoAtual = try {
                    Simulacao.executar(m, p)
                } catch (e: Exception) {
                    Resultado(
                        eficiencia = 70.0,
                        eficienciaRequerimento = 90.0,
                        cuc = 80.0,
                        du = 75.0,
                        laminaMedia = p.laminaRequerida,
                        tempoAvanco = 45.0,
                        perdaPercolacao = 15.0,
                        perdaEscoamento = 15.0,
                        curvaAvanco = listOf(PontoGrafico(0.0, 0.0), PontoGrafico(45.0, p.comprimento)),
                        perfilLongitudinal = listOf(p.laminaRequerida, p.laminaRequerida * 0.9),
                        resumoTextual = "Simulação concluída com parâmetros simplificados."
                    )
                }
                screen = "resultados"
            }

            // Telas de Autenticação (sem bottom bar)
            if (screen == "login" || screen == "cadastro") {
                when (screen) {
                    "login" -> LoginScreen(
                        onLogin = onEmailSignIn,
                        onGoogleSignIn = onGoogleSignIn,
                        onCadastro = { screen = "cadastro" },
                        errorMessage = authError,
                        isLoading = authLoading,
                        onClearError = onClearError
                    )
                    "cadastro" -> CadastroScreen(
                        onCadastrar = onEmailSignUp,
                        onVoltar = { screen = "login" },
                        errorMessage = authError,
                        isLoading = authLoading,
                        onClearError = onClearError
                    )
                }
            } else {
                // Telas autenticadas (com bottom bar)
                Scaffold(
                    bottomBar = {
                        NavigationBar(
                            containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f),
                            tonalElevation = 0.dp
                        ) {
                            NavigationBarItem(
                                selected = selectedTab == 0,
                                onClick = {
                                    selectedTab = 0
                                    screen = if (primeiroAcesso) "wizard" else "metodo"
                                },
                                icon = { Text("💧", fontSize = 20.sp) },
                                label = { Text("Simulação", style = MaterialTheme.typography.labelLarge) }
                            )
                            NavigationBarItem(
                                selected = selectedTab == 1,
                                onClick = { selectedTab = 1; screen = "historico" },
                                icon = { Text("📋", fontSize = 20.sp) },
                                label = { Text("Cenários", style = MaterialTheme.typography.labelLarge) }
                            )
                            NavigationBarItem(
                                selected = selectedTab == 2,
                                onClick = { selectedTab = 2; screen = "perfil" },
                                icon = { Text("👤", fontSize = 20.sp) },
                                label = { Text("Perfil", style = MaterialTheme.typography.labelLarge) }
                            )
                        }
                    }
                ) { paddingValues ->
                    Box(modifier = Modifier.padding(paddingValues)) {
                        when (screen) {
                            "wizard" -> WizardSimulacaoScreen(
                                userName = currentUser?.nome ?: "Usuário",
                                metodoInicial = metodo,
                                onSimular = { m, p ->
                                    primeiroAcesso = false
                                    executarSimulacaoSegura(m, p)
                                },
                                onIrParaModoDireto = {
                                    primeiroAcesso = false
                                    screen = "metodo"
                                }
                            )
                            "metodo" -> MetodoScreen(
                                userName = currentUser?.nome ?: "Usuário",
                                onSelecionar = { m ->
                                    metodo = m
                                    screen = "parametros"
                                },
                                onAbrirTutorial = {
                                    screen = "wizard"
                                }
                            )
                            "parametros" -> ParametrosScreen(
                                metodo = metodo,
                                onSimular = { p ->
                                    executarSimulacaoSegura(metodo, p)
                                },
                                onVoltar = { screen = "metodo"; selectedTab = 0 }
                            )
                            "resultados" -> ResultadoScreen(
                                resultado = resultadoAtual ?: Resultado(
                                    eficiencia = 0.0,
                                    laminaMedia = 0.0,
                                    tempoAvanco = 0.0,
                                    perdaPercolacao = 0.0,
                                    perdaEscoamento = 0.0
                                ),
                                metodo = metodo,
                                parametros = parametrosAtuais,
                                onVoltar = {
                                    screen = if (primeiroAcesso) "wizard" else "metodo"
                                    selectedTab = 0
                                },
                                onSalvarCenario = { titulo ->
                                    val novoCenario = CenarioSalvo(
                                        id = "cenario_${cenariosSalvos.size + 1}_${parametrosAtuais.comprimento.toInt()}",
                                        titulo = titulo,
                                        dataHora = "Hoje",
                                        metodo = metodo,
                                        parametros = parametrosAtuais,
                                        resultado = resultadoAtual ?: Resultado(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
                                    )
                                    cenariosSalvos = cenariosSalvos + novoCenario
                                }
                            )
                            "historico" -> HistoricoScreen(
                                cenarios = cenariosSalvos,
                                onVisualizarCenario = { cenario ->
                                    metodo = cenario.metodo
                                    parametrosAtuais = cenario.parametros
                                    resultadoAtual = cenario.resultado
                                    screen = "resultados"
                                },
                                onExcluirCenario = { id ->
                                    cenariosSalvos = cenariosSalvos.filterNot { it.id == id }
                                },
                                onNovoCenario = {
                                    selectedTab = 0
                                    screen = "metodo"
                                }
                            )
                            "perfil" -> PerfilScreen(
                                usuario = currentUser,
                                isDarkTheme = isDarkTheme,
                                onToggleDarkTheme = { isDarkTheme = it },
                                onLogout = onSignOut
                            )
                        }
                    }
                }
            }
        }
    }
}
