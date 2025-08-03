package com.example.parking_detector_plugin.service

import android.app.Service
import android.os.IBinder
import com.example.parking_detector_plugin.core.Constants
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

/**
 * Service que delega toda la lógica a ActivityTransitionController.
 */
class ActivityTransitionService : Service(), KoinComponent {
    private val serviceLifecycleManager: ServiceLifecycleManagerImpl by inject()
    private val controller: ActivityTransitionController by inject()

    override fun onCreate() {
        super.onCreate()
        // Register this service for foreground management
        serviceLifecycleManager.setService(this)
        controller.start()
    }

    override fun onStartCommand(intent: android.content.Intent?, flags: Int, startId: Int): Int {
        // Manejar stop action
        if (intent?.action == Constants.ACTION_STOP_SERVICE) {
            controller.stop()
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    override fun onDestroy() {
        controller.stop()
        super.onDestroy()
    }

    override fun onBind(intent: android.content.Intent?): IBinder? = null
}
