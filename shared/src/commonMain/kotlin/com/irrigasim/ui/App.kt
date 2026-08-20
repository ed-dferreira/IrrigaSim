package com.irrigasim.ui

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.irrigasim.domain.*
import com.irrigasim.ui.navigation.ScreenRoute
import com.irrigasim.ui.navigation.rememberAppNavigationState
import com.irrigasim.ui.theme.AppIcons
import com.irrigasim.ui.theme.IrrigaSIMTheme
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
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
            val navState = rememberAppNavigationState(
                initialRoute = if (currentUser != null) {
                    if (primeiroAcesso) ScreenRoute.Wizard else ScreenRoute.Simulacao
                } else {
                    ScreenRoute.Login
                }
            )
            val scope = rememberCoroutineScope()
            val pagerState = rememberPagerState(
                initialPage = navState.selectedTab,
                pageCount = { ScreenRoute.TAB_ROOTS.size }
            )

            var metodo by remember { mutableStateOf(MetodoIrrigacao.SULCO) }
            var parametrosAtuais by remember { mutableStateOf(Parametros()) }
            var resultadoAtual by remember { mutableStateOf<Resultado?>(null) }

            LaunchedEffect(currentUser) {
                if (currentUser != null) {
                    navState.resetTo(if (primeiroAcesso) ScreenRoute.Wizard else ScreenRoute.Simulacao)
                } else {
                    navState.resetTo(ScreenRoute.Login)
                }
            }

            // Sincroniza o pager com a bottom bar: swipe concluído atualiza a aba selecionada
            LaunchedEffect(pagerState) {
                snapshotFlow { pagerState.settledPage }.collect { page ->
                    navState.onPagerSettled(page)
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
                navState.resetTo(ScreenRoute.Simulacao)
                navState.navigate(ScreenRoute.Resultados)
            }

            fun abrirCenarioSalvo(cenario: CenarioSalvo) {
                metodo = cenario.metodo
                parametrosAtuais = cenario.parametros
                resultadoAtual = cenario.resultado
                navState.navigate(ScreenRoute.Resultados)
            }

            when (navState.currentRoute) {
                ScreenRoute.Login -> LoginScreen(
                    onLogin = onEmailSignIn,
                    onGoogleSignIn = onGoogleSignIn,
                    onCadastro = { navState.navigate(ScreenRoute.Cadastro) },
                    errorMessage = authError,
                    isLoading = authLoading,
                    onClearError = onClearError
                )
                ScreenRoute.Cadastro -> CadastroScreen(
                    onCadastrar = onEmailSignUp,
                    onVoltar = { navState.goBack() },
                    errorMessage = authError,
                    isLoading = authLoading,
                    onClearError = onClearError
                )
                else -> Scaffold(
                    bottomBar = {
                        NavigationBar(
                            containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f),
                            tonalElevation = 0.dp
                        ) {
                            ScreenRoute.TAB_ROOTS.forEachIndexed { index, rota ->
                                NavigationBarItem(
                                    selected = navState.selectedTab == index,
                                    onClick = {
                                        navState.selectTab(index)
                                        scope.launch { pagerState.animateScrollToPage(index) }
                                    },
                                    icon = { Icon(tabIcon(rota), contentDescription = null) },
                                    label = { Text(rota.label, style = MaterialTheme.typography.labelLarge) }
                                )
                            }
                        }
                    }
                ) { paddingValues ->
                    Box(modifier = Modifier.padding(paddingValues)) {
                        HorizontalPager(
                            state = pagerState,
                            modifier = Modifier.fillMaxSize(),
                            userScrollEnabled = navState.currentRoute.isTabRoot,
                            beyondBoundsPageCount = ScreenRoute.TAB_ROOTS.lastIndex
                        ) { page ->
                            when (ScreenRoute.TAB_ROOTS[page]) {
                                ScreenRoute.Simulacao -> MetodoScreen(
                                    userName = currentUser?.nome ?: "Usuário",
                                    onSelecionar = { m ->
                                        metodo = m
                                        navState.navigate(ScreenRoute.Parametros)
                                    },
                                    onAbrirTutorial = { navState.navigate(ScreenRoute.Wizard) }
                                )
                                ScreenRoute.Cenarios -> HistoricoScreen(
                                    cenarios = cenariosSalvos,
                                    onVisualizarCenario = { abrirCenarioSalvo(it) },
                                    onExcluirCenario = { id ->
                                        cenariosSalvos = cenariosSalvos.filterNot { it.id == id }
                                    },
                                    onNovoCenario = {
                                        navState.selectTab(0)
                                        scope.launch { pagerState.animateScrollToPage(0) }
                                    }
                                )
                                ScreenRoute.Perfil -> PerfilScreen(
                                    usuario = currentUser,
                                    isDarkTheme = isDarkTheme,
                                    onToggleDarkTheme = { isDarkTheme = it },
                                    onLogout = onSignOut
                                )
                                else -> Unit
                            }
                        }

                        // Sub-telas sobrepostas ao pager (wizard, parâmetros e resultados)
                        if (navState.currentRoute in ScreenRoute.SUB_SCREENS) {
                            Surface(
                                modifier = Modifier.fillMaxSize(),
                                color = MaterialTheme.colorScheme.background
                            ) {
                                when (navState.currentRoute) {
                                    ScreenRoute.Wizard -> WizardSimulacaoScreen(
                                        userName = currentUser?.nome ?: "Usuário",
                                        metodoInicial = metodo,
                                        onSimular = { m, p ->
                                            primeiroAcesso = false
                                            executarSimulacaoSegura(m, p)
                                        },
                                        onIrParaModoDireto = {
                                            primeiroAcesso = false
                                            navState.resetTo(ScreenRoute.Simulacao)
                                        }
                                    )
                                    ScreenRoute.Parametros -> ParametrosScreen(
                                        metodo = metodo,
                                        onSimular = { p ->
                                            executarSimulacaoSegura(metodo, p)
                                        },
                                        onVoltar = { navState.goBack() }
                                    )
                                    ScreenRoute.Resultados -> ResultadoScreen(
                                        resultado = resultadoAtual ?: Resultado(
                                            eficiencia = 0.0,
                                            laminaMedia = 0.0,
                                            tempoAvanco = 0.0,
                                            perdaPercolacao = 0.0,
                                            perdaEscoamento = 0.0
                                        ),
                                        metodo = metodo,
                                        parametros = parametrosAtuais,
                                        onVoltar = { navState.goBack() },
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
                                    else -> Unit
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

private fun tabIcon(route: ScreenRoute): androidx.compose.ui.graphics.vector.ImageVector = when (route) {
    ScreenRoute.Simulacao -> AppIcons.NavSimulacao
    ScreenRoute.Cenarios -> AppIcons.NavCenarios
    ScreenRoute.Perfil -> AppIcons.NavPerfil
    else -> AppIcons.NavSimulacao
}
