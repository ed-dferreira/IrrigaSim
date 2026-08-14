package com.irrigasim.data

import com.irrigasim.domain.RepositorioSimulacoes

actual fun criarRepositorioSimulacoes(): RepositorioSimulacoes = RepositorioSimulacoesMemoria()
