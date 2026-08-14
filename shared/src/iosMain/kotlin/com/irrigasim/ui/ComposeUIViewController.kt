package com.irrigasim.ui

import androidx.compose.ui.window.ComposeUIViewController

/**
 * Cria o UIViewController para o Compose Multiplatform no iOS.
 * Esta função é chamada pelo SwiftUI.
 */
fun MainViewController() = ComposeUIViewController { IrrigaSIMApp() }
