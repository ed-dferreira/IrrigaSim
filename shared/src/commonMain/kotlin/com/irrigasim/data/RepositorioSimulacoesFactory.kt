package com.irrigasim.data

import com.irrigasim.domain.MetodoIrrigacao
import com.irrigasim.domain.RepositorioSimulacoes
import com.irrigasim.domain.SimulacaoSalva

/** Implementação em memória para testes e iOS stub */
class RepositorioSimulacoesMemoria : RepositorioSimulacoes {
    private val itens = mutableListOf<SimulacaoSalva>()
    private var nextId = 1L

    override suspend fun listar(): List<SimulacaoSalva> = itens.sortedByDescending { it.dataMillis }

    override suspend fun salvar(
        metodo: MetodoIrrigacao,
        nome: String,
        parametrosJson: String,
        resultadoJson: String
    ): Long {
        val id = nextId++
        itens.add(
            SimulacaoSalva(
                id = id,
                metodo = metodo,
                nome = nome,
                dataMillis = System.currentTimeMillis(),
                parametrosJson = parametrosJson,
                resultadoJson = resultadoJson
            )
        )
        return id
    }

    override suspend fun buscarPorId(id: Long): SimulacaoSalva? = itens.find { it.id == id }

    override suspend fun excluir(id: Long) {
        itens.removeAll { it.id == id }
    }

    fun limpar() = itens.clear()
}

expect fun criarRepositorioSimulacoes(): RepositorioSimulacoes
