package com.irrigasim.ui.viewmodel

import com.irrigasim.domain.MetodoIrrigacao
import com.irrigasim.domain.Parametros
import kotlinx.coroutines.CoroutineScope

/**
 * Estado do Wizard Didático em 4 etapas (primeiro acesso / tutorial).
 * Todos os campos são texto puro (conteúdo dos campos de entrada); a conversão
 * numérica com coerção acontece apenas em [WizardViewModel.construirParametros].
 */
data class WizardUiState(
    val etapa: Int = 1,
    val metodo: MetodoIrrigacao = MetodoIrrigacao.SULCO,
    val tipoSoloPreset: String = "franco",
    val k: String = "45.0",
    val a: String = "0.55",
    val vib: String = "2.0",
    val lamina: String = "50.0",
    val comprimento: String = "100",
    val desnivelM: String = "0.50",
    val distanciaHorizontalM: String = "100",
    val larguraOuEspacamento: String = "0.8",
    val vazao: String = "0.6",
    val tempo: String = "90",
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
 * ViewModel do wizard didático: controla a etapa corrente e os dados do formulário.
 */
class WizardViewModel(
    metodoInicial: MetodoIrrigacao = MetodoIrrigacao.SULCO,
    scope: CoroutineScope = viewModelProductionScope()
) : BaseViewModel<WizardUiState>(WizardUiState(metodo = metodoInicial), scope) {

    // ---- Navegação entre etapas -------------------------------------------

    fun irParaEtapa(etapa: Int) {
        updateState { it.copy(etapa = etapa.coerceIn(1, TOTAL_ETAPAS)) }
    }

    fun avancarEtapa() {
        irParaEtapa(currentState.etapa + 1)
    }

    fun voltarEtapa() {
        irParaEtapa(currentState.etapa - 1)
    }

    // ---- Etapa 1: método ---------------------------------------------------

    /**
     * Seleciona o método; ao escolher sulcos com o espaçamento ainda no padrão,
     * ajusta o valor sugerido para 0,75 m.
     */
    fun selecionarMetodo(metodo: MetodoIrrigacao) {
        updateState { atual ->
            val larguraAjustada =
                if (metodo == MetodoIrrigacao.SULCO && atual.larguraOuEspacamento == "0.8") {
                    "0.75"
                } else {
                    atual.larguraOuEspacamento
                }
            atual.copy(metodo = metodo, larguraOuEspacamento = larguraAjustada)
        }
    }

    // ---- Etapa 2: solo & requerimento ---------------------------------------

    /** Aplica um preset de solo agrícola (arenoso, franco ou argiloso). */
    fun aplicarPresetSolo(preset: String) {
        val (k, a, vib) = when (preset) {
            "arenoso" -> Triple("65.0", "0.65", "5.0")
            "argiloso" -> Triple("30.0", "0.45", "0.8")
            else -> Triple("45.0", "0.55", "2.0")
        }
        updateState { it.copy(tipoSoloPreset = preset, k = k, a = a, vib = vib) }
    }

    fun atualizarK(valor: String) = atualizarSoloCustom { it.copy(k = valor) }

    fun atualizarA(valor: String) = atualizarSoloCustom { it.copy(a = valor) }

    fun atualizarVib(valor: String) = atualizarSoloCustom { it.copy(vib = valor) }

    private fun atualizarSoloCustom(transform: (WizardUiState) -> WizardUiState) {
        updateState { atual -> transform(atual).copy(tipoSoloPreset = "custom") }
    }

    // ---- Demais campos ------------------------------------------------------

    fun atualizarLamina(valor: String) = updateState { it.copy(lamina = valor) }

    fun atualizarComprimento(valor: String) = updateState { it.copy(comprimento = valor) }

    fun atualizarDesnivel(valor: String) = updateState { it.copy(desnivelM = valor) }

    fun atualizarDistanciaHorizontal(valor: String) =
        updateState { it.copy(distanciaHorizontalM = valor) }

    fun atualizarLarguraOuEspacamento(valor: String) =
        updateState { it.copy(larguraOuEspacamento = valor) }

    fun atualizarVazao(valor: String) = updateState { it.copy(vazao = valor) }

    fun atualizarTempo(valor: String) = updateState { it.copy(tempo = valor) }

    fun atualizarManningN(valor: String) = updateState { it.copy(manningN = valor) }

    // ---- Conversão para o domínio -------------------------------------------

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

    companion object {
        const val TOTAL_ETAPAS = 4
    }
}
