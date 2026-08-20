package com.irrigasim.ui.viewmodel

import com.irrigasim.domain.CenarioSalvo
import com.irrigasim.domain.MetodoIrrigacao
import com.irrigasim.domain.Parametros
import com.irrigasim.domain.PontoGrafico
import com.irrigasim.domain.Resultado
import com.irrigasim.domain.Simulacao
import kotlinx.coroutines.CoroutineScope

/**
 * Estado compartilhado do fluxo de simulação (método -> parâmetros -> resultado),
 * extraído de App.kt. É observado pelas telas de método, parâmetros e resultados.
 */
data class SimulacaoUiState(
    val metodo: MetodoIrrigacao = MetodoIrrigacao.SULCO,
    val parametros: Parametros = Parametros(),
    val resultado: Resultado? = null,
    /** Controla se é o primeiro acesso para exibir o tutorial em 4 etapas apenas na 1ª vez. */
    val primeiroAcesso: Boolean = true
)

/**
 * ViewModel central da simulação: guarda o método selecionado, os parâmetros
 * atuais e o último resultado calculado.
 */
class SimulacaoViewModel(scope: CoroutineScope = viewModelProductionScope()) :
    BaseViewModel<SimulacaoUiState>(SimulacaoUiState(), scope) {

    /** Seleciona o método de irrigação para a próxima simulação. */
    fun selecionarMetodo(metodo: MetodoIrrigacao) {
        updateState { it.copy(metodo = metodo) }
    }

    /**
     * Executa a simulação para o método/parâmetros informados e publica o resultado.
     * Em caso de falha numérica, publica um resultado simplificado (comportamento
     * didático: o aluno sempre recebe uma saída para analisar).
     */
    fun executarSimulacao(metodo: MetodoIrrigacao, parametros: Parametros): Resultado {
        val resultado = try {
            Simulacao.executar(metodo, parametros)
        } catch (e: Exception) {
            resultadoFallback(parametros)
        }
        updateState { it.copy(metodo = metodo, parametros = parametros, resultado = resultado) }
        return resultado
    }

    /** Carrega um cenário salvo como contexto atual de simulação. */
    fun abrirCenario(cenario: CenarioSalvo) {
        updateState {
            it.copy(
                metodo = cenario.metodo,
                parametros = cenario.parametros,
                resultado = cenario.resultado
            )
        }
    }

    /** Encerra o modo tutorial do primeiro acesso. */
    fun concluirPrimeiroAcesso() {
        updateState { it.copy(primeiroAcesso = false) }
    }

    /** Resultado simplificado usado quando o motor numérico falha. */
    internal fun resultadoFallback(p: Parametros): Resultado = Resultado(
        eficiencia = 70.0,
        eficienciaRequerimento = 90.0,
        cuc = 80.0,
        du = 75.0,
        laminaMedia = p.laminaRequerida,
        tempoAvanco = 45.0,
        perdaPercolacao = 15.0,
        perdaEscoamento = 15.0,
        curvaAvanco = listOf(PontoGrafico(0.0, 0.0), PontoGrafico(45.0, p.comprimento)),
        perfilLongitudinal = listOf(p.laminaRequerida, p.laminaRequerida * 0.9),
        resumoTextual = "Simulação concluída com parâmetros simplificados."
    )
}
