package com.irrigasim.ui.navigation

sealed class ScreenRoute(val id: String, val label: String) {

    data object Login : ScreenRoute("login", "Entrar")
    data object Cadastro : ScreenRoute("cadastro", "Criar conta")

    data object Simulacao : ScreenRoute("simulacao", "Simulação")
    data object Cenarios : ScreenRoute("cenarios", "Cenários")
    data object Perfil : ScreenRoute("perfil", "Perfil")

    data object Wizard : ScreenRoute("wizard", "Guia Didático")
    data object Parametros : ScreenRoute("parametros", "Parâmetros")
    data object Resultados : ScreenRoute("resultados", "Resultados")

    val tabIndex: Int?
        get() = TAB_ROOTS.indexOf(this).takeIf { it >= 0 }

    val isTabRoot: Boolean
        get() = tabIndex != null

    /**
     * Profundidade hierárquica da rota, usada para definir a direção das
     * transições de navegação (avançar desliza para um lado, voltar para o outro).
     */
    val navDepth: Int
        get() = when (this) {
            Cadastro, Wizard, Parametros, Resultados -> 1
            else -> 0
        }

    companion object {
        // `by lazy` evita ciclo de inicialização na JVM: se o <clinit> da classe
        // rodar durante o <clinit> de um subobjeto (rota), os campos INSTANCE
        // ainda seriam nulos e as listas ficariam envenenadas com elementos null.
        val TAB_ROOTS: List<ScreenRoute> by lazy { listOf(Simulacao, Cenarios, Perfil) }

        val SUB_SCREENS: List<ScreenRoute> by lazy { listOf(Wizard, Parametros, Resultados) }

        private val ALL: List<ScreenRoute> by lazy {
            listOf(Login, Cadastro, Simulacao, Cenarios, Perfil, Wizard, Parametros, Resultados)
        }

        fun fromId(id: String): ScreenRoute? = ALL.firstOrNull { it.id == id }
    }
}
