package com.irrigasim.domain

import com.irrigasim.domain.faixas.ParametrosFaixa
import com.irrigasim.domain.faixas.SimulacaoFaixas
import com.irrigasim.domain.indicadores.IndicadoresDesempenho
import com.irrigasim.domain.inundacao.ParametrosInundacao
import com.irrigasim.domain.inundacao.SimulacaoInundacao
import com.irrigasim.domain.sulcos.ParametrosSulco
import com.irrigasim.domain.sulcos.SimulacaoSulcos

enum class MetodoIrrigacao {
    SULCO, FAIXA, INUNDACAO;

    val nome: String
        get() = when (this) {
            SULCO -> "Sulcos"
            FAIXA -> "Faixa (Border)"
            INUNDACAO -> "Inundação / Bacia"
        }

    val disponivel: Boolean
        get() = true // Todos os 3 métodos disponíveis!

    companion object {
        fun fromString(valor: String): MetodoIrrigacao = when (valor.lowercase().trim()) {
            "sulco", "furrow", "sulcos" -> SULCO
            "faixa", "border", "faixas" -> FAIXA
            "bacia", "inundação", "inundacao", "basin" -> INUNDACAO
            else -> throw IllegalArgumentException("Método inválido: $valor")
        }
    }
}

/**
 * Parâmetros genéricos unificados para interface UI.
 */
data class Parametros(
    val comprimento: Double = 100.0,
    val declividade: Double = 0.5, // em percentual % (ex: 0.5%)
    val larguraOuEspacamento: Double = 0.8, // largura para faixa, espaçamento para sulco
    val k: Double = 45.0,
    val a: Double = 0.55,
    val vib: Double = 2.0,
    val vazao: Double = 0.6,
    val tempoAplicacao: Double = 90.0,
    val laminaRequerida: Double = 50.0,
    val manningN: Double = 0.04,
    val sigmaZ: Double = 0.25
)

/**
 * Ponto para gráficos 2D.
 */
data class PontoGrafico(val x: Double, val y: Double)

/**
 * Resultado unificado para exibição gráfica e numérica na UI.
 */
data class Resultado(
    val eficiencia: Double,            // Ea (%)
    val eficienciaRequerimento: Double = 100.0, // Er (%)
    val cuc: Double = 85.0,            // CUC (%)
    val du: Double = 80.0,             // DU (%)
    val laminaMedia: Double,           // mm
    val tempoAvanco: Double,           // min
    val perdaPercolacao: Double,       // %
    val perdaEscoamento: Double,       // %
    val vazaoMaxima: Double = 0.0,
    val vazaoMinima: Double = 0.0,
    val curvaAvanco: List<PontoGrafico> = emptyList(),
    val perfilLongitudinal: List<Double> = emptyList(),
    val resumoTextual: String = "",
    val alertaVazaoExcedida: Boolean = false
)

/**
 * Motor central de simulação que delega para o método escolhido.
 */
object Simulacao {
    fun executar(metodo: MetodoIrrigacao, p: Parametros): Resultado {
        val declividadeFracao = p.declividade / 100.0

        return when (metodo) {
            MetodoIrrigacao.FAIXA -> {
                val pFaixa = ParametrosFaixa(
                    k = p.k,
                    a = p.a,
                    vib = p.vib,
                    comprimento = p.comprimento,
                    largura = p.larguraOuEspacamento,
                    declividade = declividadeFracao,
                    manningN = p.manningN,
                    laminaRequerida = p.laminaRequerida,
                    vazaoEntrada = p.vazao,
                    tempoAplicacao = p.tempoAplicacao,
                    sigmaZ = p.sigmaZ
                )
                val resFaixa = SimulacaoFaixas.executar(pFaixa)

                // Gera perfil longitudinal se não presente
                val perfil = IndicadoresDesempenho.perfilLongitudinal(
                    tauMontanteMin = p.tempoAplicacao + resFaixa.tempoOportunidadeMedio * 0.5,
                    tauJusanteMin = (p.tempoAplicacao - resFaixa.tempoAvanco).coerceAtLeast(0.0),
                    k = p.k, a = p.a, vib = p.vib, nPontos = 20
                )
                val cucVal = IndicadoresDesempenho.cuc(perfil)
                val duVal = IndicadoresDesempenho.du(perfil)

                Resultado(
                    eficiencia = resFaixa.eficienciaAplicacao,
                    eficienciaRequerimento = resFaixa.eficienciaRequerimento,
                    cuc = cucVal,
                    du = duVal,
                    laminaMedia = resFaixa.laminaMediaAplicada,
                    tempoAvanco = resFaixa.tempoAvanco,
                    perdaPercolacao = resFaixa.perdaPercolacao,
                    perdaEscoamento = resFaixa.perdaEscoamento,
                    vazaoMaxima = resFaixa.vazaoMaxima,
                    vazaoMinima = resFaixa.vazaoMinima,
                    curvaAvanco = resFaixa.curvaAvanco.map { PontoGrafico(it.tempoMinutos, it.distanciaMetros) },
                    perfilLongitudinal = perfil,
                    resumoTextual = resFaixa.resumoTextual,
                    alertaVazaoExcedida = resFaixa.alertaVazaoExcedida
                )
            }

            MetodoIrrigacao.SULCO -> {
                val pSulco = ParametrosSulco(
                    k = p.k,
                    a = p.a,
                    vib = p.vib,
                    comprimento = p.comprimento,
                    espacamento = p.larguraOuEspacamento,
                    declividade = declividadeFracao,
                    manningN = p.manningN,
                    laminaRequerida = p.laminaRequerida,
                    vazaoEntrada = p.vazao,
                    tempoAplicacao = p.tempoAplicacao,
                    sigmaZ = p.sigmaZ
                )
                val resSulco = SimulacaoSulcos.executar(pSulco)

                Resultado(
                    eficiencia = resSulco.eficienciaAplicacao,
                    eficienciaRequerimento = resSulco.eficienciaRequerimento,
                    cuc = resSulco.cuc,
                    du = resSulco.du,
                    laminaMedia = resSulco.laminaMediaAplicada,
                    tempoAvanco = resSulco.tempoAvanco,
                    perdaPercolacao = resSulco.perdaPercolacao,
                    perdaEscoamento = resSulco.perdaEscoamento,
                    vazaoMaxima = resSulco.vazaoMaxima,
                    curvaAvanco = resSulco.curvaAvanco.map { PontoGrafico(it.tempoMinutos, it.distanciaMetros) },
                    perfilLongitudinal = resSulco.perfilLongitudinal,
                    resumoTextual = resSulco.resumoTextual
                )
            }

            MetodoIrrigacao.INUNDACAO -> {
                val pInund = ParametrosInundacao(
                    k = p.k,
                    a = p.a,
                    vib = p.vib,
                    comprimento = p.comprimento,
                    largura = p.larguraOuEspacamento,
                    declividade = declividadeFracao,
                    laminaRequerida = p.laminaRequerida,
                    vazaoEntrada = p.vazao,
                    tempoAplicacao = p.tempoAplicacao
                )
                val resInund = SimulacaoInundacao.executar(pInund)

                Resultado(
                    eficiencia = resInund.eficienciaAplicacao,
                    eficienciaRequerimento = resInund.eficienciaRequerimento,
                    cuc = resInund.cuc,
                    du = resInund.du,
                    laminaMedia = resInund.laminaMediaAplicada,
                    tempoAvanco = resInund.tempoEnchimentoMin,
                    perdaPercolacao = resInund.perdaPercolacao,
                    perdaEscoamento = resInund.perdaEscoamento,
                    curvaAvanco = resInund.curvaTempoLamina.map { PontoGrafico(it.tempoMinutos, it.laminaInfiltradaMm) },
                    perfilLongitudinal = resInund.perfilLongitudinal,
                    resumoTextual = resInund.resumoTextual
                )
            }
        }
    }
}

/** Usuario autenticado no app */
data class Usuario(
    val uid: String,
    val nome: String,
    val email: String,
    val fotoUrl: String? = null,
    val instituicao: String? = null,
    val curso: String? = null
)

/** Simulação salva localmente pelo usuário */
data class SimulacaoSalva(
    val id: Long,
    val metodo: MetodoIrrigacao,
    val nome: String,
    val dataMillis: Long,
    val parametrosJson: String,
    val resultadoJson: String
)

interface RepositorioSimulacoes {
    suspend fun listar(): List<SimulacaoSalva>
    suspend fun salvar(metodo: MetodoIrrigacao, nome: String, parametrosJson: String, resultadoJson: String): Long
    suspend fun buscarPorId(id: Long): SimulacaoSalva?
    suspend fun excluir(id: Long)
}

/** Modelo de cenário salvo na UI */
data class CenarioSalvo(
    val id: String,
    val titulo: String,
    val dataHora: String,
    val metodo: MetodoIrrigacao,
    val parametros: Parametros,
    val resultado: Resultado
)

