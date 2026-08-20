package com.irrigasim.ui.navigation

import androidx.compose.runtime.Composable

/**
 * Intercepta o botão/voltar do sistema enquanto [enabled] for verdadeiro.
 *
 * No Android delega ao `OnBackPressedDispatcher` da Activity; no iOS não há
 * botão físico de voltar, portanto a implementação é um no-op (a navegação de
 * volta acontece pelos botões visuais das telas).
 */
@Composable
internal expect fun BackPressHandler(enabled: Boolean = true, onBack: () -> Unit)
