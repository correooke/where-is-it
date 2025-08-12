package com.okecode.parking_detector_plugin

import android.app.Application
import com.okecode.parking_detector_plugin.di.appModule
import org.koin.android.ext.koin.androidContext
import org.koin.android.ext.koin.androidLogger
import org.koin.core.context.startKoin

class WhereIsItApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // 1. Inicializar Koin
        startKoin {
            androidLogger()
            androidContext(this@WhereIsItApplication)
            modules(appModule)
        }

    }
}