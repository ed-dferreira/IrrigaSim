package com.irrigasim.domain.faixas

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class OtimizadorVazaoTest {

    @Test
    fun melhorEa seleciona vazao com maior Ea() {
        val params = ParametrosFaixa.exemploReferencia().copy(
            vazoesCandidatas = listOf(8.0, 14.548, 20.0)
        )
        val (melhor, resultados) = OtimizadorVazao.melhorEa(params.vazoesCandidatas, params)
        assertEquals(3, resultados.size)
        val maxEa = resultados.maxOf { it.eficienciaAplicacao }
        assertEquals(maxEa, resultados.first { it.vazaoLsPorMetro == melhor }.eficienciaAplicacao, 0.001)
    }

    @Test
    fun melhorEa retorna vazao atual quando lista vazia() {
        val params = ParametrosFaixa.exemploReferencia().copy(vazoesCandidatas = emptyList())
        val (melhor, resultados) = OtimizadorVazao.melhorEa(emptyList(), params)
        assertEquals(params.vazaoEntrada, melhor)
        assertTrue(resultados.isEmpty())
    }
}
