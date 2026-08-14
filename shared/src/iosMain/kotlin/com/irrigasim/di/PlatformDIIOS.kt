package com.irrigasim.di

import com.irrigasim.network.createHttpClient
import com.irrigasim.network.AuthApi
import com.irrigasim.network.CenarioApi
import com.irrigasim.network.UserApi
import com.irrigasim.data.datasource.CenarioLocalDataSource
import com.irrigasim.data.datasource.CenarioRemoteDataSource
import com.irrigasim.data.datasource.UserLocalDataSource
import com.irrigasim.data.datasource.UserRemoteDataSource
import com.irrigasim.data.datasource.AuthLocalDataSource
import org.koin.dsl.module

/**
 * Módulo Koin específico do iOS.
 */
actual val platformModule = module {
    // HTTP Client
    single { createHttpClient() }

    // APIs
    single { AuthApi(get()) }
    single { CenarioApi(get()) }
    single { UserApi(get()) }

    // Data Sources
    single { CenarioLocalDataSource() }
    single { CenarioRemoteDataSource(get()) }
    single { UserLocalDataSource() }
    single { UserRemoteDataSource(get()) }
    single { AuthLocalDataSource() }
}
