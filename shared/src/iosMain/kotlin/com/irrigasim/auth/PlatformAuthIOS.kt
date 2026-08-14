package com.irrigasim.auth

/**
 * Inicialização específica do iOS para auth.
 */
actual fun createAuthManager(): AuthManager = AuthManagerIOS()
