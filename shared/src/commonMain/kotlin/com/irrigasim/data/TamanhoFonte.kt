package com.irrigasim.data

/**
 * Opções de tamanho de fonte da interface, aplicadas como escala sobre a
 * tipografia base do tema.
 */
enum class TamanhoFonte(val label: String, val escala: Float) {
    PEQUENO("Pequeno", 0.9f),
    MEDIO("Médio", 1.0f),
    GRANDE("Grande", 1.15f),
    MUITO_GRANDE("Muito grande", 1.3f);

    companion object {
        /** Padrão do app. */
        val PADRAO = MEDIO

        /** Converte um nome persistido; valores desconhecidos caem no padrão. */
        fun fromName(nome: String): TamanhoFonte =
            entries.firstOrNull { it.name == nome } ?: PADRAO
    }
}
