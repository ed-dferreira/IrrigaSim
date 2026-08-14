package com.irrigasim.di

import org.koin.core.context.startKoin
import org.koin.dsl.KoinAppDeclaration

/**
 * Inicializa Koin para iOS.
 */
actual fun initKoin(config: KoinAppDeclaration?) {
    startKoin {
        modules(appModule, platformModule)
        config?.invoke(this)
    }
}
