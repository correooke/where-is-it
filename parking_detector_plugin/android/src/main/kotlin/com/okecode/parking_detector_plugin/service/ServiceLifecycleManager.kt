package com.okecode.parking_detector_plugin.service

import android.app.Notification
import android.app.Service
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

interface ServiceLifecycleManager {
    fun startForeground(notification: Notification)
    fun stopForeground()
}

class ServiceLifecycleManagerImpl : KoinComponent, ServiceLifecycleManager {
    private var currentService: Service? = null

    fun setService(service: Service) {
        currentService = service
    }

    override fun startForeground(notification: Notification) {
        currentService?.startForeground(1, notification)
    }

    override fun stopForeground() {
        currentService?.stopForeground(true)
    }
} 
