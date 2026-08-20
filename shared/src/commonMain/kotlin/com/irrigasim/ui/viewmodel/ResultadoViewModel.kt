package com.irrigasim.ui.viewmodel

import com.irrigasim.domain.MetodoIrrigacao
import com.irrigasim.domain.Parametros
import kotlinx.coroutines.CoroutineScope

/**
 * Estado da tela de resultados: aba de gráfico selecionada e bloco de
 * salvamento do cenário.
 */
data class ResultadoUiState(
    val abaSelecionada: Int = 0,
    val cenarioSalvo: Boolean = false,
    val nomeCenario: String = ""
)

/**
 * ViewModel da tela de resultados.
 */
class ResultadoViewModel(
    metodo: MetodoIrrigacao,
    parametros: Parametros,
    scope: CoroutineScope = viewModelProductionScope()
) : BaseViewModel<ResultadoUiState>(
    ResultadoUiState(
        nomeCenario = "${metodo.nome} — ${parametros.comprimento.toInt()}m (${parametros.vazao} L/s)"
    ),
    scope
) {

    /** Seleciona a aba de gráficos (índice coercido ao intervalo válido). */
    fun selecionarAba(indice: Int) {
        updateState { it.copy(abaSelecionada = indice.coerceIn(0, TOTAL_ABAS - 1)) }
    }

    fun atualizarNomeCenario(nome: String) {
        updateState { it.copy(nomeCenario = nome) }
    }

    /**
     * Salva o cenário via [salvar] apenas se o nome for válido e o cenário
     * ainda não tiver sido salvo; marca o cenário como salvo em seguida.
     */
    fun salvarCenario(salvar: (String) -> Unit) {
        val estado = currentState
        if (estado.cenarioSalvo || estado.nomeCenario.isBlank()) return
        salvar(estado.nomeCenario)
        updateState { it.copy(cenarioSalvo = true) }
    }

    companion object {
        const val TOTAL_ABAS = 3
    }
}
