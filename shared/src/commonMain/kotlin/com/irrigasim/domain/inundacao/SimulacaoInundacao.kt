package com.irrigasim.domain.inundacao

import com.irrigasim.domain.indicadores.IndicadoresDesempenho
import com.irrigasim.domain.infiltracao.KostiakovLewis
import kotlin.math.abs
import kotlin.math.pow

/**
 * Parâmetros para simulação de irrigação por bacias/inundação (basin/flood).
 *
 * Na irrigação por inundação, toda a bacia é inundada simultaneamente.
 * Pressupostos:
 *  - Bacia perfeitamente nivelada (declividade ≈ 0)
 *  - Distribuição de água uniforme na superfície
 *  - Infiltração descrita por Kostiakov-Lewis em cada ponto
 *  - Tempo de oportunidade uniforme ao longo da bacia
 *
 * Unidades:
 *  - Dimensões: metros (m)
 *  - Vazão: litros por segundo (L/s)
 *  - Tempo: minutos (min)
 *  - Lâmina: milímetros (mm)
 */
data class ParametrosInundacao(
    // ── Kostiakov-Lewis ──────────────────────────────────────────────────────
    /** Coeficiente k de Kostiakov (mm/h^a) */
    val k: Double,
    /** Expoente a de Kostiakov (0 < a < 1) */
    val a: Double,
    /** Taxa de infiltração básica VIB (mm/h) */
    val vib: Double,

    // ── Geometria da bacia ───────────────────────────────────────────────────
    /** Comprimento da bacia (m) */
    val comprimento: Double,
    /** Largura da bacia (m) */
    val largura: Double,
    /** Declividade residual (m/m) — idealmente ≈ 0 para inundação */
    val declividade: Double = 0.0,

    // ── Manejo ───────────────────────────────────────────────────────────────
    /** Lâmina líquida requerida LN (mm) */
    val laminaRequerida: Double,
    /** Vazão de entrada Q0 (L/s) — para a bacia inteira */
    val vazaoEntrada: Double,
    /** Tempo máximo de aplicação disponível ti (min) */
    val tempoAplicacao: Double,

    // ── Infraestrutura ───────────────────────────────────────────────────────
    /** Número de entradas de água (bocas de entrada) na bacia */
    val nEntradas: Int = 1,
    /** Lâmina mínima na superfície para considerar bacia "cheia" (mm) */
    val laminaSuperficieMinMm: Double = 5.0
) {
    init {
        require(comprimento > 0) { "Comprimento deve ser positivo" }
        require(largura > 0) { "Largura deve ser positiva" }
        require(k >= 0) { "k deve ser não negativo" }
        require(a in 0.0..1.0) { "a deve estar entre 0 e 1" }
        require(vib >= 0) { "VIB deve ser não negativo" }
        require(vazaoEntrada > 0) { "Vazão deve ser positiva" }
        require(tempoAplicacao > 0) { "Tempo de aplicação deve ser positivo" }
        require(laminaRequerida > 0) { "Lâmina requerida deve ser positiva" }
        require(nEntradas >= 1) { "Deve haver ao menos 1 entrada" }
    }

    val areaM2: Double get() = comprimento * largura

    companion object {
        /** Caso de referência: bacia de arroz (inundação por pontes) */
        fun exemploReferencia() = ParametrosInundacao(
            k = 20.0, a = 0.40, vib = 1.5,
            comprimento = 50.0, largura = 30.0,
            declividade = 0.0001,
            laminaRequerida = 60.0,
            vazaoEntrada = 25.0,
            tempoAplicacao = 180.0,
            nEntradas = 2,
            laminaSuperficieMinMm = 5.0
        )
    }
}

// ─── Modelos de resultado ─────────────────────────────────────────────────────

data class PontoInundacao(
    val tempoMinutos: Double,
    /** Lâmina na superfície da bacia (mm) — zero quando toda água já infiltrou */
    val laminaSuperficieMm: Double,
    /** Lâmina infiltrada acumulada (mm) */
    val laminaInfiltradaMm: Double
)

data class ResultadoInundacao(
    /** Eficiência de aplicação Ea (%) */
    val eficienciaAplicacao: Double,
    /** Eficiência de requerimento Er (%) */
    val eficienciaRequerimento: Double,
    /** CUC — Coeficiente de Uniformidade de Christiansen (%) */
    val cuc: Double,
    /** DU — Distribution Uniformity (%) */
    val du: Double,
    /** Perdas por percolação profunda (%) */
    val perdaPercolacao: Double,
    /** Perdas por escoamento superficial (%) */
    val perdaEscoamento: Double,
    /** Tempo necessário para encher a bacia (min) */
    val tempoEnchimentoMin: Double,
    /** Tempo ótimo de corte da vazão (min) */
    val tempoCorteOtimoMin: Double,
    /** Lâmina média aplicada (mm) */
    val laminaMediaAplicada: Double,
    /** Lâmina infiltrada ao final (mm) */
    val laminaInfiltradaFinalMm: Double,
    /** Evolução temporal: superfície e infiltração */
    val curvaTempoLamina: List<PontoInundacao>,
    /** Perfil de desempenho longitudinal (mm) — variação devida à declividade residual */
    val perfilLongitudinal: List<Double>,
    /** Resumo textual didático */
    val resumoTextual: String,
    /** Avaliação de desempenho */
    val avaliacao: IndicadoresDesempenho.AvaliacaoDesempenho
)

// ─── Motor de simulação ───────────────────────────────────────────────────────

/**
 * Simulação de irrigação por inundação/bacia (basin irrigation).
 *
 * Modelo:
 *  1. Fase de enchimento: Q0 abastece a bacia; lâmina superficial sobe
 *     até atingir laminaSuperficieMin → bacia "cheia"
 *  2. Fase de infiltração com superfície livre: lâmina superficial decresce
 *     enquanto infiltra por Kostiakov-Lewis
 *  3. Tempo ótimo de corte: calculado para que a lâmina infiltrada = LN
 *     no instante em que a superfície zera (recessão)
 *  4. Se declividade > 0: o tempo de oportunidade varia ligeiramente entre
 *     montante e jusante — calculado via Newton-Raphson
 */
object SimulacaoInundacao {

    private const val PASSO_MIN = 0.5
    private const val N_PONTOS_PERFIL = 20

    fun executar(params: ParametrosInundacao): ResultadoInundacao {
        val qM3Min = params.vazaoEntrada * 0.06   // L/s → m³/min
        val areaM2 = params.areaM2

        // 1. Tempo de enchimento (para atingir lâmina superficial mínima)
        //    V_enchimento = laminaMin × Area → t_ench = V / (Q - taxa_infiltr_inicial)
        //    Simplificação: t_ench = (laminaMin/1000 × Area) / Q [min]
        val volEnchimentoM3 = (params.laminaSuperficieMinMm / 1000.0) * areaM2
        val tempoEnchimentoMin = volEnchimentoM3 / qM3Min

        // 2. Tempo ótimo de corte: quando Z(to) = LN (resolver Kostiakov-Lewis inverso)
        val tempoCorteOtimoMin = KostiakovLewis.tempoParaLamina(
            params.laminaRequerida, params.k, params.a, params.vib
        )

        // Tempo real de corte: menor entre ótimo e disponível
        val tempoCorteRealMin = minOf(tempoCorteOtimoMin, params.tempoAplicacao)

        // 3. Curva temporal de lâmina na superfície e infiltrada
        val curva = mutableListOf<PontoInundacao>()
        var t = 0.0
        while (t <= params.tempoAplicacao + tempoCorteRealMin * 0.5) {
            val tH = t / 60.0
            val zMm = KostiakovLewis.infiltracaoAcumulada(tH, params.k, params.a, params.vib)
            val volEntradaM3 = if (t <= tempoCorteRealMin) qM3Min * t else qM3Min * tempoCorteRealMin
            val laminaAplicadaAteMm = (volEntradaM3 / areaM2) * 1000.0
            val laminaSupMm = (laminaAplicadaAteMm - zMm).coerceAtLeast(0.0)
            curva.add(PontoInundacao(t, laminaSupMm, zMm))
            if (t > tempoCorteRealMin && laminaSupMm <= 0.1) break
            t += PASSO_MIN
        }

        // 4. Lâmina final infiltrada (no tempo de recessão — quando sup = 0)
        val tauFinalH = (curva.lastOrNull { it.laminaSuperficieMm <= 0.1 }?.tempoMinutos
            ?: curva.last().tempoMinutos) / 60.0
        val laminaInfiltradaFinalMm = KostiakovLewis.infiltracaoAcumulada(
            tauFinalH, params.k, params.a, params.vib
        )

        // 5. Lâmina média aplicada
        val volAplicadoM3 = qM3Min * tempoCorteRealMin
        val laminaAplicadaMm = (volAplicadoM3 / areaM2) * 1000.0

        // 6. Perfil longitudinal — com declividade residual, τ varia:
        //    τ_montante > τ_jusante (agua chega primeiro na cabeceira)
        //    Estimativa: variação ≈ 10% da declividade relativa
        val variacaoTauPc = (params.declividade * params.comprimento / (laminaAplicadaMm / 1000.0))
            .coerceIn(0.0, 0.25)
        val tauMedio = tauFinalH * 60.0
        val tauMontante = tauMedio * (1.0 + variacaoTauPc)
        val tauJusante  = tauMedio * (1.0 - variacaoTauPc)
        val perfilMm = IndicadoresDesempenho.perfilLongitudinal(
            tauMontante, tauJusante,
            params.k, params.a, params.vib,
            N_PONTOS_PERFIL
        )

        // 7. Indicadores
        val laminaArmazenadaMm = minOf(laminaInfiltradaFinalMm, params.laminaRequerida)
        val ea = IndicadoresDesempenho.eficienciaAplicacao(laminaArmazenadaMm, laminaAplicadaMm)
        val er = IndicadoresDesempenho.eficienciaRequerimento(perfilMm, params.laminaRequerida)
        val cucVal = if (perfilMm.size >= 2) IndicadoresDesempenho.cuc(perfilMm) else 100.0
        val duVal  = if (perfilMm.size >= 4) IndicadoresDesempenho.du(perfilMm)  else 100.0
        val pp = IndicadoresDesempenho.perdaPercolacao(laminaInfiltradaFinalMm, params.laminaRequerida, laminaAplicadaMm)
        val pe = IndicadoresDesempenho.perdaEscoamento(ea, pp)

        val avaliacao = IndicadoresDesempenho.avaliar(ea, er, cucVal, duVal, laminaInfiltradaFinalMm, params.laminaRequerida)
        val resumo = buildResumo(params, ea, tempoEnchimentoMin, tempoCorteRealMin, tempoCorteOtimoMin, cucVal)

        return ResultadoInundacao(
            eficienciaAplicacao   = ea,
            eficienciaRequerimento = er,
            cuc = cucVal,
            du  = duVal,
            perdaPercolacao = pp,
            perdaEscoamento = pe,
            tempoEnchimentoMin = tempoEnchimentoMin,
            tempoCorteOtimoMin = tempoCorteOtimoMin,
            laminaMediaAplicada  = laminaAplicadaMm,
            laminaInfiltradaFinalMm = laminaInfiltradaFinalMm,
            curvaTempoLamina = curva,
            perfilLongitudinal  = perfilMm,
            resumoTextual = resumo,
            avaliacao = avaliacao
        )
    }

    private fun buildResumo(
        params: ParametrosInundacao,
        ea: Double,
        tempoEnch: Double,
        tempoCorteReal: Double,
        tempoCorteOtimo: Double,
        cuc: Double
    ): String = buildString {
        append("Bacia ${params.comprimento.toInt()} m × ${params.largura.toInt()} m ")
        append("(${(params.areaM2 / 10000.0).let { "${"%.2f".format(it)} ha" }}). ")
        append("Q = ${"%.1f".format(params.vazaoEntrada)} L/s, enchimento em ${"%.0f".format(tempoEnch)} min. ")
        append("Tempo ótimo de corte: ${"%.0f".format(tempoCorteOtimo)} min; ")
        append("aplicado: ${"%.0f".format(tempoCorteReal)} min. ")
        append("Ea = ${ea.toInt()}%, CUC = ${cuc.toInt()}%. ")
        when {
            tempoCorteReal < tempoCorteOtimo * 0.9 ->
                append("Corte prematuro — parte do campo com déficit. Aumente Q ou o tempo de aplicação.")
            ea >= 75 ->
                append("Desempenho satisfatório para LN = ${params.laminaRequerida.toInt()} mm.")
            else ->
                append("Ea abaixo do ideal — ajuste Q ou verifique nivelamento da bacia.")
        }
    }
}
