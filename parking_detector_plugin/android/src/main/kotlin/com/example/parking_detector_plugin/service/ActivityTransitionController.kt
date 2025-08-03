package com.example.parking_detector_plugin.service

import android.location.Location
import com.example.parking_detector_plugin.core.Constants
import com.example.parking_detector_plugin.core.activity.ActivityRecognitionProvider
import com.example.parking_detector_plugin.core.location.LocationDisabledException
import com.example.parking_detector_plugin.core.location.LocationPermissionException
import com.example.parking_detector_plugin.core.location.LocationProvider
import com.example.parking_detector_plugin.detector.ParkingDetector
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.DetectedActivity
import com.example.parking_detector_plugin.utils.toActivityName
import com.example.parking_detector_plugin.detector.VehicleTransition
import com.example.parking_detector_plugin.detector.ParkingState

/**
 * Controlador que orquesta la recolección de datos de sensores
 * y los envía al detector de estacionamiento.
 * Es completamente independiente de Android Service y 100% testeable.
 */
class ActivityTransitionController(
    private val locationProvider: LocationProvider,
    private val activityProvider: ActivityRecognitionProvider,
    private val notificationHandler: NotificationHandler,
    private val broadcastHandler: BroadcastHandler,
    private val serviceLifecycleManager: ServiceLifecycleManager,
    private val loggingHandler: LoggingHandler
) {
    private val parkingDetector: ParkingDetector
    private var stateCallback: ((ParkingState) -> Unit)? = null

    init {
        // Inicializar detector con callbacks de negocio
        parkingDetector = ParkingDetector { newState ->
            // Broadcast event for confirmed parked only
            broadcastHandler.sendParkingEvent(newState == ParkingState.CONFIRMED_PARKED)
            
            // Update notification based on state
            val message = when (newState) {
                ParkingState.DRIVING -> "Driving"
                ParkingState.TENTATIVE_PARKED -> "Possible parking detected"
                ParkingState.CONFIRMED_PARKED -> "Parked"
                else -> "Unknown"
            }
            notificationHandler.updateNotification(message)
            
            // Llamar al callback externo si está establecido
            stateCallback?.invoke(newState)
        }
    }

    /**
     * Permite establecer un callback externo para recibir eventos de estado
     */
    fun setStateCallback(callback: (ParkingState) -> Unit) {
        this.stateCallback = callback
    }

    /**
     * Arranca todo el orquestador: notificación y monitoreos.
     */
    fun start() {
        loggingHandler.debug("Starting ActivityTransitionController")
        notificationHandler.createNotificationChannel()
        val notif = notificationHandler.createNotification("Monitoring activity...")
        serviceLifecycleManager.startForeground(notif)

        // Ubicación - pasar datos crudos al detector
        locationProvider.requestLocationUpdates(
            onLocation = { location -> 
                parkingDetector.updateLocationData(location)
            },
            onError = { ex ->
                when (ex) {
                    is LocationPermissionException, is LocationDisabledException -> {
                        loggingHandler.error("Location error: ${ex.message}", ex)
                        stop()
                    }
                    else -> loggingHandler.error("Location error: ${ex.message}", ex)
                }
            }
        )

        // Transiciones de actividad
        val transitions = listOf(
            ActivityRecognitionProvider.TransitionSpec(
                DetectedActivity.IN_VEHICLE,
                ActivityTransition.ACTIVITY_TRANSITION_ENTER
            ),
            ActivityRecognitionProvider.TransitionSpec(
                DetectedActivity.IN_VEHICLE,
                ActivityTransition.ACTIVITY_TRANSITION_EXIT
            )
        )
        activityProvider.requestTransitions(transitions) { event ->
            loggingHandler.debug(
                "Transition: ${event.activityType.toActivityName()}, " +
                "type: ${if (event.transitionType == ActivityTransition.ACTIVITY_TRANSITION_ENTER) "ENTER" else "EXIT"}"
            )
            if (event.activityType == DetectedActivity.IN_VEHICLE) {
                // Pasar directamente al detector
                val transition = if (event.transitionType == ActivityTransition.ACTIVITY_TRANSITION_ENTER)
                    VehicleTransition.ENTER
                else
                    VehicleTransition.EXIT
                parkingDetector.handleActivityTransition(transition)
            }
        }

        // Polling de actividad
        activityProvider.requestPolling(Constants.POLLING_INTERVAL_MS) { type, confidence ->
            loggingHandler.debug("Activity: ${type.toActivityName()}, confidence: $confidence")
            // Pasar datos crudos al detector
            parkingDetector.updateActivityRecognition(type, confidence)
        }
    }

    /**
     * Detiene todos los flujos y limpia recursos.
     */
    fun stop() {
        loggingHandler.debug("Stopping ActivityTransitionController")
        locationProvider.removeUpdates()
        activityProvider.removeAll()
        serviceLifecycleManager.stopForeground()
    }
    
    /**
     * Permite acceder al estado actual del detector
     */
    fun getCurrentState(): ParkingState {
        return parkingDetector.getState()
    }
} 