package com.irrigasim.ui.navigation

import androidx.compose.runtime.Composable

@Composable
internal actual fun BackPressHandler(enabled: Boolean, onBack: () -> Unit) {
    androidx.activity.compose.BackHandler(enabled = enabled, onBack = onBack)
}
