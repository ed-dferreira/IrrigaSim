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
import com.irrigasim.ui.screens.HistoricoScreen
import com.irrigasim.ui.screens.MetodoScreen
import com.irrigasim.ui.screens.ParametrosScreen
import com.irrigasim.ui.screens.PerfilScreen
import com.irrigasim.ui.screens.ResultadoScreen
import com.irrigasim.ui.screens.WizardSimulacaoScreen
import com.irrigasim.ui.screens.auth.CadastroScreen
import com.irrigasim.ui.screens.auth.LoginScreen
import com.irrigasim.ui.theme.AppIcons
import com.irrigasim.ui.theme.IrrigaSIMTheme
import com.irrigasim.ui.theme.acessibilidade
import com.irrigasim.ui.viewmodel.HistoricoViewModel
import com.irrigasim.ui.viewmodel.PerfilViewModel
import com.irrigasim.ui.viewmodel.SimulacaoViewModel
import com.irrigasim.ui.viewmodel.rememberViewModel
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
    // ViewModels do escopo do app (provedor manual, sem DI)
    val simulacaoVm = rememberViewModel { SimulacaoViewModel() }
    val historicoVm = rememberViewModel { HistoricoViewModel() }
    val perfilVm = rememberViewModel { PerfilViewModel(usuario = currentUser) }

    val simulacao by simulacaoVm.state.collectAsState()
    val historico by historicoVm.state.collectAsState()
    val perfil by perfilVm.state.collectAsState()

    IrrigaSIMTheme(
        darkTheme = perfil.temaEscuro,
        fontScale = perfil.tamanhoFonte.escala,
        highContrast = perfil.altoContraste,
        boldText = perfil.textoNegrito,
        reducedAnimations = perfil.animacoesReduzidas,
        screenReaderMode = perfil.modoLeitorTela
    ) {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = MaterialTheme.colorScheme.background
        ) {
            val navState = rememberAppNavigationState(
                initialRoute = if (currentUser != null) {
                    if (simulacao.primeiroAcesso) ScreenRoute.Wizard else ScreenRoute.Simulacao
                } else {
                    ScreenRoute.Login
                }
            )
            val scope = rememberCoroutineScope()
            val pagerState = rememberPagerState(
                initialPage = navState.selectedTab,
                pageCount = { ScreenRoute.TAB_ROOTS.size }
            )

            LaunchedEffect(currentUser) {
                if (currentUser != null) {
                    navState.resetTo(if (simulacao.primeiroAcesso) ScreenRoute.Wizard else ScreenRoute.Simulacao)
                } else {
                    navState.resetTo(ScreenRoute.Login)
                }
            }

            // Estatísticas do perfil acompanham os cenários salvos
            LaunchedEffect(historico.cenarios) {
                perfilVm.atualizarEstatisticas(historico.cenarios)
            }

            // Sincroniza o pager com a bottom bar: swipe concluído atualiza a aba selecionada
            LaunchedEffect(pagerState) {
                snapshotFlow { pagerState.settledPage }.collect { page ->
                    navState.onPagerSettled(page)
                }
            }

            val acessibilidadeConfig = acessibilidade()

            fun navegarParaAba(index: Int) {
                navState.selectTab(index)
                scope.launch {
                    if (acessibilidadeConfig.animacoesReduzidas) {
                        pagerState.scrollToPage(index)
                    } else {
                        pagerState.animateScrollToPage(index)
                    }
                }
            }

            // Executa a simulação e navega para a tela de resultados
            fun executarSimulacaoSegura(m: MetodoIrrigacao, p: Parametros) {
                simulacaoVm.executarSimulacao(m, p)
                navState.resetTo(ScreenRoute.Simulacao)
                navState.navigate(ScreenRoute.Resultados)
            }

            fun abrirCenarioSalvo(cenario: CenarioSalvo) {
                simulacaoVm.abrirCenario(cenario)
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
                                    onClick = { navegarParaAba(index) },
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
                                        simulacaoVm.selecionarMetodo(m)
                                        navState.navigate(ScreenRoute.Parametros)
                                    },
                                    onAbrirTutorial = { navState.navigate(ScreenRoute.Wizard) }
                                )
                                ScreenRoute.Cenarios -> HistoricoScreen(
                                    cenarios = historico.cenarios,
                                    onVisualizarCenario = { abrirCenarioSalvo(it) },
                                    onExcluirCenario = { id -> historicoVm.excluirCenario(id) },
                                    onNovoCenario = { navegarParaAba(0) }
                                )
                                ScreenRoute.Perfil -> PerfilScreen(
                                    viewModel = perfilVm,
                                    usuario = currentUser,
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
                                        metodoInicial = simulacao.metodo,
                                        onSimular = { m, p ->
                                            simulacaoVm.concluirPrimeiroAcesso()
                                            executarSimulacaoSegura(m, p)
                                        },
                                        onIrParaModoDireto = {
                                            simulacaoVm.concluirPrimeiroAcesso()
                                            navState.resetTo(ScreenRoute.Simulacao)
                                        }
                                    )
                                    ScreenRoute.Parametros -> ParametrosScreen(
                                        metodo = simulacao.metodo,
                                        onSimular = { p ->
                                            executarSimulacaoSegura(simulacao.metodo, p)
                                        },
                                        onVoltar = { navState.goBack() }
                                    )
                                    ScreenRoute.Resultados -> ResultadoScreen(
                                        resultado = simulacao.resultado ?: Resultado(
                                            eficiencia = 0.0,
                                            laminaMedia = 0.0,
                                            tempoAvanco = 0.0,
                                            perdaPercolacao = 0.0,
                                            perdaEscoamento = 0.0
                                        ),
                                        metodo = simulacao.metodo,
                                        parametros = simulacao.parametros,
                                        onVoltar = { navState.goBack() },
                                        onSalvarCenario = { titulo ->
                                            historicoVm.salvarCenario(
                                                titulo = titulo,
                                                metodo = simulacao.metodo,
                                                parametros = simulacao.parametros,
                                                resultado = simulacao.resultado
                                                    ?: Resultado(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
                                            )
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
