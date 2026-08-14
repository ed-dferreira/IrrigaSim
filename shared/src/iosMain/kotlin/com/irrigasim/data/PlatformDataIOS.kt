package com.irrigasim.data

/**
 * Inicialização específica do iOS.
 */
actual fun createFirestoreSync(): FirestoreSync = FirestoreSyncIOS()

actual fun createAuthRepository(): AuthRepository = AuthRepositoryIOS()
