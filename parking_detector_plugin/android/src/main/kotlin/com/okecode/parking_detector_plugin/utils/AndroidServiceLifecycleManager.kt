package com.okecode.parking_detector_plugin.utils

import android.app.Notification
import android.app.Service
import com.okecode.parking_detector_plugin.service.ServiceLifecycleManager

class AndroidServiceLifecycleManager(private val service: Service) : ServiceLifecycleManager {
    companion object {
        private const val NOTIFICATION_ID = 1001
    }

    override fun startForeground(notification: Notification) {
        service.startForeground(NOTIFICATION_ID, notification)
    }

    override fun stopForeground() {
        service.stopForeground(true)
    }
} 
