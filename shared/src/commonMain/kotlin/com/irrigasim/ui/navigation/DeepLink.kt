package com.irrigasim.ui.navigation

import com.irrigasim.domain.MetodoIrrigacao

/**
 * Destino de um deep link após o parse da URI.
 */
sealed class DeepLinkDestination {

    /** Tela de login. */
    data object Login : DeepLinkDestination()

    /** Tela de cadastro. */
    data object Cadastro : DeepLinkDestination()

    /** Raiz de uma aba do aplicativo (simulação, cenários ou perfil). */
    data class Tab(val route: ScreenRoute) : DeepLinkDestination()

    /** Guia didático (wizard). */
    data object Wizard : DeepLinkDestination()

    /** Tela de parâmetros com método de irrigação pré-selecionado. */
    data class Parametros(val metodo: MetodoIrrigacao) : DeepLinkDestination()

    /** Tela de resultados de um cenário salvo específico. */
    data class Resultados(val cenarioId: String) : DeepLinkDestination()
}

/**
 * Ação de navegação resultante da resolução de um [DeepLinkDestination],
 * já considerando o estado de autenticação. Aplicável diretamente pelo host UI.
 */
sealed interface DeepLinkAction {

    /** Seleciona uma aba raiz (limpando a pilha de navegação). */
    data class SelectTab(val index: Int) : DeepLinkAction

    /** Empurra uma rota na pilha atual. */
    data class NavigateTo(val route: ScreenRoute) : DeepLinkAction

    /** Seleciona o método informado e abre a tela de parâmetros. */
    data class OpenParametros(val metodo: MetodoIrrigacao) : DeepLinkAction

    /** Abre os resultados de um cenário salvo pelo identificador. */
    data class OpenCenario(val cenarioId: String) : DeepLinkAction
}

/**
 * Padrões de URI para deep linking (implementação manual, sem biblioteca externa).
 *
 * Padrões suportados:
 * - `irrigasim://login`
 * - `irrigasim://cadastro`
 * - `irrigasim://simulacao`
 * - `irrigasim://cenarios`
 * - `irrigasim://perfil`
 * - `irrigasim://wizard`
 * - `irrigasim://parametros/{metodo}` com `metodo` em `sulco|faixa|bacia`
 * - `irrigasim://resultados/{cenarioId}`
 *
 * Query strings (ex.: `?src=notificacao`) e barras finais são toleradas.
 */
object DeepLink {

    const val SCHEME = "irrigasim"

    /** Padrão canônico de URI de cada rota (parâmetros entre chaves). */
    val PATTERNS: Map<ScreenRoute, String> = mapOf(
        ScreenRoute.Login to "$SCHEME://login",
        ScreenRoute.Cadastro to "$SCHEME://cadastro",
        ScreenRoute.Simulacao to "$SCHEME://simulacao",
        ScreenRoute.Cenarios to "$SCHEME://cenarios",
        ScreenRoute.Perfil to "$SCHEME://perfil",
        ScreenRoute.Wizard to "$SCHEME://wizard",
        ScreenRoute.Parametros to "$SCHEME://parametros/{metodo}",
        ScreenRoute.Resultados to "$SCHEME://resultados/{cenarioId}"
    )

    /** Constrói a URI canônica de rotas sem parâmetros. */
    fun uriFor(route: ScreenRoute): String? = PATTERNS[route]?.takeIf { !it.contains('{') }

    /** Constrói a URI da tela de parâmetros para o método informado. */
    fun parametrosUri(metodo: MetodoIrrigacao): String =
        "$SCHEME://parametros/${metodoSegment(metodo)}"

    /** Constrói a URI de resultados de um cenário salvo. */
    fun resultadosUri(cenarioId: String): String =
        "$SCHEME://resultados/$cenarioId"

    /**
     * Interpreta uma URI e devolve o destino correspondente, ou `null` quando
     * o esquema/host/parâmetros não correspondem a nenhum padrão conhecido.
     */
    fun parse(uri: String): DeepLinkDestination? {
        val prefixo = "$SCHEME://"
        if (!uri.startsWith(prefixo, ignoreCase = true)) return null

        val caminho = uri.substring(prefixo.length).substringBefore('?')
        val segmentos = caminho.split('/').filter { it.isNotBlank() }
        if (segmentos.isEmpty()) return null

        val host = segmentos[0].lowercase()
        val argumento = segmentos.getOrNull(1)

        return when (host) {
            "login" -> takeIfUnico(segmentos)?.let { DeepLinkDestination.Login }
            "cadastro" -> takeIfUnico(segmentos)?.let { DeepLinkDestination.Cadastro }
            "simulacao" -> rotaDeAba(ScreenRoute.Simulacao, argumento)
            "cenarios" -> rotaDeAba(ScreenRoute.Cenarios, argumento)
            "perfil" -> rotaDeAba(ScreenRoute.Perfil, argumento)
            "wizard" -> takeIfUnico(segmentos)?.let { DeepLinkDestination.Wizard }
            "parametros" -> takeIfDois(segmentos)?.let { metodoDe(it)?.let(DeepLinkDestination::Parametros) }
            "resultados" -> takeIfDois(segmentos)
                ?.takeIf { it.isNotBlank() }
                ?.let(DeepLinkDestination::Resultados)
            else -> null
        }
    }

    private fun takeIfUnico(segmentos: List<String>): Unit? =
        if (segmentos.size == 1) Unit else null

    private fun takeIfDois(segmentos: List<String>): String? =
        segmentos.getOrNull(1)?.takeIf { segmentos.size == 2 }

    private fun rotaDeAba(route: ScreenRoute, argumento: String?): DeepLinkDestination? =
        if (argumento == null) DeepLinkDestination.Tab(route) else null

    private fun metodoDe(valor: String?): MetodoIrrigacao? {
        if (valor.isNullOrBlank()) return null
        return try {
            MetodoIrrigacao.fromString(valor)
        } catch (_: IllegalArgumentException) {
            null
        }
    }

    private fun metodoSegment(metodo: MetodoIrrigacao): String = when (metodo) {
        MetodoIrrigacao.SULCO -> "sulco"
        MetodoIrrigacao.FAIXA -> "faixa"
        MetodoIrrigacao.INUNDACAO -> "bacia"
    }
}

/**
 * Converte um destino de deep link na ação de navegação correspondente,
 * respeitando as regras de autenticação:
 * - sem usuário autenticado, apenas telas de autenticação são acessíveis;
 * - com usuário autenticado, links de login/cadastro são ignorados.
 *
 * A existência do cenário em [DeepLinkAction.OpenCenario] é verificada no
 * momento da aplicação (dados vivos), com fallback para a aba de cenários.
 */
fun DeepLinkDestination.resolveDeepLinkAction(isAuthenticated: Boolean): DeepLinkAction? = when (this) {
    is DeepLinkDestination.Login ->
        if (isAuthenticated) null else DeepLinkAction.NavigateTo(ScreenRoute.Login)
    is DeepLinkDestination.Cadastro ->
        if (isAuthenticated) null else DeepLinkAction.NavigateTo(ScreenRoute.Cadastro)
    is DeepLinkDestination.Tab -> {
        if (isAuthenticated) route.tabIndex?.let { DeepLinkAction.SelectTab(it) } else null
    }
    is DeepLinkDestination.Wizard ->
        if (isAuthenticated) DeepLinkAction.NavigateTo(ScreenRoute.Wizard) else null
    is DeepLinkDestination.Parametros ->
        if (isAuthenticated) DeepLinkAction.OpenParametros(metodo) else null
    is DeepLinkDestination.Resultados ->
        if (isAuthenticated) DeepLinkAction.OpenCenario(cenarioId) else null
}
