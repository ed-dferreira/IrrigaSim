package com.irrigasim.domain.indicadores

import kotlin.math.abs

/**
 * Indicadores de desempenho para sistemas de irrigação por superfície.
 *
 * Referências:
 *  - Christiansen, J.E. (1942) — CUC / Coeficiente de Uniformidade
 *  - Merriam & Keller (1978)  — DU / Distribution Uniformity
 *  - Burt et al. (1997)       — Definições consolidadas de Ea e Er
 *  - Clemmens & Dedrick (1994) — Classificação de desempenho
 */
object IndicadoresDesempenho {

    // ────────────────────────────────────────────────────────────────────────
    // 1. Eficiência de Aplicação (Ea)
    // ────────────────────────────────────────────────────────────────────────

    /**
     * Ea = (Lâmina armazenada na zona radicular) / (Lâmina total aplicada) × 100
     *
     * @param laminaArmazenadaMm  Volume útil infiltrado na zona radicular (mm)
     * @param laminaAplicadaMm    Volume total aplicado (mm)
     * @return Ea em percentual [0, 100]
     */
    fun eficienciaAplicacao(laminaArmazenadaMm: Double, laminaAplicadaMm: Double): Double {
        require(laminaAplicadaMm > 0) { "Lâmina aplicada deve ser positiva" }
        return (laminaArmazenadaMm / laminaAplicadaMm * 100.0).coerceIn(0.0, 100.0)
    }

    // ────────────────────────────────────────────────────────────────────────
    // 2. Eficiência de Requerimento (Er)
    // ────────────────────────────────────────────────────────────────────────

    /**
     * Er = (Lâmina armazenada ≥ LN ao longo do campo) / (Lâmina requerida LN) × 100
     *
     * Indica a fração do campo que recebeu ao menos a lâmina líquida necessária.
     * Er = 100% quando toda a área recebeu LN ou mais.
     *
     * @param laminasInfiltradas  Lista de lâminas infiltradas em cada ponto longitudinal (mm)
     * @param laminaRequeridaMm   Lâmina líquida necessária LN (mm)
     * @return Er em percentual [0, 100]
     */
    fun eficienciaRequerimento(laminasInfiltradas: List<Double>, laminaRequeridaMm: Double): Double {
        require(laminaRequeridaMm > 0) { "LN deve ser positiva" }
        if (laminasInfiltradas.isEmpty()) return 0.0
        val suprida = laminasInfiltradas.sumOf { minOf(it, laminaRequeridaMm) }
        val necessaria = laminaRequeridaMm * laminasInfiltradas.size
        return (suprida / necessaria * 100.0).coerceIn(0.0, 100.0)
    }

    // ────────────────────────────────────────────────────────────────────────
    // 3. CUC — Coeficiente de Uniformidade de Christiansen
    // ────────────────────────────────────────────────────────────────────────

    /**
     * CUC = [1 − (Σ|Zi − Z̄| / (n · Z̄))] × 100
     *
     * onde:
     *  - Zi = lâmina infiltrada em cada ponto (mm)
     *  - Z̄  = média das lâminas infiltradas (mm)
     *  - n  = número de pontos de amostragem
     *
     * Classificação (Merriam & Keller):
     *  CUC ≥ 90% → Excelente
     *  CUC 80–90% → Boa
     *  CUC 70–80% → Regular
     *  CUC < 70%  → Ruim
     *
     * @param laminasInfiltradas Lâminas infiltradas em pontos equidistantes ao longo do campo (mm)
     * @return CUC em percentual [0, 100]
     */
    fun cuc(laminasInfiltradas: List<Double>): Double {
        require(laminasInfiltradas.size >= 2) { "São necessários ao menos 2 pontos para calcular CUC" }
        val media = laminasInfiltradas.average()
        if (media == 0.0) return 0.0
        val somaDesvios = laminasInfiltradas.sumOf { abs(it - media) }
        return (1.0 - somaDesvios / (laminasInfiltradas.size * media)) * 100.0
    }

    // ────────────────────────────────────────────────────────────────────────
    // 4. DU — Distribution Uniformity (Distribuição no Quarto Inferior)
    // ────────────────────────────────────────────────────────────────────────

    /**
     * DU = (Z̄_qi / Z̄) × 100
     *
     * onde Z̄_qi é a média do quarto inferior das lâminas infiltradas (25% menores valores).
     * DU é mais sensível a déficits localizados que o CUC.
     *
     * Classificação (ASCE Manual of Engineering Practice):
     *  DU ≥ 85% → Excelente
     *  DU 75–85% → Boa
     *  DU 65–75% → Regular
     *  DU < 65%  → Ruim
     *
     * @param laminasInfiltradas Lâminas infiltradas em pontos equidistantes (mm)
     * @return DU em percentual [0, 100]
     */
    fun du(laminasInfiltradas: List<Double>): Double {
        require(laminasInfiltradas.size >= 4) { "São necessários ao menos 4 pontos para calcular DU" }
        val sorted = laminasInfiltradas.sorted()
        val n25 = maxOf(1, sorted.size / 4)
        val mediaQuartoInferior = sorted.take(n25).average()
        val mediaTotal = laminasInfiltradas.average()
        if (mediaTotal == 0.0) return 0.0
        return (mediaQuartoInferior / mediaTotal * 100.0).coerceIn(0.0, 100.0)
    }

    // ────────────────────────────────────────────────────────────────────────
    // 5. Perdas
    // ────────────────────────────────────────────────────────────────────────

    /**
     * Perda por percolação profunda (%) — lâmina infiltrada além da zona radicular.
     *
     * Pp = max(0, Z̄ − LN) / Z̄_aplicada × 100
     */
    fun perdaPercolacao(laminaMediaInfiltradaMm: Double, laminaRequeridaMm: Double, laminaAplicadaMm: Double): Double {
        if (laminaAplicadaMm <= 0) return 0.0
        val excesso = (laminaMediaInfiltradaMm - laminaRequeridaMm).coerceAtLeast(0.0)
        return (excesso / laminaAplicadaMm * 100.0).coerceIn(0.0, 100.0)
    }

    /**
     * Perda por escoamento superficial (%) — água que sai do campo sem infiltrar.
     *
     * Pe = max(0, 100 − Ea − Pp)
     */
    fun perdaEscoamento(ea: Double, pp: Double): Double =
        (100.0 - ea - pp).coerceAtLeast(0.0)

    // ────────────────────────────────────────────────────────────────────────
    // 6. Geração do perfil longitudinal de lâmina infiltrada
    // ────────────────────────────────────────────────────────────────────────

    /**
     * Gera lista de lâminas infiltradas em N pontos equidistantes ao longo do campo,
     * usando Kostiakov-Lewis com tempo de oportunidade variável por posição.
     *
     * O tempo de oportunidade em cada ponto x é:
     *   τ(x) = (ti − ta(x)) + tr(x)
     * onde ta(x) = tempo de avanço até x, tr(x) = tempo de recessão a partir de x.
     *
     * Simplificação: variação linear de τ entre τ_montante e τ_jusante.
     *
     * @param tauMontanteMin  Tempo de oportunidade na cabeceira (x=0), em minutos
     * @param tauJusanteMin   Tempo de oportunidade na extremidade (x=L), em minutos
     * @param k               Coeficiente Kostiakov (mm/h^a)
     * @param a               Expoente Kostiakov
     * @param vib             VIB — taxa básica de infiltração (mm/h)
     * @param nPontos         Número de pontos de amostragem longitudinal
     * @return Lista de lâminas infiltradas em mm, do ponto 0 a L
     */
    fun perfilLongitudinal(
        tauMontanteMin: Double,
        tauJusanteMin: Double,
        k: Double,
        a: Double,
        vib: Double,
        nPontos: Int = 20
    ): List<Double> {
        require(nPontos >= 2)
        return (0 until nPontos).map { i ->
            val fracao = i.toDouble() / (nPontos - 1)
            val tauMin = tauMontanteMin + fracao * (tauJusanteMin - tauMontanteMin)
            val tauH = tauMin / 60.0
            if (tauH <= 0) 0.0
            else k * Math.pow(tauH, a) + vib * tauH
        }
    }

    // ────────────────────────────────────────────────────────────────────────
    // 7. Classificação de desempenho
    // ────────────────────────────────────────────────────────────────────────

    enum class NivelDesempenho(val label: String, val emoji: String) {
        EXCELENTE("Excelente", "🏆"),
        BOA("Boa", "✅"),
        REGULAR("Regular", "⚠️"),
        RUIM("Ruim", "❌")
    }

    data class AvaliacaoDesempenho(
        val ea: Double,
        val er: Double,
        val cuc: Double,
        val du: Double,
        val nivelEa: NivelDesempenho,
        val nivelCuc: NivelDesempenho,
        val nivelDu: NivelDesempenho,
        val recomendacao: String
    )

    fun classificarEa(ea: Double): NivelDesempenho = when {
        ea >= 80 -> NivelDesempenho.EXCELENTE
        ea >= 65 -> NivelDesempenho.BOA
        ea >= 50 -> NivelDesempenho.REGULAR
        else     -> NivelDesempenho.RUIM
    }

    fun classificarCuc(cuc: Double): NivelDesempenho = when {
        cuc >= 90 -> NivelDesempenho.EXCELENTE
        cuc >= 80 -> NivelDesempenho.BOA
        cuc >= 70 -> NivelDesempenho.REGULAR
        else      -> NivelDesempenho.RUIM
    }

    fun classificarDu(du: Double): NivelDesempenho = when {
        du >= 85 -> NivelDesempenho.EXCELENTE
        du >= 75 -> NivelDesempenho.BOA
        du >= 65 -> NivelDesempenho.REGULAR
        else     -> NivelDesempenho.RUIM
    }

    fun avaliar(
        ea: Double,
        er: Double,
        cuc: Double,
        du: Double,
        laminaMediaMm: Double,
        laminaRequeridaMm: Double
    ): AvaliacaoDesempenho {
        val nivelEa = classificarEa(ea)
        val nivelCuc = classificarCuc(cuc)
        val nivelDu = classificarDu(du)

        val recomendacao = buildString {
            when (nivelEa) {
                NivelDesempenho.EXCELENTE -> append("Eficiência excelente (Ea = ${ea.toInt()}%). ")
                NivelDesempenho.BOA -> append("Eficiência boa (Ea = ${ea.toInt()}%). ")
                NivelDesempenho.REGULAR -> append("Ea = ${ea.toInt()}%: considere reduzir a vazão ou o tempo de aplicação. ")
                NivelDesempenho.RUIM -> append("Ea = ${ea.toInt()}%: eficiência inadequada — reavalie o dimensionamento. ")
            }
            if (er < 90) append("Er = ${er.toInt()}%: parte do campo recebe menos que LN = ${laminaRequeridaMm.toInt()} mm. ")
            if (nivelCuc == NivelDesempenho.REGULAR || nivelCuc == NivelDesempenho.RUIM)
                append("CUC = ${cuc.toInt()}%: distribuição irregular — ajuste declividade ou espaçamento. ")
            if (laminaMediaMm > laminaRequeridaMm * 1.3)
                append("Excesso médio de ${(laminaMediaMm - laminaRequeridaMm).toInt()} mm: risco de percolação profunda.")
        }

        return AvaliacaoDesempenho(ea, er, cuc, du, nivelEa, nivelCuc, nivelDu, recomendacao.trim())
    }
}
