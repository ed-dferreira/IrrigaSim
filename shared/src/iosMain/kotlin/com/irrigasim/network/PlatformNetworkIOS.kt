package com.irrigasim.network

import io.ktor.client.engine.*
import io.ktor.client.engine.ios.*

/**
 * Engine HTTP do iOS usando NSURLSession.
 */
actual fun createHttpClientEngine(): HttpClientEngine = Ios.create {
    // Configurações do NSURLSession
    configureSession {
        // Timeout
        it.timeoutIntervalForRequest = 15.0
        it.timeoutIntervalForResource = 30.0
    }

    // Configurações do engine
    request {
        // Headers
        headers.append("Accept", "application/json")
    }
}
