package com.irrigasim.ui.navigation

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class AppNavigationStateTest {

    private fun novoEstado() = AppNavigationState(ScreenRoute.Simulacao)

    @Test
    fun rotasDeAbasMapeiamParaIndiceCorreto() {
        assertEquals(0, ScreenRoute.Simulacao.tabIndex)
        assertEquals(1, ScreenRoute.Cenarios.tabIndex)
        assertEquals(2, ScreenRoute.Perfil.tabIndex)
        assertNull(ScreenRoute.Parametros.tabIndex)
        assertNull(ScreenRoute.Wizard.tabIndex)
        assertNull(ScreenRoute.Resultados.tabIndex)
        assertNull(ScreenRoute.Login.tabIndex)
    }

    @Test
    fun fromIdResolveTodasAsRotas() {
        ScreenRoute.TAB_ROOTS + ScreenRoute.SUB_SCREENS + listOf(ScreenRoute.Login, ScreenRoute.Cadastro)
            .forEach { rota ->
                assertEquals(rota, ScreenRoute.fromId(rota.id), "Falha ao resolver rota ${rota.id}")
            }
        assertNull(ScreenRoute.fromId("rota_inexistente"))
    }

    @Test
    fun selecaoDeAbaSincronizaRotaAtual() {
        val nav = novoEstado()

        nav.selectTab(1)
        assertEquals(ScreenRoute.Cenarios, nav.currentRoute)
        assertEquals(1, nav.selectedTab)

        nav.selectTab(2)
        assertEquals(ScreenRoute.Perfil, nav.currentRoute)
        assertEquals(2, nav.selectedTab)

        nav.selectTab(0)
        assertEquals(ScreenRoute.Simulacao, nav.currentRoute)
        assertEquals(0, nav.selectedTab)
    }

    @Test
    fun selecaoDeAbaForaDoIntervaloEhCoercida() {
        val nav = novoEstado()
        nav.selectTab(7)
        assertEquals(ScreenRoute.Perfil, nav.currentRoute)
        assertEquals(2, nav.selectedTab)
        nav.selectTab(-1)
        assertEquals(ScreenRoute.Simulacao, nav.currentRoute)
        assertEquals(0, nav.selectedTab)
    }

    @Test
    fun voltarDeSubTelaRetornaParaAbaDeOrigem() {
        val nav = novoEstado()

        nav.selectTab(1)
        nav.navigate(ScreenRoute.Resultados)
        assertEquals(ScreenRoute.Resultados, nav.currentRoute)

        assertTrue(nav.goBack())
        assertEquals(ScreenRoute.Cenarios, nav.currentRoute)
        assertEquals(1, nav.selectedTab)
    }

    @Test
    fun fluxoDeSimulacaoVoltaParaRaizDaAbaSimulacao() {
        val nav = novoEstado()

        nav.navigate(ScreenRoute.Parametros)
        assertEquals(ScreenRoute.Parametros, nav.currentRoute)

        nav.resetTo(ScreenRoute.Simulacao)
        nav.navigate(ScreenRoute.Resultados)
        assertTrue(nav.goBack())

        assertEquals(ScreenRoute.Simulacao, nav.currentRoute)
        assertEquals(0, nav.selectedTab)
        assertFalse(nav.canGoBack)
    }

    @Test
    fun wizardIniciaSobreAbaSimulacaoSemPilha() {
        val nav = AppNavigationState(ScreenRoute.Wizard)

        assertEquals(ScreenRoute.Wizard, nav.currentRoute)
        assertEquals(0, nav.selectedTab)
        assertFalse(nav.canGoBack)
    }

    @Test
    fun swipeEntreAbasIgnoradoComSubTelaAtivaELimpaPilhaAoVoltarParaRaiz() {
        val nav = novoEstado()

        nav.navigate(ScreenRoute.Parametros)
        nav.onPagerSettled(2)
        assertEquals(ScreenRoute.Parametros, nav.currentRoute)
        assertEquals(0, nav.selectedTab)

        assertTrue(nav.goBack())
        nav.onPagerSettled(2)
        assertEquals(ScreenRoute.Perfil, nav.currentRoute)
        assertEquals(2, nav.selectedTab)
        assertFalse(nav.canGoBack)
    }

    @Test
    fun voltarEmPilhaVaziaNaoAlteraEstado() {
        val nav = novoEstado()

        assertFalse(nav.goBack())
        assertEquals(ScreenRoute.Simulacao, nav.currentRoute)
        assertEquals(0, nav.selectedTab)
    }

    @Test
    fun navegarParaMesmaRotaNaoDuplicaPilha() {
        val nav = novoEstado()

        nav.navigate(ScreenRoute.Parametros)
        nav.navigate(ScreenRoute.Parametros)

        assertTrue(nav.goBack())
        assertEquals(ScreenRoute.Simulacao, nav.currentRoute)
        assertFalse(nav.canGoBack)
    }

    @Test
    fun voltarDoCadastroRetornaParaLogin() {
        val nav = AppNavigationState(ScreenRoute.Login)

        nav.navigate(ScreenRoute.Cadastro)
        assertEquals(ScreenRoute.Cadastro, nav.currentRoute)
        assertTrue(nav.canGoBack)

        assertTrue(nav.goBack())
        assertEquals(ScreenRoute.Login, nav.currentRoute)
        assertEquals(0, nav.selectedTab)
        assertFalse(nav.canGoBack)
    }

    @Test
    fun voltarDeSubTelaAbertaPorOutraSubTelaVoltaParaPrimeira() {
        val nav = novoEstado()

        nav.navigate(ScreenRoute.Wizard)
        nav.navigate(ScreenRoute.Parametros)

        assertTrue(nav.goBack())
        assertEquals(ScreenRoute.Wizard, nav.currentRoute)
        assertTrue(nav.canGoBack)

        assertTrue(nav.goBack())
        assertEquals(ScreenRoute.Simulacao, nav.currentRoute)
        assertFalse(nav.canGoBack)
    }

    @Test
    fun selecaoDeAbaComSubTelaAbertaLimpaPilhaEVoltaParaRaizCorreta() {
        val nav = novoEstado()

        nav.selectTab(1)
        nav.navigate(ScreenRoute.Resultados)
        assertTrue(nav.canGoBack)

        // Usuário toca em outra aba da bottom bar com sub-tela aberta
        nav.selectTab(2)
        assertEquals(ScreenRoute.Perfil, nav.currentRoute)
        assertEquals(2, nav.selectedTab)
        assertFalse(nav.canGoBack)
    }
}
