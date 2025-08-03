package com.example.parking_detector_plugin.service

import android.app.Service
import android.content.Intent
import android.os.IBinder
import com.example.parking_detector_plugin.ParkingDetectorPlugin
import com.example.parking_detector_plugin.core.Constants
import com.example.parking_detector_plugin.utils.AndroidActivityRecognitionProvider
import com.example.parking_detector_plugin.core.location.RealLocationProvider
import com.example.parking_detector_plugin.detector.ParkingState
import com.example.parking_detector_plugin.utils.AndroidNotificationHandler
import com.example.parking_detector_plugin.utils.AndroidBroadcastHandler
import com.example.parking_detector_plugin.utils.AndroidServiceLifecycleManager
import com.example.parking_detector_plugin.utils.AndroidLoggingHandler
import android.util.Log

class ParkingDetectionService : Service() {
    private lateinit var controller: ActivityTransitionController
    private var isRunning = false
    
    companion object {
        private var currentState: ParkingState? = null
        private const val TAG = "ParkingDetectionService"
        
        fun getCurrentState(): ParkingState? {
            return currentState
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate called")
        
        try {
            // Inicializar servicios
            val locationProvider = RealLocationProvider(this)
            val activityProvider = AndroidActivityRecognitionProvider(this)
            val notificationHandler = AndroidNotificationHandler(this)
            val broadcastHandler = AndroidBroadcastHandler(this)
            val serviceLifecycleManager = AndroidServiceLifecycleManager(this)
            val loggingHandler = AndroidLoggingHandler(Constants.TAG)
            
            // Crear controlador con callback personalizado para actualizar el estado
            controller = ActivityTransitionController(
                locationProvider,
                activityProvider,
                notificationHandler,
                broadcastHandler,
                serviceLifecycleManager,
                loggingHandler
            )
            
            // Override para el callback de estado del parking detector
            controller.setStateCallback { newState ->
                try {
                    // Actualizar estado global
                    currentState = newState
                    
                    // Enviar a Flutter a través del plugin
                    ParkingDetectorPlugin.getInstance()?.sendParkingStateEvent(newState)
                } catch (e: Exception) {
                    Log.e(TAG, "Error in state callback", e)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in onCreate", e)
            stopSelf()
        }
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand called")
        if (!isRunning) {
            try {
                controller.start()
                isRunning = true
            } catch (e: Exception) {
                Log.e(TAG, "Error starting controller", e)
                stopSelf()
                return START_NOT_STICKY
            }
        }
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onDestroy() {
        Log.d(TAG, "onDestroy called")
        try {
            if (isRunning) {
                controller.stop()
                isRunning = false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in onDestroy", e)
        } finally {
            super.onDestroy()
        }
    }
} 