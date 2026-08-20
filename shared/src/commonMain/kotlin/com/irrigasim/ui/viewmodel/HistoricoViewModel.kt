package com.irrigasim.ui.viewmodel

import com.irrigasim.domain.CenarioSalvo
import com.irrigasim.domain.MetodoIrrigacao
import com.irrigasim.domain.Parametros
import com.irrigasim.domain.Resultado
import kotlinx.coroutines.CoroutineScope

/** Estado da aba de cenários salvos. */
data class HistoricoUiState(
    val cenarios: List<CenarioSalvo> = emptyList()
)

/**
 * ViewModel do histórico: gerencia a lista de cenários salvos (CRUD em memória).
 */
class HistoricoViewModel(scope: CoroutineScope = viewModelProductionScope()) :
    BaseViewModel<HistoricoUiState>(HistoricoUiState(), scope) {

    /** Salva um novo cenário e o retorna. */
    fun salvarCenario(
        titulo: String,
        metodo: MetodoIrrigacao,
        parametros: Parametros,
        resultado: Resultado
    ): CenarioSalvo {
        val novoCenario = CenarioSalvo(
            id = "cenario_${currentState.cenarios.size + 1}_${parametros.comprimento.toInt()}",
            titulo = titulo,
            dataHora = "Hoje",
            metodo = metodo,
            parametros = parametros,
            resultado = resultado
        )
        updateState { it.copy(cenarios = it.cenarios + novoCenario) }
        return novoCenario
    }

    /** Exclui o cenário com o id informado (operação é idempotente). */
    fun excluirCenario(id: String) {
        updateState { it.copy(cenarios = it.cenarios.filterNot { cenario -> cenario.id == id }) }
    }
}
