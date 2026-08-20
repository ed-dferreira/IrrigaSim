package com.irrigasim.ui.viewmodel

import com.irrigasim.domain.Usuario
import kotlinx.coroutines.CoroutineScope

/**
 * Estado da tela de perfil: edição dos dados pessoais e configurações de
 * acessibilidade (tema escuro).
 */
data class PerfilUiState(
    val editando: Boolean = false,
    val nome: String = "",
    val instituicao: String = "",
    val curso: String = "",
    val temaEscuro: Boolean = false
)

/**
 * ViewModel do perfil do usuário e das preferências de acessibilidade.
 */
class PerfilViewModel(
    usuario: Usuario? = null,
    scope: CoroutineScope = viewModelProductionScope()
) : BaseViewModel<PerfilUiState>(
    PerfilUiState(
        nome = usuario?.nome ?: "",
        instituicao = usuario?.instituicao ?: "",
        curso = usuario?.curso ?: ""
    ),
    scope
) {

    // ---- Edição do perfil -------------------------------------------------

    fun iniciarEdicao() {
        updateState { it.copy(editando = true) }
    }

    fun cancelarEdicao() {
        updateState { it.copy(editando = false) }
    }

    fun salvarEdicao() {
        updateState { it.copy(editando = false) }
    }

    fun atualizarNome(nome: String) {
        updateState { it.copy(nome = nome) }
    }

    fun atualizarInstituicao(instituicao: String) {
        updateState { it.copy(instituicao = instituicao) }
    }

    fun atualizarCurso(curso: String) {
        updateState { it.copy(curso = curso) }
    }

    // ---- Acessibilidade ---------------------------------------------------

    /** Alterna o tema escuro (redução de brilho da tela). */
    fun alternarTemaEscuro(ativo: Boolean) {
        updateState { it.copy(temaEscuro = ativo) }
    }

    /**
     * Re-sincroniza os campos com os dados da conta autenticada, preservando
     * uma edição em andamento.
     */
    fun sincronizarCom(usuario: Usuario?) {
        if (usuario == null || currentState.editando) return
        updateState {
            it.copy(
                nome = usuario.nome,
                instituicao = usuario.instituicao ?: "",
                curso = usuario.curso ?: ""
            )
        }
    }
}
