package com.irrigasim.ui.navigation

import androidx.compose.runtime.Composable

/**
 * iOS não possui botão de voltar do sistema: o retorno é feito pelos botões
 * visuais das telas (`onVoltar`), então a interceptação é desnecessária.
 */
@Composable
internal actual fun BackPressHandler(enabled: Boolean, onBack: () -> Unit) {
    // no-op
}
