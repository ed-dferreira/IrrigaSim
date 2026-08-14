package com.irrigasim.domain.infiltracao

import kotlin.math.abs
import kotlin.math.pow

/**
 * Infiltração acumulada pelo modelo Kostiakov-Lewis:
 * Z(τ) = k · τ^a + VIB · τ
 *
 * @param tauHoras tempo de oportunidade em horas
 * @param k coeficiente Kostiakov (mm/h^a)
 * @param a expoente de infiltração (0 < a < 1)
 * @param vib taxa de infiltração básica VIB (mm/h)
 * @return lâmina infiltrada acumulada em mm
 */
object KostiakovLewis {
    fun infiltracaoAcumulada(tauHoras: Double, k: Double, a: Double, vib: Double): Double {
        require(k >= 0) { "k deve ser não negativo" }
        require(a in 0.0..1.0) { "a deve estar entre 0 e 1" }
        require(vib >= 0) { "VIB deve ser não negativo" }
        require(tauHoras >= 0) { "τ deve ser não negativo" }
        if (tauHoras == 0.0) return 0.0
        return k * tauHoras.pow(a) + vib * tauHoras
    }

    /** Taxa instantânea de infiltração f(τ) = k·a·τ^(a-1) + VIB em mm/h */
    fun taxaInfiltracao(tauHoras: Double, k: Double, a: Double, vib: Double): Double {
        if (tauHoras <= 0) return Double.POSITIVE_INFINITY
        return k * a * tauHoras.pow(a - 1) + vib
    }

    /**
     * Calcula o tempo de oportunidade (em minutos) necessário para infiltrar uma dada lâmina (mm).
     * Utiliza método Newton-Raphson híbrido com bisseção para garantir convergência.
     */
    fun tempoParaLamina(laminaMm: Double, k: Double, a: Double, vib: Double): Double {
        if (laminaMm <= 0.0) return 0.0
        var tMin = 0.0
        var tMax = 100.0 // horas (chute inicial grande)
        while (infiltracaoAcumulada(tMax, k, a, vib) < laminaMm) {
            tMax *= 2.0
        }

        var tauH = (tMin + tMax) / 2.0
        val tol = 1e-6
        val maxIter = 100

        for (i in 0 until maxIter) {
            val z = infiltracaoAcumulada(tauH, k, a, vib)
            val diff = z - laminaMm
            if (abs(diff) < tol) break

            val dz = taxaInfiltracao(tauH, k, a, vib)
            if (dz > 0 && dz.isFinite()) {
                val nextTau = tauH - diff / dz
                if (nextTau in tMin..tMax) {
                    tauH = nextTau
                } else {
                    if (diff > 0) tMax = tauH else tMin = tauH
                    tauH = (tMin + tMax) / 2.0
                }
            } else {
                if (diff > 0) tMax = tauH else tMin = tauH
                tauH = (tMin + tMax) / 2.0
            }
        }
        return tauH * 60.0 // converte horas para minutos
    }

    data class PontoInfiltracao(val tempoMinutos: Double, val laminaMm: Double)

    fun gerarPerfil(
        k: Double,
        a: Double,
        vib: Double,
        tempoMaximoMinutos: Double,
        passoMinutos: Double = 5.0
    ): List<PontoInfiltracao> {
        require(tempoMaximoMinutos > 0)
        val pontos = mutableListOf<PontoInfiltracao>()
        var t = 0.0
        while (t <= tempoMaximoMinutos) {
            val lamina = infiltracaoAcumulada(t / 60.0, k, a, vib)
            pontos.add(PontoInfiltracao(t, lamina))
            t += passoMinutos
        }
        return pontos
    }
}
