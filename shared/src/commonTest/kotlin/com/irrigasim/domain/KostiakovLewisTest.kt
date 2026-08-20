package com.irrigasim.domain.infiltracao

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class KostiakovLewisTest {

    @Test
    fun `infiltracaoAcumulada retorna zero para tempo zero`() {
        assertEquals(0.0, KostiakovLewis.infiltracaoAcumulada(0.0, 45.0, 0.55, 2.0))
    }

    @Test
    fun `infiltracaoAcumulada segue formula k tau a mais VIB tau`() {
        // Z(1h) = 45·1^0.55 + 2·1 = 47 mm (fonte: álgebra independente)
        assertEquals(47.0, KostiakovLewis.infiltracaoAcumulada(1.0, 45.0, 0.55, 2.0), 0.01)
    }

    @Test
    fun `infiltracaoAcumulada aumenta com tempo`() {
        val z1 = KostiakovLewis.infiltracaoAcumulada(0.5, 45.0, 0.55, 2.0)
        val z2 = KostiakovLewis.infiltracaoAcumulada(1.0, 45.0, 0.55, 2.0)
        assertTrue(z2 > z1)
    }

    @Test
    fun `infiltracaoAcumulada falha com k negativo`() {
        assertFailsWith<IllegalArgumentException> {
            KostiakovLewis.infiltracaoAcumulada(1.0, -1.0, 0.55, 2.0)
        }
    }

    @Test
    fun `taxaInfiltracao e positiva para tempo positivo`() {
        val taxa = KostiakovLewis.taxaInfiltracao(1.0, 45.0, 0.55, 2.0)
        assertTrue(taxa > 0)
    }

    @Test
    fun `gerarPerfil produz pontos crescentes`() {
        val perfil = KostiakovLewis.gerarPerfil(45.0, 0.55, 2.0, 60.0, 10.0)
        assertTrue(perfil.size >= 2)
        for (i in 1 until perfil.size) {
            assertTrue(perfil[i].laminaMm >= perfil[i - 1].laminaMm)
        }
    }
}
