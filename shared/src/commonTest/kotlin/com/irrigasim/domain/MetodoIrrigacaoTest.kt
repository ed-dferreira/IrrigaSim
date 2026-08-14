package com.irrigasim.domain

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

/**
 * Testes unitários para o enum MetodoIrrigacao.
 */
class MetodoIrrigacaoTest {

    @Test
    fun `SULCO tem nome correto`() {
        assertEquals("Sulco", MetodoIrrigacao.SULCO.nome)
    }

    @Test
    fun `FAIXA tem nome correto`() {
        assertEquals("Faixa (Border)", MetodoIrrigacao.FAIXA.nome)
    }

    @Test
    fun `INUNDACAO tem nome correto`() {
        assertEquals("Inundação", MetodoIrrigacao.INUNDACAO.nome)
    }

    @Test
    fun `fromString aceita sulco minusculo`() {
        assertEquals(MetodoIrrigacao.SULCO, MetodoIrrigacao.fromString("sulco"))
    }

    @Test
    fun `fromString aceita faixa`() {
        assertEquals(MetodoIrrigacao.FAIXA, MetodoIrrigacao.fromString("faixa"))
    }

    @Test
    fun `fromString aceita border`() {
        assertEquals(MetodoIrrigacao.FAIXA, MetodoIrrigacao.fromString("border"))
    }

    @Test
    fun `fromString aceita bacia`() {
        assertEquals(MetodoIrrigacao.INUNDACAO, MetodoIrrigacao.fromString("bacia"))
    }

    @Test
    fun `fromString aceita inundacao`() {
        assertEquals(MetodoIrrigacao.INUNDACAO, MetodoIrrigacao.fromString("inundação"))
    }

    @Test
    fun `fromString falha com valor invalido`() {
        assertFailsWith<IllegalArgumentException> {
            MetodoIrrigacao.fromString("invalido")
        }
    }
}
