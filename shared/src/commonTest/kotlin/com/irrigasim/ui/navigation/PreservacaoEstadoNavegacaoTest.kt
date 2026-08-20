package com.irrigasim.ui.navigation

import com.irrigasim.domain.CenarioSalvo
import com.irrigasim.domain.MetodoIrrigacao
import com.irrigasim.domain.Parametros
import com.irrigasim.domain.Resultado
import com.irrigasim.ui.viewmodel.HistoricoViewModel
import com.irrigasim.ui.viewmodel.SimulacaoViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Os ViewModels vivem no escopo do app (App.kt), enquanto a navegação troca de
 * rota/aba. Estes testes verificam o contrato central da issue: o estado dos
 * ViewModels sobrevive a navegar para sub-telas, voltar e trocar de abas —
 * exatamente como os fluxos reais são costurados em App.kt.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class PreservacaoEstadoNavegacaoTest {

    private fun resultadoPadrao(eficiencia: Double = 80.0) = Resultado(
        eficiencia = eficiencia,
        laminaMedia = 50.0,
        tempoAvanco = 40.0,
        perdaPercolacao = 6.0,
        perdaEscoamento = 4.0
    )

    @Test
    fun metodoSelecionadoSobreviveaNavegarParaParametrosEVoltar() = runTest {
        val simulacaoVm = SimulacaoViewModel(scope = backgroundScope)
        val nav = AppNavigationState(ScreenRoute.Simulacao)

        // Usuário escolhe faixa na aba Simulação; o app abre a tela de parâmetros
        simulacaoVm.selecionarMetodo(MetodoIrrigacao.FAIXA)
        nav.navigate(ScreenRoute.Parametros)
        assertEquals(ScreenRoute.Parametros, nav.currentRoute)

        // Voltar para a raiz: a escolha do método permanece
        assertTrue(nav.goBack())
        assertEquals(ScreenRoute.Simulacao, nav.currentRoute)
        assertEquals(MetodoIrrigacao.FAIXA, simulacaoVm.state.value.metodo)
    }

    @Test
    fun resultadoDaSimulacaoSobreviveAoFluxoDeResultadosComVolta() = runTest {
        val simulacaoVm = SimulacaoViewModel(scope = backgroundScope)
        val nav = AppNavigationState(ScreenRoute.Simulacao)

        // Mesma sequência de executarSimulacaoSegura em App.kt
        val parametros = Parametros(comprimento = 120.0, vazao = 0.8)
        val resultado = simulacaoVm.executarSimulacao(MetodoIrrigacao.FAIXA, parametros)
        nav.resetTo(ScreenRoute.Simulacao)
        nav.navigate(ScreenRoute.Resultados)
        assertEquals(ScreenRoute.Resultados, nav.currentRoute)

        // Usuário volta dos resultados: método, parâmetros e resultado preservados
        assertTrue(nav.goBack())
        assertEquals(ScreenRoute.Simulacao, nav.currentRoute)
        assertEquals(resultado, simulacaoVm.state.value.resultado)
        assertEquals(parametros, simulacaoVm.state.value.parametros)
    }

    @Test
    fun cenarioAbertoPermaneceCarregadoAposTrocarDeAbaEFecharResultados() = runTest {
        val simulacaoVm = SimulacaoViewModel(scope = backgroundScope)
        val historicoVm = HistoricoViewModel(scope = backgroundScope)
        val nav = AppNavigationState(ScreenRoute.Simulacao)

        // Cenário salvo é aberto a partir da aba Cenarios (abrirCenarioSalvo em App.kt)
        val salvo = CenarioSalvo(
            id = "cenario_1_150",
            titulo = "Faixa 150m",
            dataHora = "Hoje",
            metodo = MetodoIrrigacao.FAIXA,
            parametros = Parametros(comprimento = 150.0),
            resultado = resultadoPadrao(eficiencia = 72.0)
        )
        historicoVm.salvarCenario(salvo.titulo, salvo.metodo, salvo.parametros, salvo.resultado)
        simulacaoVm.abrirCenario(salvo)
        nav.selectTab(1)
        nav.navigate(ScreenRoute.Resultados)

        // Usuário desiste: volta para a raiz e passeia pelas outras abas
        assertTrue(nav.goBack())
        nav.selectTab(2)
        nav.selectTab(0)

        // O cenário continua no histórico e carregado no contexto de simulação
        assertEquals(1, historicoVm.state.value.cenarios.size)
        assertEquals(salvo.metodo, simulacaoVm.state.value.metodo)
        assertEquals(salvo.parametros, simulacaoVm.state.value.parametros)
        assertEquals(salvo.resultado, simulacaoVm.state.value.resultado)
    }

    @Test
    fun exclusaoDeCenarioSobreviveATrocasDeAbaENavegacaoParaResultados() = runTest {
        val historicoVm = HistoricoViewModel(scope = backgroundScope)
        val simulacaoVm = SimulacaoViewModel(scope = backgroundScope)
        val nav = AppNavigationState(ScreenRoute.Simulacao)

        val a = historicoVm.salvarCenario("A", MetodoIrrigacao.SULCO, Parametros(comprimento = 100.0), resultadoPadrao())
        val b = historicoVm.salvarCenario("B", MetodoIrrigacao.INUNDACAO, Parametros(comprimento = 60.0), resultadoPadrao())

        // Exclusão acontece na aba Cenarios; depois o usuário abre resultados de B
        historicoVm.excluirCenario(a.id)
        simulacaoVm.abrirCenario(b)
        nav.selectTab(1)
        nav.navigate(ScreenRoute.Resultados)
        nav.goBack()
        nav.selectTab(2)

        assertEquals(listOf(b), historicoVm.state.value.cenarios)
        assertEquals(b.resultado, simulacaoVm.state.value.resultado)
    }

    @Test
    fun conclusaoDoPrimeiroAcessoPersisteAposQualquerNavegacao() = runTest {
        val simulacaoVm = SimulacaoViewModel(scope = backgroundScope)
        // Primeiro acesso inicia direto no wizard (App.kt)
        val nav = AppNavigationState(ScreenRoute.Wizard)
        assertEquals(ScreenRoute.Wizard, nav.currentRoute)

        // Usuário conclui o tutorial e navega livremente pelo app
        simulacaoVm.concluirPrimeiroAcesso()
        nav.resetTo(ScreenRoute.Simulacao)
        nav.selectTab(1)
        nav.navigate(ScreenRoute.Parametros)
        nav.goBack()
        nav.onPagerSettled(0)

        assertFalse(simulacaoVm.state.value.primeiroAcesso)
    }
}
