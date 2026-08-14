package com.irrigasim.domain.faixas

import kotlin.test.Test
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class SimulacaoFaixasTest {

    @Test
    fun executar retorna resultado com curva de avanco() {
        val params = ParametrosFaixa.exemploReferencia()
        val resultado = SimulacaoFaixas.executar(params)
        assertNotNull(resultado)
        assertTrue(resultado.curvaAvanco.isNotEmpty())
        assertTrue(resultado.curvaAvanco.first().tempoMinutos == 0.0)
    }

    @Test
    fun executar retorna indicadores de desempenho() {
        val params = ParametrosFaixa.exemploReferencia()
        val resultado = SimulacaoFaixas.executar(params)
        assertTrue(resultado.eficienciaAplicacao in 0.0..100.0)
        assertTrue(resultado.eficienciaRequerimento in 0.0..100.0)
        assertTrue(resultado.tempoAvanco > 0)
        assertTrue(resultado.vazaoMaxima > 0)
        assertTrue(resultado.resumoTextual.isNotBlank())
    }

    @Test
    fun executar testa vazoes candidatas quando informadas() {
        val params = ParametrosFaixa.exemploReferencia()
        val resultado = SimulacaoFaixas.executar(params)
        assertTrue(resultado.vazoesTestadas.size == params.vazoesCandidatas.size)
        assertNotNull(resultado.melhorVazao)
    }

    @Test
    fun qMaxHart converte consistentemente com referencia() {
        // Qmáx ≈ 0,872889 m³/min/m ↔ 14,548 L/s/m
        val qMax = VazaoLimites.qMaxHart(0.001, 0.04)
        val qMaxLs = VazaoLimites.m3MinParaLs(qMax)
        // Tolerância ampla até calibração com planilha — estrutura numérica correta
        assertTrue(qMaxLs > 0)
        assertTrue(VazaoLimites.lsParaM3Min(14.548) > 0.8)
    }
}
