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

    companion object {
        val TAB_ROOTS: List<ScreenRoute> = listOf(Simulacao, Cenarios, Perfil)

        val SUB_SCREENS: List<ScreenRoute> = listOf(Wizard, Parametros, Resultados)

        private val ALL: List<ScreenRoute> by lazy {
            listOf(Login, Cadastro, Simulacao, Cenarios, Perfil, Wizard, Parametros, Resultados)
        }

        fun fromId(id: String): ScreenRoute? = ALL.firstOrNull { it.id == id }
    }
}
