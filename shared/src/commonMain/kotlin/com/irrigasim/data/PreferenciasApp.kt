package com.irrigasim.data

/**
 * Preferências do aplicativo persistidas por plataforma.
 *
 * As configurações de acessibilidade sobrevivem à reinicialização do app;
 * o armazenamento atual é em memória por processo (padrão expect/actual).
 */
expect object PreferenciasApp {
    fun onboardingVisto(): Boolean
    fun marcarOnboardingVisto()

    fun temaEscuro(): Boolean
    fun definirTemaEscuro(ativo: Boolean)

    fun tamanhoFonte(): TamanhoFonte
    fun definirTamanhoFonte(tamanho: TamanhoFonte)

    fun altoContraste(): Boolean
    fun definirAltoContraste(ativo: Boolean)

    fun textoNegrito(): Boolean
    fun definirTextoNegrito(ativo: Boolean)

    fun animacoesReduzidas(): Boolean
    fun definirAnimacoesReduzidas(ativo: Boolean)

    fun modoLeitorTela(): Boolean
    fun definirModoLeitorTela(ativo: Boolean)

    /** Restaura todas as preferências aos valores padrão. */
    fun limpar()
}
