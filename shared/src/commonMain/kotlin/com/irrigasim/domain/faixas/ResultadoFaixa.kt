package com.irrigasim.domain.faixas

data class PontoAvanco(val tempoMinutos: Double, val distanciaMetros: Double)

data class ResultadoVazaoTestada(
    val vazaoLsPorMetro: Double,
    val tempoAvancoMin: Double,
    val tempoOportunidadeMedioMin: Double,
    val eficienciaAplicacao: Double
)

data class ResultadoFaixa(
    /** Eficiência de aplicação Ea (%) */
    val eficienciaAplicacao: Double,
    /** Eficiência de requerimento Er (%) */
    val eficienciaRequerimento: Double,
    /** Perdas por percolação profunda Pp (%) */
    val perdaPercolacao: Double,
    /** Perdas por escoamento/excesso Pe (%) */
    val perdaEscoamento: Double,
    /** Vazão máxima Qmáx — Hart et al. (m³/min/m) */
    val vazaoMaxima: Double,
    /** Vazão mínima Qmín — Walker & Skogerboe (L/s/m) */
    val vazaoMinima: Double,
    /** Tempo de avanço ta (min) */
    val tempoAvanco: Double,
    /** Tempo médio de oportunidade taméd (min) */
    val tempoOportunidadeMedio: Double,
    /** Lâmina média aplicada (mm) */
    val laminaMediaAplicada: Double,
    /** Curva de avanço x(t) */
    val curvaAvanco: List<PontoAvanco>,
    /** Resultados para vazões candidatas testadas */
    val vazoesTestadas: List<ResultadoVazaoTestada>,
    /** Melhor vazão entre candidatas (L/s/m), se houver */
    val melhorVazao: Double?,
    /** Resumo textual didático */
    val resumoTextual: String,
    /** Alerta se vazão de projeto excede disponível */
    val alertaVazaoExcedida: Boolean = false
)
