package com.irrigasim.domain.faixas

import com.irrigasim.domain.infiltracao.KostiakovLewis
import kotlin.math.min

/**
 * Motor de simulação completo para irrigação por faixas.
 */
object SimulacaoFaixas {
    private const val TOLERANCIA_RELATIVA = 0.01 // 1%

    fun executar(params: ParametrosFaixa): ResultadoFaixa {
        val qMax = VazaoLimites.qMaxHart(params.declividade, params.manningN)
        val qMaxLs = VazaoLimites.m3MinParaLs(qMax)

        val (curvaAvanco, tempoAvanco) = BalancoVolumetrico.calcularAvanco(params)

        val tauAvancoHoras = tempoAvanco / 60.0
        val laminaInfiltradaAvanco = KostiakovLewis.infiltracaoAcumulada(
            tauAvancoHoras, params.k, params.a, params.vib
        )

        val qMin = VazaoLimites.qMinWalker(
            params.comprimento,
            params.largura,
            params.sigmaZ,
            laminaInfiltradaAvanco,
            params.tempoAplicacao
        )

        val tempoRecessao = RecessaoStrelkoff.tempoRecessaoMin(
            tempoAvanco,
            params.tempoAplicacao,
            params.comprimento,
            params.declividade
        )

        val tempoOportunidadeMedio = TempoOportunidade.calcular(
            params.laminaRequerida,
            params.k,
            params.a,
            params.vib
        ) + tempoRecessao * 0.3

        val volumeAplicadoM3 = VazaoLimites.lsParaM3Min(params.vazaoEntrada) *
            params.tempoAplicacao * params.largura
        val laminaMediaAplicada = (volumeAplicadoM3 / (params.comprimento * params.largura)) * 1000.0

        val laminaArmazenada = KostiakovLewis.infiltracaoAcumulada(
            tempoOportunidadeMedio / 60.0, params.k, params.a, params.vib
        )

        val eficienciaAplicacao = min(100.0, (params.laminaRequerida / laminaMediaAplicada) * 100.0)
        val eficienciaRequerimento = min(100.0, (laminaArmazenada / params.laminaRequerida) * 100.0)
        val perdaPercolacao = ((laminaArmazenada - params.laminaRequerida) / laminaMediaAplicada * 100.0)
            .coerceAtLeast(0.0)
        val perdaEscoamento = (100.0 - eficienciaAplicacao - perdaPercolacao).coerceAtLeast(0.0)

        val (melhorVazao, vazoesTestadas) = if (params.vazoesCandidatas.isNotEmpty()) {
            OtimizadorVazao.melhorEa(params.vazoesCandidatas, params)
        } else {
            null to emptyList()
        }

        val vazaoTotalLs = params.vazaoEntrada * params.largura
        val alertaVazao = params.vazaoDisponivel?.let { vazaoTotalLs > it } ?: false

        val resumo = buildResumo(
            params, eficienciaAplicacao, tempoAvanco, tempoOportunidadeMedio,
            qMaxLs, qMin, alertaVazao
        )

        return ResultadoFaixa(
            eficienciaAplicacao = eficienciaAplicacao,
            eficienciaRequerimento = eficienciaRequerimento,
            perdaPercolacao = perdaPercolacao,
            perdaEscoamento = perdaEscoamento,
            vazaoMaxima = qMax,
            vazaoMinima = qMin,
            tempoAvanco = tempoAvanco,
            tempoOportunidadeMedio = tempoOportunidadeMedio,
            laminaMediaAplicada = laminaMediaAplicada,
            curvaAvanco = curvaAvanco,
            vazoesTestadas = vazoesTestadas,
            melhorVazao = melhorVazao,
            resumoTextual = resumo,
            alertaVazaoExcedida = alertaVazao
        )
    }

    fun dentroTolerancia(esperado: Double, obtido: Double): Boolean {
        if (esperado == 0.0) return obtido == 0.0
        return kotlin.math.abs(esperado - obtido) / kotlin.math.abs(esperado) <= TOLERANCIA_RELATIVA
    }

    private fun buildResumo(
        params: ParametrosFaixa,
        ea: Double,
        ta: Double,
        toMed: Double,
        qMaxLs: Double,
        qMin: Double,
        alerta: Boolean
    ): String = buildString {
        append("Simulação de faixa de ${params.comprimento.toInt()} m × ${params.largura.toInt()} m. ")
        append("Com vazão de ${"%.2f".format(params.vazaoEntrada)} L/s/m por ${params.tempoAplicacao.toInt()} min, ")
        append("a água avança em ${ta.toInt()} min (ta) e o tempo médio de oportunidade é ${toMed.toInt()} min. ")
        append("A eficiência de aplicação Ea é ${"%.1f".format(ea)}%. ")
        append("Limites: Qmáx = ${"%.2f".format(qMaxLs)} L/s/m, Qmín = ${"%.2f".format(qMin)} L/s/m. ")
        when {
            ea >= 75 -> append("Desempenho satisfatório para a lâmina requerida de ${params.laminaRequerida.toInt()} mm.")
            else -> append("Ea abaixo do ideal — considere ajustar vazão ou tempo de aplicação.")
        }
        if (alerta) append(" ⚠ A vazão de projeto excede a disponível na tomada.")
    }
}
