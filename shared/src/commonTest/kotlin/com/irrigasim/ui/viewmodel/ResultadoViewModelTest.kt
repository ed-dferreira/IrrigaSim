package com.irrigasim.ui.viewmodel

import com.irrigasim.domain.MetodoIrrigacao
import com.irrigasim.domain.Parametros
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse

@OptIn(ExperimentalCoroutinesApi::class)
class ResultadoViewModelTest {

    // ---- Abas de gráficos ------------------------------------------------------

    @Test
    fun abaInicialEhBalancoHidrico() = runTest {
        val vm = novoViewModel(backgroundScope)

        assertEquals(0, vm.state.value.abaSelecionada)
    }

    @Test
    fun selecionarAbaAtualizaAbaAtiva() = runTest {
        val vm = novoViewModel(backgroundScope)

        vm.selecionarAba(2)

        assertEquals(2, vm.state.value.abaSelecionada)
    }

    @Test
    fun selecionarAbaCoercionaIndicesForaDoIntervalo() = runTest {
        val vm = novoViewModel(backgroundScope)

        vm.selecionarAba(-1)
        assertEquals(0, vm.state.value.abaSelecionada)

        vm.selecionarAba(99)
        assertEquals(ResultadoViewModel.TOTAL_ABAS - 1, vm.state.value.abaSelecionada)
    }

    // ---- Nome e salvamento do cenário ---------------------------------------------

    @Test
    fun nomeCenarioPadraoEhDerivadoDoMetodoEParametros() = runTest {
        val vm = novoViewModel(backgroundScope)

        assertEquals("Sulcos — 100m (0.6 L/s)", vm.state.value.nomeCenario)
    }

    @Test
    fun atualizarNomeCenarioRefleteNoEstado() = runTest {
        val vm = novoViewModel(backgroundScope)

        vm.atualizarNomeCenario("Meu teste")

        assertEquals("Meu teste", vm.state.value.nomeCenario)
    }

    @Test
    fun salvarCenarioComNomeEmBrancoNaoSalvaNemMarcaComoSalvo() = runTest {
        val vm = novoViewModel(backgroundScope)
        vm.atualizarNomeCenario("   ")
        var chamado = false

        vm.salvarCenario { chamado = true }

        assertFalse(chamado)
        assertFalse(vm.state.value.cenarioSalvo)
    }

    @Test
    fun salvarCenarioValidoChamaCallbackEMarcaComoSalvo() = runTest {
        val vm = novoViewModel(backgroundScope)
        var tituloRecebido: String? = null

        vm.salvarCenario { tituloRecebido = it }

        assertEquals("Sulcos — 100m (0.6 L/s)", tituloRecebido)
        assertEquals(true, vm.state.value.cenarioSalvo)
    }

    @Test
    fun naoPermiteSalvarDuasVezesOMesmoCenario() = runTest {
        val vm = novoViewModel(backgroundScope)
        var chamadas = 0

        vm.salvarCenario { chamadas++ }
        vm.salvarCenario { chamadas++ }

        assertEquals(1, chamadas)
    }

    private fun novoViewModel(scope: CoroutineScope): ResultadoViewModel =
        ResultadoViewModel(
            metodo = MetodoIrrigacao.SULCO,
            parametros = Parametros(),
            scope = scope
        )
}
