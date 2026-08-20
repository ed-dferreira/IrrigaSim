package com.irrigasim.ui.viewmodel

import com.irrigasim.data.PreferenciasApp
import com.irrigasim.data.TamanhoFonte
import com.irrigasim.domain.CenarioSalvo
import com.irrigasim.domain.MetodoIrrigacao
import com.irrigasim.domain.Parametros
import com.irrigasim.domain.Resultado
import com.irrigasim.domain.Usuario
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class PerfilViewModelTest {

    private val usuario = Usuario(
        uid = "u1",
        nome = "Maria Silva",
        email = "maria@ufla.br",
        instituicao = "UFLA",
        curso = "Eng. Agrícola"
    )

    @BeforeTest
    fun restaurarPreferenciasPadrao() {
        PreferenciasApp.limpar()
    }

    @Test
    fun camposIniciaisVemDaContaInformada() = runTest {
        val vm = PerfilViewModel(usuario, scope = backgroundScope)

        assertEquals("Maria Silva", vm.state.value.nome)
        assertEquals("UFLA", vm.state.value.instituicao)
        assertEquals("Eng. Agrícola", vm.state.value.curso)
        assertFalse(vm.state.value.editando)
    }

    @Test
    fun semContaCamposIniciamVazios() = runTest {
        val vm = PerfilViewModel(usuario = null, scope = backgroundScope)

        assertEquals("", vm.state.value.nome)
        assertEquals("", vm.state.value.instituicao)
        assertEquals("", vm.state.value.curso)
    }

    @Test
    fun fluxoDeEdicaoAlternaEditando() = runTest {
        val vm = PerfilViewModel(usuario, scope = backgroundScope)

        vm.iniciarEdicao()
        assertTrue(vm.state.value.editando)

        vm.salvarEdicao()
        assertFalse(vm.state.value.editando)

        vm.iniciarEdicao()
        vm.cancelarEdicao()
        assertFalse(vm.state.value.editando)
    }

    @Test
    fun atualizacaoDeCamposRefleteNoEstado() = runTest {
        val vm = PerfilViewModel(usuario = null, scope = backgroundScope)

        vm.atualizarNome("João")
        vm.atualizarInstituicao("UFLA")
        vm.atualizarCurso("Agronomia")

        assertEquals("João", vm.state.value.nome)
        assertEquals("UFLA", vm.state.value.instituicao)
        assertEquals("Agronomia", vm.state.value.curso)
    }

    // ---- Acessibilidade ----------------------------------------------------

    @Test
    fun temaEscuroIniciaDesligadoEAlternarLigaEDesliga() = runTest {
        val vm = PerfilViewModel(usuario = null, scope = backgroundScope)

        assertFalse(vm.state.value.temaEscuro)

        vm.alternarTemaEscuro(true)
        assertTrue(vm.state.value.temaEscuro)

        vm.alternarTemaEscuro(false)
        assertFalse(vm.state.value.temaEscuro)
    }

    @Test
    fun altoContrasteIniciaDesligadoEAlternarLigaEDesliga() = runTest {
        val vm = PerfilViewModel(usuario = null, scope = backgroundScope)

        assertFalse(vm.state.value.altoContraste)

        vm.alternarAltoContraste(true)
        assertTrue(vm.state.value.altoContraste)

        vm.alternarAltoContraste(false)
        assertFalse(vm.state.value.altoContraste)
    }

    @Test
    fun textoNegritoIniciaDesligadoEAlternarLigaEDesliga() = runTest {
        val vm = PerfilViewModel(usuario = null, scope = backgroundScope)

        assertFalse(vm.state.value.textoNegrito)

        vm.alternarTextoNegrito(true)
        assertTrue(vm.state.value.textoNegrito)

        vm.alternarTextoNegrito(false)
        assertFalse(vm.state.value.textoNegrito)
    }

    @Test
    fun animacoesReduzidasIniciaDesligadoEAlternarLigaEDesliga() = runTest {
        val vm = PerfilViewModel(usuario = null, scope = backgroundScope)

        assertFalse(vm.state.value.animacoesReduzidas)

        vm.alternarAnimacoesReduzidas(true)
        assertTrue(vm.state.value.animacoesReduzidas)

        vm.alternarAnimacoesReduzidas(false)
        assertFalse(vm.state.value.animacoesReduzidas)
    }

    @Test
    fun modoLeitorTelaIniciaDesligadoEAlternarLigaEDesliga() = runTest {
        val vm = PerfilViewModel(usuario = null, scope = backgroundScope)

        assertFalse(vm.state.value.modoLeitorTela)

        vm.alternarModoLeitorTela(true)
        assertTrue(vm.state.value.modoLeitorTela)

        vm.alternarModoLeitorTela(false)
        assertFalse(vm.state.value.modoLeitorTela)
    }

    @Test
    fun tamanhoFonteIniciaNoPadraoEPodeSerAlterado() = runTest {
        val vm = PerfilViewModel(usuario = null, scope = backgroundScope)

        assertEquals(TamanhoFonte.PADRAO, vm.state.value.tamanhoFonte)

        vm.definirTamanhoFonte(TamanhoFonte.MUITO_GRANDE)
        assertEquals(TamanhoFonte.MUITO_GRANDE, vm.state.value.tamanhoFonte)

        vm.definirTamanhoFonte(TamanhoFonte.PEQUENO)
        assertEquals(TamanhoFonte.PEQUENO, vm.state.value.tamanhoFonte)
    }

    @Test
    fun preferenciasPersistemEntreInstancias() = runTest {
        val primeiraSessao = PerfilViewModel(usuario = null, scope = backgroundScope)
        primeiraSessao.alternarTemaEscuro(true)
        primeiraSessao.definirTamanhoFonte(TamanhoFonte.GRANDE)
        primeiraSessao.alternarAltoContraste(true)
        primeiraSessao.alternarTextoNegrito(true)
        primeiraSessao.alternarAnimacoesReduzidas(true)
        primeiraSessao.alternarModoLeitorTela(true)

        val novaExecucao = PerfilViewModel(usuario = null, scope = backgroundScope)

        assertTrue(novaExecucao.state.value.temaEscuro)
        assertEquals(TamanhoFonte.GRANDE, novaExecucao.state.value.tamanhoFonte)
        assertTrue(novaExecucao.state.value.altoContraste)
        assertTrue(novaExecucao.state.value.textoNegrito)
        assertTrue(novaExecucao.state.value.animacoesReduzidas)
        assertTrue(novaExecucao.state.value.modoLeitorTela)
    }

    @Test
    fun limparRestauraPreferenciasAoPadrao() = runTest {
        val vm = PerfilViewModel(usuario = null, scope = backgroundScope)
        vm.alternarTemaEscuro(true)
        vm.definirTamanhoFonte(TamanhoFonte.MUITO_GRANDE)

        PreferenciasApp.limpar()
        val novaExecucao = PerfilViewModel(usuario = null, scope = backgroundScope)

        assertFalse(novaExecucao.state.value.temaEscuro)
        assertEquals(TamanhoFonte.PADRAO, novaExecucao.state.value.tamanhoFonte)
    }

    // ---- Estatísticas ------------------------------------------------------

    private fun cenario(metodo: MetodoIrrigacao) = CenarioSalvo(
        id = "c_${metodo.name}",
        titulo = metodo.nome,
        dataHora = "Hoje",
        metodo = metodo,
        parametros = Parametros(),
        resultado = Resultado(
            eficiencia = 80.0,
            laminaMedia = 50.0,
            tempoAvanco = 40.0,
            perdaPercolacao = 6.0,
            perdaEscoamento = 4.0
        )
    )

    @Test
    fun estatisticasSemCenariosFicamZeradas() = runTest {
        val vm = PerfilViewModel(usuario = null, scope = backgroundScope)

        vm.atualizarEstatisticas(emptyList())

        assertEquals(0, vm.state.value.totalSimulacoes)
        assertNull(vm.state.value.metodoFavorito)
    }

    @Test
    fun estatisticasCalculamTotalEMetodoMaisFrequente() = runTest {
        val vm = PerfilViewModel(usuario = null, scope = backgroundScope)
        val cenarios = listOf(
            cenario(MetodoIrrigacao.SULCO),
            cenario(MetodoIrrigacao.FAIXA),
            cenario(MetodoIrrigacao.SULCO),
            cenario(MetodoIrrigacao.INUNDACAO),
            cenario(MetodoIrrigacao.SULCO)
        )

        vm.atualizarEstatisticas(cenarios)

        assertEquals(5, vm.state.value.totalSimulacoes)
        assertEquals(MetodoIrrigacao.SULCO, vm.state.value.metodoFavorito)
    }

    @Test
    fun empateDeMetodosFicaComPrimeiroDoEnum() = runTest {
        val vm = PerfilViewModel(usuario = null, scope = backgroundScope)
        val cenarios = listOf(
            cenario(MetodoIrrigacao.INUNDACAO),
            cenario(MetodoIrrigacao.FAIXA)
        )

        vm.atualizarEstatisticas(cenarios)

        assertEquals(2, vm.state.value.totalSimulacoes)
        assertEquals(MetodoIrrigacao.FAIXA, vm.state.value.metodoFavorito)
    }

    @Test
    fun estatisticasAcompanhamExclusoesDeCenarios() = runTest {
        val vm = PerfilViewModel(usuario = null, scope = backgroundScope)

        vm.atualizarEstatisticas(listOf(cenario(MetodoIrrigacao.SULCO), cenario(MetodoIrrigacao.SULCO)))
        vm.atualizarEstatisticas(listOf(cenario(MetodoIrrigacao.SULCO)))

        assertEquals(1, vm.state.value.totalSimulacoes)
        assertEquals(MetodoIrrigacao.SULCO, vm.state.value.metodoFavorito)
    }

    // ---- Sincronização -----------------------------------------------------

    @Test
    fun sincronizarComAtualizaCamposQuandoNaoEstaEditando() = runTest {
        val vm = PerfilViewModel(usuario = null, scope = backgroundScope)

        vm.sincronizarCom(usuario)

        assertEquals("Maria Silva", vm.state.value.nome)
        assertEquals("UFLA", vm.state.value.instituicao)
        assertEquals("Eng. Agrícola", vm.state.value.curso)
    }

    @Test
    fun sincronizarComNaoSobrescreveCamposDuranteEdicao() = runTest {
        val vm = PerfilViewModel(usuario = null, scope = backgroundScope)
        vm.iniciarEdicao()
        vm.atualizarNome("Rascunho em andamento")

        vm.sincronizarCom(usuario)

        assertEquals("Rascunho em andamento", vm.state.value.nome)
        assertTrue(vm.state.value.editando)
    }

    @Test
    fun sincronizarComUsuarioNuloNaoAlteraEstado() = runTest {
        val vm = PerfilViewModel(usuario, scope = backgroundScope)

        vm.sincronizarCom(null)

        assertEquals("Maria Silva", vm.state.value.nome)
    }
}
