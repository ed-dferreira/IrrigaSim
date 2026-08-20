package com.irrigasim.ui.viewmodel

import com.irrigasim.data.PreferenciasApp
import com.irrigasim.data.TamanhoFonte
import com.irrigasim.domain.CenarioSalvo
import com.irrigasim.domain.MetodoIrrigacao
import com.irrigasim.domain.Usuario
import kotlinx.coroutines.CoroutineScope

/**
 * Estado da tela de perfil: edição dos dados pessoais, estatísticas de uso e
 * configurações de acessibilidade.
 */
data class PerfilUiState(
    val editando: Boolean = false,
    val nome: String = "",
    val instituicao: String = "",
    val curso: String = "",
    val temaEscuro: Boolean = false,
    val tamanhoFonte: TamanhoFonte = TamanhoFonte.PADRAO,
    val altoContraste: Boolean = false,
    val textoNegrito: Boolean = false,
    val animacoesReduzidas: Boolean = false,
    val modoLeitorTela: Boolean = false,
    val totalSimulacoes: Int = 0,
    val metodoFavorito: MetodoIrrigacao? = null
)

/**
 * ViewModel do perfil do usuário, estatísticas de uso e preferências de
 * acessibilidade. Cada alteração de preferência é persistida em
 * [PreferenciasApp] e recarregada na próxima inicialização do app.
 */
class PerfilViewModel(
    usuario: Usuario? = null,
    scope: CoroutineScope = viewModelProductionScope()
) : BaseViewModel<PerfilUiState>(
    PerfilUiState(
        nome = usuario?.nome ?: "",
        instituicao = usuario?.instituicao ?: "",
        curso = usuario?.curso ?: "",
        temaEscuro = PreferenciasApp.temaEscuro(),
        tamanhoFonte = PreferenciasApp.tamanhoFonte(),
        altoContraste = PreferenciasApp.altoContraste(),
        textoNegrito = PreferenciasApp.textoNegrito(),
        animacoesReduzidas = PreferenciasApp.animacoesReduzidas(),
        modoLeitorTela = PreferenciasApp.modoLeitorTela()
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
        PreferenciasApp.definirTemaEscuro(ativo)
    }

    /** Define a escala de fonte da interface. */
    fun definirTamanhoFonte(tamanho: TamanhoFonte) {
        updateState { it.copy(tamanhoFonte = tamanho) }
        PreferenciasApp.definirTamanhoFonte(tamanho)
    }

    /** Alterna o modo de alto contraste (texto e superfícies maximizados). */
    fun alternarAltoContraste(ativo: Boolean) {
        updateState { it.copy(altoContraste = ativo) }
        PreferenciasApp.definirAltoContraste(ativo)
    }

    /** Alterna o texto em negrito global. */
    fun alternarTextoNegrito(ativo: Boolean) {
        updateState { it.copy(textoNegrito = ativo) }
        PreferenciasApp.definirTextoNegrito(ativo)
    }

    /** Alterna a redução de animações e transições. */
    fun alternarAnimacoesReduzidas(ativo: Boolean) {
        updateState { it.copy(animacoesReduzidas = ativo) }
        PreferenciasApp.definirAnimacoesReduzidas(ativo)
    }

    /** Alterna o modo leitor de tela (descrições verbais ampliadas). */
    fun alternarModoLeitorTela(ativo: Boolean) {
        updateState { it.copy(modoLeitorTela = ativo) }
        PreferenciasApp.definirModoLeitorTela(ativo)
    }

    // ---- Estatísticas de uso ----------------------------------------------

    /**
     * Recalcula as estatísticas do usuário a partir dos cenários salvos:
     * total de simulações e método de irrigação mais frequente.
     */
    fun atualizarEstatisticas(cenarios: List<CenarioSalvo>) {
        updateState {
            it.copy(
                totalSimulacoes = cenarios.size,
                metodoFavorito = metodoMaisFrequente(cenarios)
            )
        }
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

/** Método mais frequente nos cenários; empates ficam com o primeiro atingido. */
internal fun metodoMaisFrequente(cenarios: List<CenarioSalvo>): MetodoIrrigacao? {
    if (cenarios.isEmpty()) return null
    return cenarios.groupingBy { it.metodo }.eachCount()
        .maxWithOrNull(compareBy({ it.value }, { -it.key.ordinal }))
        ?.key
}
