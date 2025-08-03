package com.example.parking_detector_plugin.di

import android.app.NotificationManager
import android.content.Context
import com.example.parking_detector_plugin.core.activity.ActivityRecognitionProvider
import com.example.parking_detector_plugin.core.activity.RealActivityRecognitionProvider
import com.example.parking_detector_plugin.core.location.LocationProvider
import com.example.parking_detector_plugin.core.location.RealLocationProvider
import com.example.parking_detector_plugin.service.*
import org.koin.android.ext.koin.androidContext
import org.koin.dsl.module

val appModule = module {
    // Core providers
    single<LocationProvider> { RealLocationProvider(androidContext()) }
    single<ActivityRecognitionProvider> { RealActivityRecognitionProvider(androidContext()) }

    // Service handlers
    single<NotificationHandler> { NotificationHandlerImpl() }
    single<BroadcastHandler> { BroadcastHandlerImpl() }
    single<ServiceLifecycleManager> { ServiceLifecycleManagerImpl() }
    single<LoggingHandler> { LoggingHandlerImpl() }

    // System services
    single { androidContext().getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager }

    // Controlador puro para la lógica del servicio
    single { ActivityTransitionController(
        get<LocationProvider>(),
        get<ActivityRecognitionProvider>(),
        get<NotificationHandler>(),
        get<BroadcastHandler>(),
        get<ServiceLifecycleManager>(),
        get<LoggingHandler>()
    ) }
} 