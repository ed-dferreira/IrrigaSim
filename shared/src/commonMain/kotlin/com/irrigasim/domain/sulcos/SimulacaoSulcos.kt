package com.irrigasim.domain.sulcos

import com.irrigasim.domain.indicadores.IndicadoresDesempenho
import com.irrigasim.domain.infiltracao.KostiakovLewis
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sqrt

// ─── Modelos de resultado ─────────────────────────────────────────────────────

data class PontoAvancoSulco(val tempoMinutos: Double, val distanciaMetros: Double)

data class ResultadoSulco(
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
    /** Vazão máxima não erosiva Qmáx (L/s/sulco) */
    val vazaoMaxima: Double,
    /** Tempo de avanço ta (min) */
    val tempoAvanco: Double,
    /** Tempo médio de oportunidade τ̄ (min) */
    val tempoOportunidadeMedio: Double,
    /** Lâmina média aplicada (mm) */
    val laminaMediaAplicada: Double,
    /** Lâmina média infiltrada (mm) */
    val laminaMediaInfiltrada: Double,
    /** Perfil longitudinal de lâminas infiltradas (mm), da cabeceira à extremidade */
    val perfilLongitudinal: List<Double>,
    /** Curva de avanço da frente de água */
    val curvaAvanco: List<PontoAvancoSulco>,
    /** Resumo textual didático */
    val resumoTextual: String,
    /** Avaliação de desempenho */
    val avaliacao: IndicadoresDesempenho.AvaliacaoDesempenho
)

// ─── Motor de simulação ───────────────────────────────────────────────────────

/**
 * Simulação de irrigação por sulcos — Balanço de Volume + Kostiakov-Lewis.
 *
 * Abordagem:
 *  1. Verifica se a vazão está dentro dos limites hidráulicos (Qmáx não erosiva)
 *  2. Calcula a curva de avanço da frente d'água via balanço volumétrico iterativo
 *  3. Estima o tempo de recessão pelo método de Strelkoff simplificado
 *  4. Gera o perfil longitudinal de lâmina infiltrada com variação linear de τ
 *  5. Calcula Ea, Er, CUC, DU e perdas
 *
 * Referências:
 *  - Walker & Skogerboe (1987) — Surface Irrigation: Theory and Practice
 *  - Clemmens et al. (2007) — WinSRFR User Manual (USDA-ARS)
 */
object SimulacaoSulcos {

    private const val PASSO_TEMPO_MIN = 0.5  // passo de integração (min)
    private const val N_PONTOS_PERFIL = 20   // pontos para o perfil longitudinal

    // ────────────────────────────────────────────────────────────────────────
    // Ponto de entrada
    // ────────────────────────────────────────────────────────────────────────

    fun executar(params: ParametrosSulco): ResultadoSulco {
        val qLsPorSulco = params.vazaoEntrada
        val qM3Min = qLsPorSulco * 0.06          // L/s → m³/min
        val qM3s  = qLsPorSulco / 1000.0         // L/s → m³/s

        // 1. Qmáx hidráulica não erosiva (Manning + critério de Froude)
        val qMax = calcularQMaxSulco(params)

        // 2. Curva de avanço
        val (curvaAvanco, tempoAvanco) = calcularAvancoSulco(params, qM3Min)

        // 3. Tempo de recessão (simplificado Strelkoff)
        val tempoRecessaoMin = calcularTempoRecessao(
            tempoAvancoMin = tempoAvanco,
            tempoAplicacaoMin = params.tempoAplicacao,
            declividade = params.declividade
        )

        // 4. Tempos de oportunidade (variação linear: máximo na cabeceira, mínimo na extremidade)
        //    τ_montante = ti − 0 + tr (cabeceira sempre fica mais tempo molhada)
        //    τ_jusante  = ti − ta + tr×f (extremidade recebeu água por menos tempo)
        val tauMontanteMin = params.tempoAplicacao + tempoRecessaoMin
        val tauJusanteMin  = (params.tempoAplicacao - tempoAvanco + tempoRecessaoMin * 0.3)
            .coerceAtLeast(0.0)
        val tauMedioMin = (tauMontanteMin + tauJusanteMin) / 2.0

        // 5. Perfil longitudinal de lâmina infiltrada
        val perfilMm = IndicadoresDesempenho.perfilLongitudinal(
            tauMontanteMin, tauJusanteMin,
            params.k, params.a, params.vib,
            N_PONTOS_PERFIL
        )
        val laminaMediaInfiltradaMm = perfilMm.average()

        // 6. Lâmina média aplicada
        //    V_aplicado = Q0 × ti (volume por unidade de comprimento × espaçamento)
        val volAplicadoM3 = qM3Min * params.tempoAplicacao   // m³/sulco
        val areaM2 = params.comprimento * params.espacamento
        val laminaAplicadaMm = (volAplicadoM3 / areaM2) * 1000.0

        // 7. Indicadores
        val laminaArmazenadaMm = min(laminaMediaInfiltradaMm, params.laminaRequerida)
        val ea = IndicadoresDesempenho.eficienciaAplicacao(laminaArmazenadaMm, laminaAplicadaMm)
        val er = IndicadoresDesempenho.eficienciaRequerimento(perfilMm, params.laminaRequerida)
        val cucVal = IndicadoresDesempenho.cuc(perfilMm)
        val duVal = IndicadoresDesempenho.du(perfilMm)
        val pp = IndicadoresDesempenho.perdaPercolacao(laminaMediaInfiltradaMm, params.laminaRequerida, laminaAplicadaMm)
        val pe = IndicadoresDesempenho.perdaEscoamento(ea, pp)

        val avaliacao = IndicadoresDesempenho.avaliar(ea, er, cucVal, duVal, laminaMediaInfiltradaMm, params.laminaRequerida)

        val resumo = buildResumo(params, ea, tempoAvanco, tauMedioMin, qMax, cucVal, duVal)

        return ResultadoSulco(
            eficienciaAplicacao  = ea,
            eficienciaRequerimento = er,
            cuc = cucVal,
            du  = duVal,
            perdaPercolacao = pp,
            perdaEscoamento = pe,
            vazaoMaxima = qMax,
            tempoAvanco = tempoAvanco,
            tempoOportunidadeMedio = tauMedioMin,
            laminaMediaAplicada  = laminaAplicadaMm,
            laminaMediaInfiltrada = laminaMediaInfiltradaMm,
            perfilLongitudinal  = perfilMm,
            curvaAvanco = curvaAvanco,
            resumoTextual = resumo,
            avaliacao = avaliacao
        )
    }

    // ────────────────────────────────────────────────────────────────────────
    // Vazão máxima não erosiva — Critério de Hart (1970)
    // Q_max = (1/n) · A(y_c) · R(y_c)^(2/3) · √S
    // com restrição adicional de Froude < 0.6 para evitar erosão
    // ────────────────────────────────────────────────────────────────────────

    fun calcularQMaxSulco(params: ParametrosSulco): Double {
        // Profundidade crítica aproximada (seção triangular simplificada)
        // y_c = (Q²/(g·m²))^(1/5) para seção triangular
        // Para seção trapezoidal: solução iterativa
        val g = 9.81
        val froudeLimite = 0.6
        val nIter = 50
        var yTest = 0.05
        var qMax = 0.0
        repeat(nIter) {
            val a = params.areaSecao(yTest)
            val t = params.base + 2 * params.taludes * yTest
            val fr = if (a > 0 && t > 0) sqrt(params.vazaoEntrada / 1000.0 / a / sqrt(g * a / t)) else 1.0
            val qManning = (1.0 / params.manningN) * a *
                params.raioHidraulico(yTest).pow(2.0 / 3.0) * sqrt(params.declividade.coerceAtLeast(1e-5))
            qMax = qManning * 1000.0 // m³/s → L/s
            if (fr > froudeLimite) yTest *= 0.9 else yTest *= 1.05
            if (yTest > 1.0) yTest = 1.0
        }
        return qMax.coerceAtLeast(params.vazaoEntrada)
    }

    // ────────────────────────────────────────────────────────────────────────
    // Balanço volumétrico — Fase de avanço
    // V_entrada(t) = V_superficie(t) + V_infiltrado(t)
    // Q0 · t = σz · y0 · x(t) + Z(τ_med) · x(t)
    // ────────────────────────────────────────────────────────────────────────

    private fun calcularAvancoSulco(
        params: ParametrosSulco,
        qM3Min: Double
    ): Pair<List<PontoAvancoSulco>, Double> {
        val curva = mutableListOf(PontoAvancoSulco(0.0, 0.0))
        var t = 0.0
        var x = 0.0
        val L = params.comprimento
        val sigma = params.sigmaZ

        // Profundidade normal aproximada para armazenamento superficial
        val qM3s = qM3Min / 60.0
        val y0 = params.profundidadeNormal(qM3s).coerceAtLeast(0.01)
        val areaSecao0 = params.areaSecao(y0)

        while (x < L && t < params.tempoAplicacao * 4) {
            t += PASSO_TEMPO_MIN
            val volEntrada = qM3Min * t

            // Lâmina infiltrada acumulada na frente (τ ≈ t/2 para média)
            val tauMedHoras = (t / 2.0) / 60.0
            val zMm = KostiakovLewis.infiltracaoAcumulada(tauMedHoras, params.k, params.a, params.vib)
            val zM = zMm / 1000.0

            // Balanço: V_entrada = sigma * A_sulco/W * x + z * x * W (por sulco)
            // Simplificando: x = V_entrada / (sigma * y0 + z)
            val denominador = (sigma * areaSecao0 / params.espacamento + zM * params.espacamento)
                .coerceAtLeast(1e-9)
            val xNovo = (volEntrada / denominador).coerceIn(0.0, L)
            x = xNovo
            curva.add(PontoAvancoSulco(t, x))
            if (x >= L) break
        }

        val tempoAvanco = curva.lastOrNull { it.distanciaMetros >= L * 0.99 }?.tempoMinutos
            ?: curva.last().tempoMinutos
        return curva to tempoAvanco
    }

    // ────────────────────────────────────────────────────────────────────────
    // Recessão — método algébrico de Strelkoff (simplificado)
    // ────────────────────────────────────────────────────────────────────────

    private fun calcularTempoRecessao(
        tempoAvancoMin: Double,
        tempoAplicacaoMin: Double,
        declividade: Double
    ): Double {
        val razao = tempoAplicacaoMin / tempoAvancoMin.coerceAtLeast(1.0)
        val fatorDecl = 1.0 + 0.15 * declividade * 1000.0
        return (tempoAplicacaoMin - tempoAvancoMin).coerceAtLeast(0.0) *
            fatorDecl * (1.0 + 0.05 * razao)
    }

    // ────────────────────────────────────────────────────────────────────────
    // Resumo textual didático
    // ────────────────────────────────────────────────────────────────────────

    private fun buildResumo(
        params: ParametrosSulco,
        ea: Double,
        tempoAvanco: Double,
        tauMedio: Double,
        qMax: Double,
        cuc: Double,
        du: Double
    ): String = buildString {
        append("Simulação de sulcos: L = ${params.comprimento.toInt()} m, ")
        append("espaçamento = ${"%.2f".format(params.espacamento)} m. ")
        append("Q = ${"%.2f".format(params.vazaoEntrada)} L/s/sulco por ${params.tempoAplicacao.toInt()} min. ")
        append("Avanço em ${tempoAvanco.toInt()} min, τ̄ = ${tauMedio.toInt()} min. ")
        append("Ea = ${ea.toInt()}%, CUC = ${cuc.toInt()}%, DU = ${du.toInt()}%. ")
        append("Qmáx = ${"%.1f".format(qMax)} L/s/sulco. ")
        when {
            ea >= 75 && cuc >= 80 -> append("Desempenho satisfatório para LN = ${params.laminaRequerida.toInt()} mm.")
            ea < 65               -> append("Ea baixa — reduza a vazão ou o tempo de aplicação.")
            cuc < 75              -> append("Distribuição irregular — verifique a declividade e espaçamento.")
            else                  -> append("Desempenho aceitável, com margem de melhoria.")
        }
    }
}
