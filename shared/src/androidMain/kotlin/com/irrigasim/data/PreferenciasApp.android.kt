package com.irrigasim.data

private var onboardingVistoMem = false

actual object PreferenciasApp {
    actual fun onboardingVisto(): Boolean = onboardingVistoMem
    actual fun marcarOnboardingVisto() { onboardingVistoMem = true }
}
