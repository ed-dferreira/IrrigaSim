package com.irrigasim.ui.viewmodel

import com.irrigasim.domain.CenarioSalvo
import com.irrigasim.domain.MetodoIrrigacao
import com.irrigasim.domain.Parametros
import com.irrigasim.domain.Resultado
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class SimulacaoViewModelTest {

    @Test
    fun estadoInicialTemMetodoSulcoSemResultadoEPrimeiroAcesso() = runTest {
        val vm = SimulacaoViewModel(scope = backgroundScope)

        assertEquals(MetodoIrrigacao.SULCO, vm.state.value.metodo)
        assertEquals(Parametros(), vm.state.value.parametros)
        assertNull(vm.state.value.resultado)
        assertTrue(vm.state.value.primeiroAcesso)
    }

    @Test
    fun selecionarMetodoAtualizaEstado() = runTest {
        val vm = SimulacaoViewModel(scope = backgroundScope)

        vm.selecionarMetodo(MetodoIrrigacao.FAIXA)

        assertEquals(MetodoIrrigacao.FAIXA, vm.state.value.metodo)
    }

    @Test
    fun executarSimulacaoPublicaResultadoEAtualizaMetodoEParametros() = runTest {
        val vm = SimulacaoViewModel(scope = backgroundScope)
        val parametros = Parametros(comprimento = 120.0, vazao = 0.8)

        val resultado = vm.executarSimulacao(MetodoIrrigacao.FAIXA, parametros)

        assertEquals(resultado, vm.state.value.resultado)
        assertEquals(MetodoIrrigacao.FAIXA, vm.state.value.metodo)
        assertEquals(parametros, vm.state.value.parametros)
    }

    @Test
    fun executarSimulacaoSucessivaSubstituiResultadoAnterior() = runTest {
        val vm = SimulacaoViewModel(scope = backgroundScope)

        vm.executarSimulacao(MetodoIrrigacao.SULCO, Parametros(comprimento = 80.0))
        val segundo = vm.executarSimulacao(MetodoIrrigacao.INUNDACAO, Parametros(comprimento = 50.0))

        assertEquals(segundo, vm.state.value.resultado)
        assertEquals(MetodoIrrigacao.INUNDACAO, vm.state.value.metodo)
    }

    @Test
    fun abrirCenarioCarregaMetodoParametrosEResultado() = runTest {
        val vm = SimulacaoViewModel(scope = backgroundScope)
        val cenario = CenarioSalvo(
            id = "cenario_1_100",
            titulo = "Teste",
            dataHora = "Hoje",
            metodo = MetodoIrrigacao.INUNDACAO,
            parametros = Parametros(comprimento = 60.0),
            resultado = Resultado(
                eficiencia = 82.0,
                laminaMedia = 48.0,
                tempoAvanco = 30.0,
                perdaPercolacao = 10.0,
                perdaEscoamento = 8.0
            )
        )

        vm.abrirCenario(cenario)

        assertEquals(MetodoIrrigacao.INUNDACAO, vm.state.value.metodo)
        assertEquals(60.0, vm.state.value.parametros.comprimento)
        assertEquals(82.0, vm.state.value.resultado?.eficiencia)
    }

    @Test
    fun concluirPrimeiroAcessoDesativaTutorial() = runTest {
        val vm = SimulacaoViewModel(scope = backgroundScope)

        vm.concluirPrimeiroAcesso()

        assertFalse(vm.state.value.primeiroAcesso)
    }

    @Test
    fun resultadoFallbackPreencheCamposDidaticos() = runTest {
        val vm = SimulacaoViewModel(scope = backgroundScope)
        val parametros = Parametros(laminaRequerida = 42.0, comprimento = 150.0)

        val fallback = vm.resultadoFallback(parametros)

        assertEquals(70.0, fallback.eficiencia)
        assertEquals(90.0, fallback.eficienciaRequerimento)
        assertEquals(80.0, fallback.cuc)
        assertEquals(75.0, fallback.du)
        assertEquals(42.0, fallback.laminaMedia)
        assertEquals(45.0, fallback.tempoAvanco)
        assertEquals(15.0, fallback.perdaPercolacao)
        assertEquals(15.0, fallback.perdaEscoamento)
        assertEquals(2, fallback.curvaAvanco.size)
        assertEquals(150.0, fallback.curvaAvanco.last().y)
        assertTrue(fallback.resumoTextual.isNotBlank())
    }
}
