package com.irrigasim.data

import com.irrigasim.domain.MetodoIrrigacao
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class RepositorioSimulacoesTest {

    @Test
    fun salvar e listar simulacao() = runTest {
        val repo = RepositorioSimulacoesMemoria()
        val id = repo.salvar(MetodoIrrigacao.FAIXA, "Teste", "{}", "{}")
        assertTrue(id > 0)
        val lista = repo.listar()
        assertEquals(1, lista.size)
        assertEquals("Teste", lista.first().nome)
    }

    @Test
    fun excluir remove simulacao() = runTest {
        val repo = RepositorioSimulacoesMemoria()
        val id = repo.salvar(MetodoIrrigacao.FAIXA, "A", "{}", "{}")
        repo.excluir(id)
        assertTrue(repo.listar().isEmpty())
    }

    @Test
    fun buscarPorId retorna simulacao() = runTest {
        val repo = RepositorioSimulacoesMemoria()
        val id = repo.salvar(MetodoIrrigacao.FAIXA, "B", "{\"k\":45}", "{}")
        val s = repo.buscarPorId(id)
        assertNotNull(s)
        assertEquals(MetodoIrrigacao.FAIXA, s.metodo)
    }
}
