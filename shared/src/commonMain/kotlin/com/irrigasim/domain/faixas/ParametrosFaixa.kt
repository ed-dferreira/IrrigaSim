package com.irrigasim.domain.faixas

/**
 * Parâmetros completos para simulação de irrigação por faixas (border).
 * Unidades conforme planilha de referência da Aula 7.
 */
data class ParametrosFaixa(
    /** Coeficiente k de Kostiakov (mm/h^a) */
    val k: Double,
    /** Expoente a de Kostiakov */
    val a: Double,
    /** Taxa de infiltração básica VIB (mm/h) */
    val vib: Double,
    /** Comprimento da faixa (m) */
    val comprimento: Double,
    /** Largura da faixa (m) */
    val largura: Double,
    /** Declividade longitudinal (m/m ou %) — armazenada como fração (ex.: 0.001 = 0,1%) */
    val declividade: Double,
    /** Rugosidade de Manning n */
    val manningN: Double,
    /** Lâmina líquida requerida / IRN (mm) */
    val laminaRequerida: Double,
    /** Vazão unitária de entrada Q0 (L/s/m de largura) */
    val vazaoEntrada: Double,
    /** Tempo de aplicação / corte de vazão ti (min) */
    val tempoAplicacao: Double,
    /** Fator de armazenamento superficial σz (adimensional) */
    val sigmaZ: Double = 0.25,
    /** Expoente de forma do perfil de avanço r (adimensional) */
    val expoenteFormaR: Double = 0.5,
    /** Vazão total disponível na tomada Qt (L/s) — para alerta de dimensionamento */
    val vazaoDisponivel: Double? = null,
    /** Vazões candidatas para teste de desempenho (L/s/m), opcional */
    val vazoesCandidatas: List<Double> = emptyList()
) {
    init {
        require(comprimento > 0) { "Comprimento deve ser positivo" }
        require(largura > 0) { "Largura deve ser positiva" }
        require(declividade >= 0) { "Declividade não pode ser negativa" }
        require(manningN > 0) { "Manning n deve ser positivo" }
        require(k >= 0) { "k deve ser não negativo" }
        require(a in 0.0..1.0) { "a deve estar entre 0 e 1" }
        require(vib >= 0) { "VIB deve ser não negativo" }
        require(vazaoEntrada > 0) { "Vazão de entrada deve ser positiva" }
        require(tempoAplicacao > 0) { "Tempo de aplicação deve ser positivo" }
        require(laminaRequerida > 0) { "Lâmina requerida deve ser positiva" }
        require(sigmaZ > 0) { "σz deve ser positivo" }
        require(expoenteFormaR > 0) { "r deve ser positivo" }
    }

    /** Declividade em percentual para exibição */
    val declividadePercentual: Double get() = declividade * 100.0

    companion object {
        /**
         * Caso de referência derivado da planilha Projeto_Inundação_intermitente
         * (valores citados na validação: Qmáx ≈ 0,872889 m³/min/m ↔ 14,548 L/s/m, Ea ≈ 87,89%).
         */
        fun exemploReferencia(): ParametrosFaixa = ParametrosFaixa(
            k = 45.0,
            a = 0.55,
            vib = 2.0,
            comprimento = 400.0,
            largura = 20.0,
            declividade = 0.001,
            manningN = 0.04,
            laminaRequerida = 50.0,
            vazaoEntrada = 14.548,
            tempoAplicacao = 120.0,
            sigmaZ = 0.25,
            expoenteFormaR = 0.5,
            vazaoDisponivel = 300.0,
            vazoesCandidatas = listOf(8.0, 10.0, 12.0, 14.548, 16.0, 18.0, 20.0, 22.0, 24.0)
        )
    }
}
