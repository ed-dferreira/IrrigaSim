package com.irrigasim.domain.faixas

import kotlin.math.pow
import kotlin.math.sqrt

/**
 * Limites de vazão para irrigação por faixas.
 * Qmáx: Hart et al. (1980) — capacidade hidráulica máxima da faixa.
 * Qmín: Walker & Skogerboe (1984) — vazão mínima para completar o avanço.
 */
object VazaoLimites {
    private const val L_S_PARA_M3_MIN = 0.06 // 1 L/s = 0.06 m³/min

    /**
     * Qmáx unitária (m³/min/m de largura) via Manning para escoamento em lâmina livre.
     * y ≈ (q·n / √S)^(3/5) → q_max = (1/n)·√S·y^(5/3)
     * y estimado pela profundidade crítica aproximada para border: y ≈ 0.05 m.
     */
    fun qMaxHart(declividade: Double, manningN: Double, profundidadeEstimadaM: Double = 0.05): Double {
        require(declividade > 0) { "Declividade deve ser positiva para Qmáx" }
        require(manningN > 0)
        val q = (1.0 / manningN) * sqrt(declividade) * profundidadeEstimadaM.pow(5.0 / 3.0)
        return q // m³/min/m
    }

    /** Converte m³/min/m para L/s/m */
    fun m3MinParaLs(qM3MinPorMetro: Double): Double = qM3MinPorMetro / L_S_PARA_M3_MIN

    /** Converte L/s/m para m³/min/m */
    fun lsParaM3Min(qLsPorMetro: Double): Double = qLsPorMetro * L_S_PARA_M3_MIN

    /**
     * Qmín unitária (L/s/m) — Walker & Skogerboe.
     * Q_min = (σz · Z(ta) · L) / (ti · W) ajustado para unidade por metro de largura.
     */
    fun qMinWalker(
        comprimento: Double,
        largura: Double,
        sigmaZ: Double,
        laminaInfiltradaAvancoMm: Double,
        tempoAplicacaoMin: Double
    ): Double {
        require(comprimento > 0 && largura > 0 && tempoAplicacaoMin > 0)
        val volumeInfiltracaoM3 = (laminaInfiltradaAvancoMm / 1000.0) * comprimento * largura
        val qTotalM3Min = (sigmaZ * volumeInfiltracaoM3) / tempoAplicacaoMin
        val qUnitM3Min = qTotalM3Min / largura
        return m3MinParaLs(qUnitM3Min)
    }
}
