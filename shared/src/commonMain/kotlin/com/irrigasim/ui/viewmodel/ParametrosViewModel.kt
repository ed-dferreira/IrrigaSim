package com.irrigasim.ui.viewmodel

import com.irrigasim.domain.MetodoIrrigacao
import com.irrigasim.domain.Parametros
import kotlinx.coroutines.CoroutineScope

/**
 * Estado da tela de entrada direta de parâmetros (modo rápido).
 */
data class ParametrosUiState(
    val metodo: MetodoIrrigacao,
    val comprimento: String = "100",
    val desnivelM: String = "0.50",
    val distanciaHorizontalM: String = "100",
    val larguraOuEspacamento: String = if (metodo == MetodoIrrigacao.SULCO) "0.75" else "0.8",
    val k: String = "45.0",
    val a: String = "0.55",
    val vib: String = "2.0",
    val vazao: String = if (metodo == MetodoIrrigacao.INUNDACAO) "15.0" else "0.6",
    val tempo: String = "90",
    val lamina: String = "50",
    val manningN: String = "0.04"
) {
    val desnivelValor: Double
        get() = desnivelM.toDoubleOrNull() ?: 0.0

    val distanciaValor: Double
        get() = distanciaHorizontalM.toDoubleOrNull() ?: 1.0

    /** Declividade em percentual calculada a partir das duas medidas de campo. */
    val declividadeCalculada: Double
        get() = if (distanciaValor > 0) (desnivelValor / distanciaValor) * 100.0 else 0.0
}

/**
 * ViewModel da tela de parâmetros: mantém os campos do formulário e converte
 * a entrada em [Parametros] com coerções numéricas.
 */
class ParametrosViewModel(
    metodo: MetodoIrrigacao,
    scope: CoroutineScope = viewModelProductionScope()
) : BaseViewModel<ParametrosUiState>(ParametrosUiState(metodo = metodo), scope) {

    fun atualizarComprimento(valor: String) = updateState { it.copy(comprimento = valor) }

    fun atualizarDesnivel(valor: String) = updateState { it.copy(desnivelM = valor) }

    fun atualizarDistanciaHorizontal(valor: String) =
        updateState { it.copy(distanciaHorizontalM = valor) }

    fun atualizarLarguraOuEspacamento(valor: String) =
        updateState { it.copy(larguraOuEspacamento = valor) }

    fun atualizarK(valor: String) = updateState { it.copy(k = valor) }

    fun atualizarA(valor: String) = updateState { it.copy(a = valor) }

    fun atualizarVib(valor: String) = updateState { it.copy(vib = valor) }

    fun atualizarVazao(valor: String) = updateState { it.copy(vazao = valor) }

    fun atualizarTempo(valor: String) = updateState { it.copy(tempo = valor) }

    fun atualizarLamina(valor: String) = updateState { it.copy(lamina = valor) }

    fun atualizarManningN(valor: String) = updateState { it.copy(manningN = valor) }

    /** Converte o formulário em [Parametros], aplicando as coerções numéricas. */
    fun construirParametros(): Parametros {
        val s = currentState
        return Parametros(
            comprimento = (s.comprimento.toDoubleOrNull() ?: 100.0).coerceAtLeast(10.0),
            declividade = s.declividadeCalculada.coerceAtLeast(0.001),
            larguraOuEspacamento = (s.larguraOuEspacamento.toDoubleOrNull() ?: 0.8).coerceAtLeast(0.1),
            k = (s.k.toDoubleOrNull() ?: 45.0).coerceAtLeast(1.0),
            a = (s.a.toDoubleOrNull() ?: 0.55).coerceIn(0.01, 0.99),
            vib = (s.vib.toDoubleOrNull() ?: 2.0).coerceAtLeast(0.1),
            vazao = (s.vazao.toDoubleOrNull() ?: 0.6).coerceAtLeast(0.01),
            tempoAplicacao = (s.tempo.toDoubleOrNull() ?: 90.0).coerceAtLeast(1.0),
            laminaRequerida = (s.lamina.toDoubleOrNull() ?: 50.0).coerceAtLeast(1.0),
            manningN = (s.manningN.toDoubleOrNull() ?: 0.04).coerceAtLeast(0.01)
        )
    }
}
