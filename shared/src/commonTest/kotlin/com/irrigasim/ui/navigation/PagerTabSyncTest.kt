package com.irrigasim.ui.navigation

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Contrato entre o [androidx.compose.foundation.pager.HorizontalPager] e o
 * [AppNavigationState], conforme a fiação em App.kt:
 *
 * 1. swipe concluído (`settledPage`) -> `onPagerSettled(page)` atualiza a aba;
 * 2. `userScrollEnabled` só é verdadeiro em raízes de aba (`isTabRoot`);
 * 3. mudanças programáticas de `selectedTab` (voltar, deep link) reposicionam o pager.
 */
class PagerTabSyncTest {

    // region Swipe concluído -> onPagerSettled

    @Test
    fun swipeConcluidoEmRaizAtualizaAbaSelecionadaERota() {
        val nav = AppNavigationState(ScreenRoute.Simulacao)

        nav.onPagerSettled(1)

        assertEquals(ScreenRoute.Cenarios, nav.currentRoute)
        assertEquals(1, nav.selectedTab)
        assertFalse(nav.canGoBack)
    }

    @Test
    fun sequenciaDeSwipesPercorreAsTresAbasSemEmpilharHistorico() {
        val nav = AppNavigationState(ScreenRoute.Simulacao)

        nav.onPagerSettled(1)
        assertEquals(ScreenRoute.Cenarios, nav.currentRoute)

        nav.onPagerSettled(2)
        assertEquals(ScreenRoute.Perfil, nav.currentRoute)

        nav.onPagerSettled(0)
        assertEquals(ScreenRoute.Simulacao, nav.currentRoute)

        assertFalse(nav.canGoBack)
    }

    @Test
    fun settleNaMesmaAbaNaoAlteraEstado() {
        val nav = AppNavigationState(ScreenRoute.Simulacao)
        nav.selectTab(1)

        nav.onPagerSettled(1)

        assertEquals(ScreenRoute.Cenarios, nav.currentRoute)
        assertEquals(1, nav.selectedTab)
        assertFalse(nav.canGoBack)
    }

    @Test
    fun settleComSubTelaAbertaNaoTrocaDeAba() {
        val nav = AppNavigationState(ScreenRoute.Simulacao)
        nav.navigate(ScreenRoute.Parametros)

        nav.onPagerSettled(2)

        assertEquals(ScreenRoute.Parametros, nav.currentRoute)
        assertEquals(0, nav.selectedTab)
    }

    // endregion

    // region Scroll do pager habilitado apenas em raízes de aba

    @Test
    fun scrollDoPagerHabilitadoSomenteEmRaizesDeAba() {
        ScreenRoute.TAB_ROOTS.forEach { rota ->
            assertTrue(rota.isTabRoot, "Esperava scroll habilitado em ${rota.id}")
        }
        ScreenRoute.SUB_SCREENS + listOf(ScreenRoute.Login, ScreenRoute.Cadastro)
            .forEach { rota ->
                assertFalse(rota.isTabRoot, "Esperava scroll desabilitado em ${rota.id}")
            }
    }

    // endregion

    // region Sincronização inversa: selectedTab reposiciona o pager

    @Test
    fun voltarDeSubTelaReposicionaOAbaAlvoDoPager() {
        val nav = AppNavigationState(ScreenRoute.Simulacao)
        nav.selectTab(1)
        nav.navigate(ScreenRoute.Resultados)

        assertTrue(nav.goBack())

        // selectedTab volta para a aba de origem; em App.kt esse valor dispara
        // animateScrollToPage no pager.
        assertEquals(1, nav.selectedTab)
        assertEquals(ScreenRoute.Cenarios, nav.currentRoute)
    }

    @Test
    fun toqueNaBottomBarReposicionaOAbaAlvoDoPager() {
        val nav = AppNavigationState(ScreenRoute.Simulacao)

        nav.selectTab(2)

        assertEquals(2, nav.selectedTab)
        assertEquals(ScreenRoute.Perfil, nav.currentRoute)
    }

    // endregion
}
