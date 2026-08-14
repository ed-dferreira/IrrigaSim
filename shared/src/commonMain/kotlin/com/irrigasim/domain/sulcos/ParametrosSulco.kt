package com.irrigasim.domain.sulcos

import kotlin.math.pow
import kotlin.math.sqrt

/**
 * Parâmetros para simulação de irrigação por sulcos (furrow).
 *
 * Geometria do sulco: seção transversal trapezoidal
 *   A(y) = (b + m·y) · y
 *   P(y) = b + 2·y·√(1 + m²)
 *   T(y) = b + 2·m·y   (largura na superfície livre)
 *
 * onde y = profundidade d'água (m), b = base (m), m = taludes (H:V).
 *
 * Unidades do sistema:
 *   - Comprimento: metros (m)
 *   - Vazão: litros por segundo (L/s) — por sulco individual
 *   - Tempo: minutos (min)
 *   - Lâmina: milímetros (mm)
 *   - Declividade: fração (ex.: 0.001 = 0,1%)
 */
data class ParametrosSulco(
    // ── Kostiakov-Lewis ──────────────────────────────────────────────────────
    /** Coeficiente k de Kostiakov (mm/h^a) */
    val k: Double,
    /** Expoente a de Kostiakov (0 < a < 1) */
    val a: Double,
    /** Taxa de infiltração básica VIB (mm/h) */
    val vib: Double,

    // ── Geometria do sulco ───────────────────────────────────────────────────
    /** Comprimento do sulco (m) */
    val comprimento: Double,
    /** Espaçamento entre sulcos (m) — define a largura de influência por sulco */
    val espacamento: Double,
    /** Declividade longitudinal (m/m) — ex.: 0.001 = 0,1% */
    val declividade: Double,
    /** Base da seção trapezoidal b (m) — use 0 para seção triangular */
    val base: Double = 0.0,
    /** Taludes m (H:V) — ex.: 1.0 = 45°, 0 = retangular */
    val taludes: Double = 1.0,
    /** Rugosidade de Manning n */
    val manningN: Double = 0.04,

    // ── Manejo ───────────────────────────────────────────────────────────────
    /** Lâmina líquida requerida LN (mm) */
    val laminaRequerida: Double,
    /** Vazão de entrada por sulco Q0 (L/s/sulco) */
    val vazaoEntrada: Double,
    /** Tempo de aplicação / corte de vazão ti (min) */
    val tempoAplicacao: Double,

    // ── Avançado ─────────────────────────────────────────────────────────────
    /** Fator de forma de armazenamento superficial σz (adim.) */
    val sigmaZ: Double = 0.77,
    /** Expoente de forma do perfil r (adim.) */
    val expoenteFormaR: Double = 0.6,
    /** Vazões candidatas para otimização (L/s/sulco), opcional */
    val vazoesCandidatas: List<Double> = emptyList()
) {
    init {
        require(comprimento > 0) { "Comprimento deve ser positivo" }
        require(espacamento > 0) { "Espaçamento deve ser positivo" }
        require(declividade >= 0) { "Declividade não pode ser negativa" }
        require(manningN > 0) { "Manning n deve ser positivo" }
        require(k >= 0) { "k deve ser não negativo" }
        require(a in 0.0..1.0) { "a deve estar entre 0 e 1" }
        require(vib >= 0) { "VIB deve ser não negativo" }
        require(vazaoEntrada > 0) { "Vazão deve ser positiva" }
        require(tempoAplicacao > 0) { "Tempo de aplicação deve ser positivo" }
        require(laminaRequerida > 0) { "Lâmina requerida deve ser positiva" }
        require(base >= 0) { "Base b deve ser não negativa" }
        require(taludes >= 0) { "Taludes m devem ser não negativos" }
    }

    val declividadePercentual: Double get() = declividade * 100.0

    // ── Geometria hidráulica ─────────────────────────────────────────────────

    /** Área da seção transversal A(y) em m² */
    fun areaSecao(y: Double): Double = (base + taludes * y) * y

    /** Perímetro molhado P(y) em m */
    fun perimetroMolhado(y: Double): Double = base + 2 * y * sqrt(1 + taludes.pow(2))

    /** Raio hidráulico R(y) = A/P em m */
    fun raioHidraulico(y: Double): Double {
        val p = perimetroMolhado(y)
        return if (p == 0.0) 0.0 else areaSecao(y) / p
    }

    /**
     * Profundidade normal y0 (m) para a vazão Q em m³/s via Manning.
     * Resolve numericamente por bisseção: Q = (1/n)·A·R^(2/3)·√S
     */
    fun profundidadeNormal(qM3s: Double): Double {
        if (qM3s <= 0) return 0.0
        var yMin = 0.0001
        var yMax = 2.0
        repeat(60) {
            val yMid = (yMin + yMax) / 2.0
            val qMid = (1.0 / manningN) * areaSecao(yMid) *
                raioHidraulico(yMid).pow(2.0 / 3.0) * sqrt(declividade)
            if (qMid < qM3s) yMin = yMid else yMax = yMid
        }
        return (yMin + yMax) / 2.0
    }

    companion object {
        /** Caso de referência: sulco triangular típico do Cerrado */
        fun exemploReferencia() = ParametrosSulco(
            k = 30.0, a = 0.50, vib = 3.0,
            comprimento = 200.0, espacamento = 0.75,
            declividade = 0.002, base = 0.0, taludes = 1.2,
            manningN = 0.025,
            laminaRequerida = 40.0, vazaoEntrada = 0.5,
            tempoAplicacao = 90.0,
            sigmaZ = 0.77, expoenteFormaR = 0.6,
            vazoesCandidatas = listOf(0.3, 0.4, 0.5, 0.6, 0.7, 0.8)
        )
    }
}
