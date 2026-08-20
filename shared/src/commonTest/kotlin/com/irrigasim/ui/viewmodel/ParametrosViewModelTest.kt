package com.irrigasim.ui.viewmodel

import com.irrigasim.domain.MetodoIrrigacao
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals

@OptIn(ExperimentalCoroutinesApi::class)
class ParametrosViewModelTest {

    // ---- Defaults por método -------------------------------------------------

    @Test
    fun defaultsParaSulco() = runTest {
        val vm = ParametrosViewModel(MetodoIrrigacao.SULCO, scope = backgroundScope)

        assertEquals("0.75", vm.state.value.larguraOuEspacamento)
        assertEquals("0.6", vm.state.value.vazao)
        assertEquals(MetodoIrrigacao.SULCO, vm.state.value.metodo)
    }

    @Test
    fun defaultsParaFaixa() = runTest {
        val vm = ParametrosViewModel(MetodoIrrigacao.FAIXA, scope = backgroundScope)

        assertEquals("0.8", vm.state.value.larguraOuEspacamento)
        assertEquals("0.6", vm.state.value.vazao)
    }

    @Test
    fun defaultsParaInundacao() = runTest {
        val vm = ParametrosViewModel(MetodoIrrigacao.INUNDACAO, scope = backgroundScope)

        assertEquals("0.8", vm.state.value.larguraOuEspacamento)
        assertEquals("15.0", vm.state.value.vazao)
    }

    // ---- Atualização de campos -------------------------------------------------

    @Test
    fun atualizacaoDeCamposRefleteNoEstado() = runTest {
        val vm = ParametrosViewModel(MetodoIrrigacao.SULCO, scope = backgroundScope)

        vm.atualizarComprimento("250")
        vm.atualizarDesnivel("1.0")
        vm.atualizarDistanciaHorizontal("200")
        vm.atualizarK("60")
        vm.atualizarA("0.7")
        vm.atualizarVib("4.0")
        vm.atualizarVazao("1.0")
        vm.atualizarTempo("150")
        vm.atualizarLamina("55")
        vm.atualizarManningN("0.025")

        assertEquals("250", vm.state.value.comprimento)
        assertEquals("1.0", vm.state.value.desnivelM)
        assertEquals("200", vm.state.value.distanciaHorizontalM)
        assertEquals("60", vm.state.value.k)
        assertEquals("0.7", vm.state.value.a)
        assertEquals("4.0", vm.state.value.vib)
        assertEquals("1.0", vm.state.value.vazao)
        assertEquals("150", vm.state.value.tempo)
        assertEquals("55", vm.state.value.lamina)
        assertEquals("0.025", vm.state.value.manningN)
    }

    // ---- Declividade e conversão ------------------------------------------------

    @Test
    fun declividadeCalculadaUsaDesnivelEDistancia() = runTest {
        val vm = ParametrosViewModel(MetodoIrrigacao.SULCO, scope = backgroundScope)

        vm.atualizarDesnivel("2.0")
        vm.atualizarDistanciaHorizontal("400")

        assertEquals(0.5, vm.state.value.declividadeCalculada)
    }

    @Test
    fun construirParametrosConverteCamposValidos() = runTest {
        val vm = ParametrosViewModel(MetodoIrrigacao.SULCO, scope = backgroundScope)
        vm.atualizarComprimento("180")
        vm.atualizarLarguraOuEspacamento("0.9")
        vm.atualizarVazao("0.9")

        val p = vm.construirParametros()

        assertEquals(180.0, p.comprimento)
        assertEquals(0.9, p.larguraOuEspacamento)
        assertEquals(0.9, p.vazao)
        assertEquals(50.0, p.laminaRequerida) // default "50"
    }

    @Test
    fun construirParametrosAplicaDefaultsECoercoesParaEntradaInvalida() = runTest {
        val vm = ParametrosViewModel(MetodoIrrigacao.SULCO, scope = backgroundScope)
        vm.atualizarComprimento("")
        vm.atualizarDesnivel("-1")
        vm.atualizarDistanciaHorizontal("abc")
        vm.atualizarLarguraOuEspacamento("0")
        vm.atualizarK("abc")
        vm.atualizarA("-2")
        vm.atualizarVazao("")
        vm.atualizarTempo("0")
        vm.atualizarLamina("abc")
        vm.atualizarManningN("-1")

        val p = vm.construirParametros()

        assertEquals(100.0, p.comprimento)           // vazio -> default
        assertEquals(0.001, p.declividade)           // negativa -> mínimo
        assertEquals(0.1, p.larguraOuEspacamento)    // zero -> mínimo
        assertEquals(45.0, p.k)                      // inválido -> default
        assertEquals(0.01, p.a)                      // negativo -> piso
        assertEquals(0.6, p.vazao)                   // vazio -> default
        assertEquals(1.0, p.tempoAplicacao)          // zero -> mínimo
        assertEquals(50.0, p.laminaRequerida)        // inválido -> default
        assertEquals(0.01, p.manningN)               // negativo -> mínimo
    }
}
