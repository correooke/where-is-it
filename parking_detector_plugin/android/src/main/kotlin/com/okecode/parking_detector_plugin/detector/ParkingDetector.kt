package com.okecode.parking_detector_plugin.detector

import android.location.Location
import com.okecode.parking_detector_plugin.core.Constants
import com.okecode.parking_detector_plugin.detector.ParkingState
import com.okecode.parking_detector_plugin.detector.VehicleTransition

/**
 * Class that encapsulates parking detection logic with clear state transitions.
 */
class ParkingDetector(
    private val onStateChanged: (ParkingState) -> Unit
) {
    private var currentState: ParkingState = ParkingState.UNKNOWN
    // Timestamp (ms) del último evento ENTER del vehículo. Ya no se usa como
    // compuerta para salir de CONFIRMED_PARKED: ahora dependemos solo de velocidad sostenida.
    private var lastVehicleEnterAtMs: Long? = null
    // Momento (ms) desde el cual la velocidad supera DRIVING_SPEED para exigir
    // una duración sostenida antes de confirmar el estado DRIVING
    private var drivingCandidateSinceMs: Long? = null

    /**
     * Processes raw location data to update parking state.
     */
    fun updateLocationData(location: Location?) {
        location?.let { loc ->
            val speed = loc.speed
            when {
                // Transition to DRIVING with robust conditions
                // 1) Histéresis por velocidad sostenida
                // 2) Si está CONFIRMED_PARKED, usar ventana sostenida más larga (sin depender de ENTER)
                (speed > Constants.DRIVING_SPEED) -> {
                    val now = System.currentTimeMillis()
                    if (drivingCandidateSinceMs == null) {
                        drivingCandidateSinceMs = now
                    }
                    val window = if (currentState == ParkingState.CONFIRMED_PARKED) {
                        Constants.CONFIRMED_TO_DRIVING_SUSTAINED_WINDOW_MS
                    } else {
                        Constants.DRIVING_CONFIRMATION_WINDOW_MS
                    }
                    val sustained = (now - (drivingCandidateSinceMs ?: now)) >= window

                    if (sustained) {
                        setDriving()
                    }
                }
                // From DRIVING to TENTATIVE_PARKED when speed drops below STOP_SPEED
                (currentState == ParkingState.DRIVING && speed < Constants.STOP_SPEED) -> setTentativeParked()
                // Recover driving if speed rises again
                (currentState == ParkingState.TENTATIVE_PARKED && speed > Constants.DRIVING_SPEED) -> setDriving()
                // No other transitions on location data
            }

            if (speed <= Constants.DRIVING_SPEED) {
                drivingCandidateSinceMs = null
            }
        }
    }

    /**
     * Processes a vehicle enter/exit transition for driving detection.
     */
    fun handleActivityTransition(transition: VehicleTransition) {
        when (transition) {
            VehicleTransition.ENTER -> {
                lastVehicleEnterAtMs = System.currentTimeMillis()
                setDriving()
            }
            VehicleTransition.EXIT -> {
                // no-op; potential exit handling in future
            }
        }
    }

    /**
     * Processes activity recognition results for tentative or confirmed parked states.
     */
    fun updateActivityRecognition(activityType: Int, confidence: Int) {
        when {
            // Tentative parked on STILL activity
            currentState == ParkingState.DRIVING
                && activityType == Constants.STILL_ACTIVITY
                && confidence > Constants.ACTIVITY_CONFIDENCE_THRESHOLD -> setTentativeParked()

            // Confirmed parked after tentative when confirmation activity detected
            currentState == ParkingState.TENTATIVE_PARKED
                && activityType in Constants.CONFIRM_ACTIVITIES
                && confidence > Constants.ACTIVITY_CONFIDENCE_THRESHOLD -> setConfirmedParked()

            else -> {
                // No-op
            }
        }
    }

    /**
     * Force set a specific state (for manual triggers).
     */
    fun setState(newState: ParkingState) {
        when (newState) {
            ParkingState.DRIVING -> setDriving()
            ParkingState.TENTATIVE_PARKED -> setTentativeParked()
            ParkingState.CONFIRMED_PARKED -> setConfirmedParked()
            ParkingState.UNKNOWN -> {
                currentState = ParkingState.UNKNOWN
                onStateChanged(ParkingState.UNKNOWN)
            }
        }
    }

    /**
     * Returns the current parking state.
     */
    fun getState(): ParkingState = currentState

    private fun setDriving() {
        if (currentState != ParkingState.DRIVING) {
            currentState = ParkingState.DRIVING
            onStateChanged(ParkingState.DRIVING)
        }
    }

    private fun setTentativeParked() {
        if (currentState != ParkingState.TENTATIVE_PARKED) {
            currentState = ParkingState.TENTATIVE_PARKED
            onStateChanged(ParkingState.TENTATIVE_PARKED)
        }
    }

    private fun setConfirmedParked() {
        if (currentState != ParkingState.CONFIRMED_PARKED) {
            currentState = ParkingState.CONFIRMED_PARKED
            onStateChanged(ParkingState.CONFIRMED_PARKED)
        }
    }
} 
