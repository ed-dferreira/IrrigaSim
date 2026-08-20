package com.irrigasim.ui.viewmodel

import com.irrigasim.domain.MetodoIrrigacao
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals

@OptIn(ExperimentalCoroutinesApi::class)
class WizardViewModelTest {

    // ---- Navegação entre etapas ---------------------------------------------

    @Test
    fun wizardIniciaNaEtapa1() = runTest {
        val vm = WizardViewModel(scope = backgroundScope)

        assertEquals(1, vm.state.value.etapa)
    }

    @Test
    fun avancarEVoltarEtapaDentroDosLimites() = runTest {
        val vm = WizardViewModel(scope = backgroundScope)

        vm.avancarEtapa()
        vm.avancarEtapa()
        assertEquals(3, vm.state.value.etapa)

        vm.voltarEtapa()
        assertEquals(2, vm.state.value.etapa)
    }

    @Test
    fun avancarNaoPassaDaUltimaEtapaEVoltarNaoPassaDaPrimeira() = runTest {
        val vm = WizardViewModel(scope = backgroundScope)

        repeat(10) { vm.avancarEtapa() }
        assertEquals(WizardViewModel.TOTAL_ETAPAS, vm.state.value.etapa)

        repeat(10) { vm.voltarEtapa() }
        assertEquals(1, vm.state.value.etapa)
    }

    @Test
    fun irParaEtapaCoercionaIndicesForaDoIntervalo() = runTest {
        val vm = WizardViewModel(scope = backgroundScope)

        vm.irParaEtapa(99)
        assertEquals(WizardViewModel.TOTAL_ETAPAS, vm.state.value.etapa)

        vm.irParaEtapa(-3)
        assertEquals(1, vm.state.value.etapa)
    }

    // ---- Etapa 1: método ------------------------------------------------------

    @Test
    fun metodoInicialEhRespeitado() = runTest {
        val vm = WizardViewModel(metodoInicial = MetodoIrrigacao.FAIXA, scope = backgroundScope)

        assertEquals(MetodoIrrigacao.FAIXA, vm.state.value.metodo)
    }

    @Test
    fun selecionarSulcoComLarguraPadraoAjustaParaEspacamentoDeSulcos() = runTest {
        val vm = WizardViewModel(metodoInicial = MetodoIrrigacao.FAIXA, scope = backgroundScope)
        assertEquals("0.8", vm.state.value.larguraOuEspacamento)

        vm.selecionarMetodo(MetodoIrrigacao.SULCO)

        assertEquals("0.75", vm.state.value.larguraOuEspacamento)
    }

    @Test
    fun selecionarSulcoPreservaLarguraJaEditada() = runTest {
        val vm = WizardViewModel(metodoInicial = MetodoIrrigacao.FAIXA, scope = backgroundScope)
        vm.atualizarLarguraOuEspacamento("1.2")

        vm.selecionarMetodo(MetodoIrrigacao.SULCO)

        assertEquals("1.2", vm.state.value.larguraOuEspacamento)
    }

    @Test
    fun selecionarFaixaMantemLarguraPadrao() = runTest {
        val vm = WizardViewModel(scope = backgroundScope)

        vm.selecionarMetodo(MetodoIrrigacao.FAIXA)

        assertEquals("0.8", vm.state.value.larguraOuEspacamento)
    }

    // ---- Etapa 2: solo ---------------------------------------------------------

    @Test
    fun presetFrancoEhOPadrao() = runTest {
        val vm = WizardViewModel(scope = backgroundScope)

        assertEquals("franco", vm.state.value.tipoSoloPreset)
        assertEquals("45.0", vm.state.value.k)
        assertEquals("0.55", vm.state.value.a)
        assertEquals("2.0", vm.state.value.vib)
    }

    @Test
    fun presetsSoloAtualizamCoeficientes() = runTest {
        val vm = WizardViewModel(scope = backgroundScope)

        vm.aplicarPresetSolo("arenoso")
        assertEquals("arenoso", vm.state.value.tipoSoloPreset)
        assertEquals("65.0", vm.state.value.k)
        assertEquals("0.65", vm.state.value.a)
        assertEquals("5.0", vm.state.value.vib)

        vm.aplicarPresetSolo("argiloso")
        assertEquals("argiloso", vm.state.value.tipoSoloPreset)
        assertEquals("30.0", vm.state.value.k)
        assertEquals("0.45", vm.state.value.a)
        assertEquals("0.8", vm.state.value.vib)
    }

    @Test
    fun edicaoManualDoSoloMarcaPresetCustom() = runTest {
        val vm = WizardViewModel(scope = backgroundScope)

        vm.atualizarK("50.0")

        assertEquals("custom", vm.state.value.tipoSoloPreset)
        assertEquals("50.0", vm.state.value.k)
    }

    // ---- Declividade e conversão ------------------------------------------------

    @Test
    fun declividadeCalculadaUsaDesnivelEDistancia() = runTest {
        val vm = WizardViewModel(scope = backgroundScope)

        vm.atualizarDesnivel("0.50")
        vm.atualizarDistanciaHorizontal("100")

        assertEquals(0.5, vm.state.value.declividadeCalculada)
    }

    @Test
    fun construirParametrosConverteCamposValidos() = runTest {
        val vm = WizardViewModel(scope = backgroundScope)
        vm.atualizarComprimento("200")
        vm.atualizarVazao("1.2")
        vm.atualizarTempo("120")
        vm.atualizarLamina("60")

        val p = vm.construirParametros()

        assertEquals(200.0, p.comprimento)
        assertEquals(1.2, p.vazao)
        assertEquals(120.0, p.tempoAplicacao)
        assertEquals(60.0, p.laminaRequerida)
        assertEquals(45.0, p.k)
        assertEquals(0.55, p.a)
    }

    @Test
    fun construirParametrosAplicaDefaultsECoercoesParaEntradaInvalida() = runTest {
        val vm = WizardViewModel(scope = backgroundScope)
        vm.atualizarComprimento("abc")
        vm.atualizarDesnivel("-5")
        vm.atualizarDistanciaHorizontal("abc")
        vm.atualizarK("-10")
        vm.atualizarA("7")
        vm.atualizarVazao("0")
        vm.atualizarTempo("-3")
        vm.atualizarLamina("")
        vm.atualizarManningN("x")

        val p = vm.construirParametros()

        assertEquals(100.0, p.comprimento)                 // texto inválido -> default
        assertEquals(0.001, p.declividade)                 // negativa -> mínimo
        assertEquals(0.8, p.larguraOuEspacamento)          // padrão preservado
        assertEquals(1.0, p.k)                             // negativo -> mínimo
        assertEquals(0.99, p.a)                            // fora de (0,1) -> teto
        assertEquals(0.01, p.vazao)                        // zero -> mínimo
        assertEquals(1.0, p.tempoAplicacao)                // negativo -> mínimo
        assertEquals(50.0, p.laminaRequerida)              // vazio -> default
        assertEquals(0.04, p.manningN)                     // inválido -> default
    }
}
