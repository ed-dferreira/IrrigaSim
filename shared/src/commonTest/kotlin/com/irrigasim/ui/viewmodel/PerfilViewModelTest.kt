package com.irrigasim.ui.viewmodel

import com.irrigasim.domain.Usuario
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
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
