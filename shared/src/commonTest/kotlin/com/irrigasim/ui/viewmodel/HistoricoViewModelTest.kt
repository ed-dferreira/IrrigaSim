package com.irrigasim.ui.viewmodel

import com.irrigasim.domain.CenarioSalvo
import com.irrigasim.domain.MetodoIrrigacao
import com.irrigasim.domain.Parametros
import com.irrigasim.domain.Resultado
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class HistoricoViewModelTest {

    @Test
    fun listaDeCenariosIniciaVazia() = runTest {
        val vm = HistoricoViewModel(scope = backgroundScope)

        assertTrue(vm.state.value.cenarios.isEmpty())
    }

    @Test
    fun salvarCenarioAdicionaNaListaERetornaOCenarioCriado() = runTest {
        val vm = HistoricoViewModel(scope = backgroundScope)

        val salvo = vm.salvarCenario(
            titulo = "Sulco 100m",
            metodo = MetodoIrrigacao.SULCO,
            parametros = Parametros(comprimento = 100.0),
            resultado = Resultado(
                eficiencia = 80.0,
                laminaMedia = 50.0,
                tempoAvanco = 40.0,
                perdaPercolacao = 12.0,
                perdaEscoamento = 8.0
            )
        )

        assertEquals(1, vm.state.value.cenarios.size)
        assertEquals(salvo, vm.state.value.cenarios.first())
        assertEquals("Sulco 100m", salvo.titulo)
        assertEquals(MetodoIrrigacao.SULCO, salvo.metodo)
        assertEquals(100.0, salvo.parametros.comprimento)
        assertEquals(80.0, salvo.resultado.eficiencia)
    }

    @Test
    fun idsGeradosSaoSequenciaisConformeTamanhoDaLista() = runTest {
        val vm = HistoricoViewModel(scope = backgroundScope)

        val primeiro = vm.salvarCenario("A", MetodoIrrigacao.SULCO, Parametros(comprimento = 100.0), Resultado(eficiencia = 80.0, laminaMedia = 50.0, tempoAvanco = 40.0, perdaPercolacao = 6.0, perdaEscoamento = 4.0))
        val segundo = vm.salvarCenario("B", MetodoIrrigacao.FAIXA, Parametros(comprimento = 150.0), Resultado(eficiencia = 70.0, laminaMedia = 45.0, tempoAvanco = 35.0, perdaPercolacao = 8.0, perdaEscoamento = 5.0))

        assertEquals("cenario_1_100", primeiro.id)
        assertEquals("cenario_2_150", segundo.id)
    }

    @Test
    fun excluirCenarioRemoveSomenteOCenarioAlvo() = runTest {
        val vm = HistoricoViewModel(scope = backgroundScope)
        val a = vm.salvarCenario("A", MetodoIrrigacao.SULCO, Parametros(comprimento = 100.0), Resultado(eficiencia = 80.0, laminaMedia = 50.0, tempoAvanco = 40.0, perdaPercolacao = 6.0, perdaEscoamento = 4.0))
        val b = vm.salvarCenario("B", MetodoIrrigacao.FAIXA, Parametros(comprimento = 150.0), Resultado(eficiencia = 70.0, laminaMedia = 45.0, tempoAvanco = 35.0, perdaPercolacao = 8.0, perdaEscoamento = 5.0))

        vm.excluirCenario(a.id)

        assertEquals(listOf(b), vm.state.value.cenarios)
    }

    @Test
    fun excluirIdInexistenteNaoAlteraLista() = runTest {
        val vm = HistoricoViewModel(scope = backgroundScope)
        vm.salvarCenario("A", MetodoIrrigacao.SULCO, Parametros(comprimento = 100.0), Resultado(eficiencia = 80.0, laminaMedia = 50.0, tempoAvanco = 40.0, perdaPercolacao = 6.0, perdaEscoamento = 4.0))

        vm.excluirCenario("id_que_nao_existe")

        assertEquals(1, vm.state.value.cenarios.size)
    }

    @Test
    fun salvarAposExclusoesMantemOrdemEIdsUnicos() = runTest {
        // Given: dois cenários salvos e o primeiro excluído
        val vm = HistoricoViewModel(scope = backgroundScope)
        val a = vm.salvarCenario("A", MetodoIrrigacao.SULCO, Parametros(comprimento = 100.0), Resultado(eficiencia = 80.0, laminaMedia = 50.0, tempoAvanco = 40.0, perdaPercolacao = 6.0, perdaEscoamento = 4.0))
        val b = vm.salvarCenario("B", MetodoIrrigacao.FAIXA, Parametros(comprimento = 150.0), Resultado(eficiencia = 70.0, laminaMedia = 45.0, tempoAvanco = 35.0, perdaPercolacao = 8.0, perdaEscoamento = 5.0))
        vm.excluirCenario(a.id)

        // When: um novo cenário é salvo depois da exclusão
        val c = vm.salvarCenario("C", MetodoIrrigacao.INUNDACAO, Parametros(comprimento = 120.0), Resultado(eficiencia = 65.0, laminaMedia = 55.0, tempoAvanco = 25.0, perdaPercolacao = 9.0, perdaEscoamento = 3.0))

        // Then: a lista reflete exatamente B e C, na ordem de criação, com ids distintos
        assertEquals(listOf(b, c), vm.state.value.cenarios)
        assertEquals(vm.state.value.cenarios.size, vm.state.value.cenarios.map { it.id }.toSet().size)
    }
}
