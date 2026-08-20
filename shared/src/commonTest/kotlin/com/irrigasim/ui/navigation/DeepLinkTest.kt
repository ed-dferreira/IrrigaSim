package com.irrigasim.ui.navigation

import com.irrigasim.domain.MetodoIrrigacao
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DeepLinkTest {

    // region Parse: padrões simples

    @Test
    fun parseResolveTodasAsTelasSemParametro() {
        assertEquals(DeepLinkDestination.Login, DeepLink.parse("irrigasim://login"))
        assertEquals(DeepLinkDestination.Cadastro, DeepLink.parse("irrigasim://cadastro"))
        assertEquals(
            DeepLinkDestination.Tab(ScreenRoute.Simulacao),
            DeepLink.parse("irrigasim://simulacao")
        )
        assertEquals(
            DeepLinkDestination.Tab(ScreenRoute.Cenarios),
            DeepLink.parse("irrigasim://cenarios")
        )
        assertEquals(
            DeepLinkDestination.Tab(ScreenRoute.Perfil),
            DeepLink.parse("irrigasim://perfil")
        )
        assertEquals(DeepLinkDestination.Wizard, DeepLink.parse("irrigasim://wizard"))
    }

    // endregion

    // region Parse: parâmetros de navegação

    @Test
    fun parseParametrosComMetodoValido() {
        assertEquals(
            DeepLinkDestination.Parametros(MetodoIrrigacao.SULCO),
            DeepLink.parse("irrigasim://parametros/sulco")
        )
        assertEquals(
            DeepLinkDestination.Parametros(MetodoIrrigacao.FAIXA),
            DeepLink.parse("irrigasim://parametros/faixa")
        )
        assertEquals(
            DeepLinkDestination.Parametros(MetodoIrrigacao.INUNDACAO),
            DeepLink.parse("irrigasim://parametros/bacia")
        )
    }

    @Test
    fun parseResultadosComIdentificadorDeCenario() {
        assertEquals(
            DeepLinkDestination.Resultados("cenario-42"),
            DeepLink.parse("irrigasim://resultados/cenario-42")
        )
    }

    @Test
    fun parseToleraQueryStringBarrasExtrasECaixaDiferente() {
        assertEquals(
            DeepLinkDestination.Parametros(MetodoIrrigacao.SULCO),
            DeepLink.parse("irrigasim://parametros/sulco?src=notificacao")
        )
        assertEquals(
            DeepLinkDestination.Tab(ScreenRoute.Cenarios),
            DeepLink.parse("irrigasim://cenarios/")
        )
        assertEquals(
            DeepLinkDestination.Login,
            DeepLink.parse("IRRIGASIM://Login")
        )
    }

    // endregion

    // region Parse: URIs inválidas

    @Test
    fun parseRejeitaEsquemaDesconhecido() {
        assertNull(DeepLink.parse("https://irrigasim.app/login"))
        assertNull(DeepLink.parse("outroapp://login"))
        assertNull(DeepLink.parse("irrigasim:/login"))
    }

    @Test
    fun parseRejeitaHostDesconhecidoOuVazio() {
        assertNull(DeepLink.parse("irrigasim://teladesconhecida"))
        assertNull(DeepLink.parse("irrigasim://"))
    }

    @Test
    fun parseRejeitaParametrosInvalidos() {
        assertNull(DeepLink.parse("irrigasim://parametros"))
        assertNull(DeepLink.parse("irrigasim://parametros/metodo_inexistente"))
        assertNull(DeepLink.parse("irrigasim://resultados"))
        assertNull(DeepLink.parse("irrigasim://resultados/"))
    }

    @Test
    fun parseRejeitaSegmentosExcedentes() {
        assertNull(DeepLink.parse("irrigasim://login/extra"))
        assertNull(DeepLink.parse("irrigasim://parametros/sulco/extra"))
        assertNull(DeepLink.parse("irrigasim://simulacao/extra"))
    }

    // endregion

    // region Construção de URIs

    @Test
    fun padroesCobremTodasAsRotas() {
        val todas = ScreenRoute.TAB_ROOTS + ScreenRoute.SUB_SCREENS +
            listOf(ScreenRoute.Login, ScreenRoute.Cadastro)
        todas.forEach { rota ->
            assertTrue(
                DeepLink.PATTERNS.containsKey(rota),
                "Falta padrão de URI para a rota ${rota.id}"
            )
        }
    }

    @Test
    fun uriForRoundTrip() {
        assertEquals(
            DeepLinkDestination.Wizard,
            DeepLink.parse(DeepLink.uriFor(ScreenRoute.Wizard)!!)
        )
        assertNull(DeepLink.uriFor(ScreenRoute.Parametros), "Rota parametrizada não deve ter URI fixa")
    }

    @Test
    fun urisParametrizadasFazemRoundTrip() {
        MetodoIrrigacao.entries.forEach { metodo ->
            val destino = DeepLink.parse(DeepLink.parametrosUri(metodo))
            assertIs<DeepLinkDestination.Parametros>(destino)
            assertEquals(metodo, destino.metodo)
        }
        val destino = DeepLink.parse(DeepLink.resultadosUri("abc123"))
        assertEquals(DeepLinkDestination.Resultados("abc123"), destino)
    }

    // endregion

    // region Resolução de ações (regras de autenticação)

    @Test
    fun semAutenticacaoSomenteTelasDeAuthSaoPermitidas() {
        assertNotNull(DeepLinkDestination.Login.resolveDeepLinkAction(isAuthenticated = false))
        assertNotNull(DeepLinkDestination.Cadastro.resolveDeepLinkAction(isAuthenticated = false))
        assertNull(DeepLinkDestination.Tab(ScreenRoute.Cenarios).resolveDeepLinkAction(isAuthenticated = false))
        assertNull(DeepLinkDestination.Wizard.resolveDeepLinkAction(isAuthenticated = false))
        assertNull(
            DeepLinkDestination.Parametros(MetodoIrrigacao.SULCO)
                .resolveDeepLinkAction(isAuthenticated = false)
        )
        assertNull(DeepLinkDestination.Resultados("1").resolveDeepLinkAction(isAuthenticated = false))
    }

    @Test
    fun comAutenticacaoLinksDeAuthSaoIgnorados() {
        assertNull(DeepLinkDestination.Login.resolveDeepLinkAction(isAuthenticated = true))
        assertNull(DeepLinkDestination.Cadastro.resolveDeepLinkAction(isAuthenticated = true))
    }

    @Test
    fun comAutenticacaoAbasMapeiamParaIndice() {
        val acao = DeepLinkDestination.Tab(ScreenRoute.Cenarios).resolveDeepLinkAction(isAuthenticated = true)
        assertEquals(DeepLinkAction.SelectTab(1), acao)

        val acaoSimulacao = DeepLinkDestination.Tab(ScreenRoute.Simulacao).resolveDeepLinkAction(isAuthenticated = true)
        assertEquals(DeepLinkAction.SelectTab(0), acaoSimulacao)

        val acaoPerfil = DeepLinkDestination.Tab(ScreenRoute.Perfil).resolveDeepLinkAction(isAuthenticated = true)
        assertEquals(DeepLinkAction.SelectTab(2), acaoPerfil)
    }

    @Test
    fun comAutenticacaoSubTelasGeramAcoesCorretas() {
        assertEquals(
            DeepLinkAction.NavigateTo(ScreenRoute.Wizard),
            DeepLinkDestination.Wizard.resolveDeepLinkAction(isAuthenticated = true)
        )
        assertEquals(
            DeepLinkAction.OpenParametros(MetodoIrrigacao.FAIXA),
            DeepLinkDestination.Parametros(MetodoIrrigacao.FAIXA).resolveDeepLinkAction(isAuthenticated = true)
        )
        assertEquals(
            DeepLinkAction.OpenCenario("cenario-7"),
            DeepLinkDestination.Resultados("cenario-7").resolveDeepLinkAction(isAuthenticated = true)
        )
    }

    // endregion

    // region Sanidade da pilha de navegação com deep links

    @Test
    fun deepLinkDeSubTelaMantemPilhaParaVoltaAAbaCorreta() {
        val nav = AppNavigationState(ScreenRoute.Simulacao)
        nav.selectTab(1)

        // Simula aplicação de irrigasim://resultados/{id} vindo da aba Cenarios
        val acao = DeepLinkDestination.Resultados("cenario-1").resolveDeepLinkAction(isAuthenticated = true)
        assertIs<DeepLinkAction.OpenCenario>(acao)
        nav.navigate(ScreenRoute.Resultados)

        assertTrue(nav.canGoBack)
        assertTrue(nav.goBack())
        assertEquals(ScreenRoute.Cenarios, nav.currentRoute)
        assertEquals(1, nav.selectedTab)
        assertFalse(nav.canGoBack)
    }

    // endregion
}
