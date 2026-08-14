package com.irrigasim.domain.faixas

import com.irrigasim.domain.infiltracao.KostiakovLewis
import kotlin.math.abs
import kotlin.math.pow

/**
 * Tempo de oportunidade médio via Newton-Raphson.
 * Resolve Z(to) = lâmina alvo para obter to médio ao longo da faixa.
 */
object TempoOportunidade {
    private const val MAX_ITER = 100
    private const val TOLERANCIA = 1e-6

    /**
     * Calcula tempo de oportunidade (horas) dado lâmina alvo infiltrada.
     */
    fun calcular(laminaAlvoMm: Double, k: Double, a: Double, vib: Double): Double {
        if (laminaAlvoMm <= 0) return 0.0
        var tau = 0.5 // chute inicial em horas
        repeat(MAX_ITER) {
            val f = KostiakovLewis.infiltracaoAcumulada(tau, k, a, vib) - laminaAlvoMm
            if (abs(f) < TOLERANCIA) return tau * 60.0 // retorna minutos
            val df = KostiakovLewis.taxaInfiltracao(tau, k, a, vib)
            if (df == 0.0) return tau * 60.0
            tau -= f / df
            if (tau < 0) tau = 0.001
        }
        return tau * 60.0
    }
}

/**
 * Balanço volumétrico iterativo para avanço da frente de água (σz, r).
 */
object BalancoVolumetrico {
    private const val PASSO_TEMPO_MIN = 1.0

    fun calcularAvanco(params: ParametrosFaixa): Pair<List<PontoAvanco>, Double> {
        val curva = mutableListOf<PontoAvanco>()
        var t = 0.0
        var x = 0.0
        val qM3MinPorMetro = VazaoLimites.lsParaM3Min(params.vazaoEntrada)
        val L = params.comprimento
        val sigma = params.sigmaZ
        val r = params.expoenteFormaR

        curva.add(PontoAvanco(0.0, 0.0))

        while (x < L && t < params.tempoAplicacao * 3) {
            t += PASSO_TEMPO_MIN
            val volumeEntrada = qM3MinPorMetro * t * params.largura
            // Estimativa de x pelo balanço: V = σ·y·x·W + infiltração acumulada·x·W
            val tauHoras = t / 60.0
            val zMm = KostiakovLewis.infiltracaoAcumulada(tauHoras, params.k, params.a, params.vib)
            val zM = zMm / 1000.0
            val profundidadeSuperficial = sigma * (x / L).pow(r) * 0.05
            val volArmazenamento = sigma * profundidadeSuperficial * x * params.largura
            val volInfiltracao = zM * x * params.largura
            val xNovo = (volumeEntrada - volInfiltracao) / (sigma * 0.05 * params.largura + 1e-9)
            x = xNovo.coerceIn(0.0, L)
            curva.add(PontoAvanco(t, x))
            if (x >= L) break
        }

        val tempoAvanco = curva.lastOrNull { it.distanciaMetros >= L * 0.99 }?.tempoMinutos
            ?: curva.last().tempoMinutos
        return curva to tempoAvanco
    }
}

/**
 * Recessão via método algébrico de Strelkoff (1977) — simplificado.
 */
object RecessaoStrelkoff {
    fun tempoRecessaoMin(
        tempoAvancoMin: Double,
        tempoAplicacaoMin: Double,
        comprimento: Double,
        declividade: Double
    ): Double {
        val razao = tempoAplicacaoMin / tempoAvancoMin.coerceAtLeast(1.0)
        val fator = 1.0 + 0.1 * declividade * 1000.0
        return (tempoAplicacaoMin - tempoAvancoMin).coerceAtLeast(0.0) * fator * (1.0 + 0.05 * razao)
    }
}
