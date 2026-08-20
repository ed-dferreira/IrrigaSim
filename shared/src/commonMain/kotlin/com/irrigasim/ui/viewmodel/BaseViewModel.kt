package com.irrigasim.ui.viewmodel

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * Escopo padrão de produção dos ViewModels (`Dispatchers.Main.immediate`).
 * Testes devem injetar um escopo próprio para não depender do dispatcher Main.
 */
fun viewModelProductionScope(): CoroutineScope =
    CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

/**
 * Base para todos os ViewModels do aplicativo (padrão MVVM).
 *
 * Cada ViewModel expõe um único objeto de estado imutável via [state] (StateFlow)
 * e concentra toda a lógica de estado da tela. O estado só é modificado pelas
 * funções públicas do ViewModel (intenção -> novo estado), nunca diretamente
 * pela UI.
 *
 * O escopo de corrotinas é injetável para facilitar testes; em produção o
 * provedor manual ([rememberViewModel]) usa [viewModelProductionScope] e
 * cancela o escopo em [onCleared] quando a tela sai da composição.
 */
abstract class BaseViewModel<S>(
    initialState: S,
    scope: CoroutineScope = viewModelProductionScope()
) {

    /** Escopo do ViewModel, análogo a `viewModelScope` do AndroidX Lifecycle. */
    protected val viewModelScope: CoroutineScope = scope

    private val _state = MutableStateFlow(initialState)

    /** Estado observável da tela. */
    val state: StateFlow<S> = _state.asStateFlow()

    /** Valor atual do estado, para leitura síncrona. */
    protected val currentState: S
        get() = _state.value

    /** Aplica uma transformação atômica sobre o estado atual. */
    protected fun updateState(transform: (S) -> S) {
        _state.update(transform)
    }

    /** Executa [block] no escopo do ViewModel. */
    protected fun launchOnViewModelScope(block: suspend CoroutineScope.() -> Unit) {
        viewModelScope.launch(block = block)
    }

    /** Libera recursos; chamado pelo provedor manual quando a tela sai da composição. */
    open fun onCleared() {
        viewModelScope.cancel()
    }
}

/**
 * Provedor manual de ViewModel (sem DI/Hilt): cria a instância uma única vez
 * por composição e chama [BaseViewModel.onCleared] quando ela sai da composição.
 */
@Composable
fun <VM : BaseViewModel<*>> rememberViewModel(create: () -> VM): VM {
    val viewModel = remember { create() }
    DisposableEffect(viewModel) {
        onDispose { viewModel.onCleared() }
    }
    return viewModel
}
