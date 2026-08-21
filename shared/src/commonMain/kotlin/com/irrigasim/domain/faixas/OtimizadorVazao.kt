package com.irrigasim.domain.faixas

/**
 * Seleciona a vazão candidata com maior Ea entre as testadas.
 */
object OtimizadorVazao {
    fun melhorEa(
        vazoesCandidatas: List<Double>,
        params: ParametrosFaixa
    ): Pair<Double, List<ResultadoVazaoTestada>> {
        if (vazoesCandidatas.isEmpty()) return Pair(params.vazaoEntrada, emptyList())

        val resultados = vazoesCandidatas.map { q ->
            val p = params.copy(vazaoEntrada = q, vazoesCandidatas = emptyList())
            val r = SimulacaoFaixas.executar(p)
            ResultadoVazaoTestada(
                vazaoLsPorMetro = q,
                tempoAvancoMin = r.tempoAvanco,
                tempoOportunidadeMedioMin = r.tempoOportunidadeMedio,
                eficienciaAplicacao = r.eficienciaAplicacao
            )
        }

        val melhor = resultados.maxByOrNull { it.eficienciaAplicacao }
        return Pair(melhor?.vazaoLsPorMetro ?: params.vazaoEntrada, resultados)
    }
}
