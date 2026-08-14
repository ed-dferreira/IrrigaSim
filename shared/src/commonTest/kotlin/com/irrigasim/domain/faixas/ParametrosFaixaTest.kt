package com.irrigasim.domain.faixas

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class ParametrosFaixaTest {

    private fun paramsValidos() = ParametrosFaixa(
        k = 45.0, a = 0.55, vib = 2.0,
        comprimento = 400.0, largura = 20.0,
        declividade = 0.001, manningN = 0.04,
        laminaRequerida = 50.0,
        vazaoEntrada = 14.548,
        tempoAplicacao = 120.0
    )

    @Test
    fun cria parametros validos() {
        val p = paramsValidos()
        assertEquals(400.0, p.comprimento)
        assertEquals(14.548, p.vazaoEntrada)
    }

    @Test
    fun falha com comprimento zero() {
        assertFailsWith<IllegalArgumentException> {
            paramsValidos().copy(comprimento = 0.0)
        }
    }

    @Test
    fun falha com a fora do intervalo() {
        assertFailsWith<IllegalArgumentException> {
            paramsValidos().copy(a = 1.5)
        }
    }

    @Test
    fun exemploReferencia tem vazoes candidatas() {
        val p = ParametrosFaixa.exemploReferencia()
        assertTrue(p.vazoesCandidatas.isNotEmpty())
        assertEquals(14.548, p.vazaoEntrada, 0.001)
    }
}
