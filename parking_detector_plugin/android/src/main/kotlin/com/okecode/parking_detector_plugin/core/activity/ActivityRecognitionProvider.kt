package com.okecode.parking_detector_plugin.core.activity

import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.DetectedActivity

/**
 * Interfaz para abstraer la detección de actividad y facilitar el testing.
 */
interface ActivityRecognitionProvider {
    data class TransitionSpec(
        val activityType: Int,
        val transitionType: Int
    )

    data class TransitionEvent(
        val activityType: Int,
        val transitionType: Int
    )

    fun requestTransitions(
        transitions: List<TransitionSpec>,
        onEvent: (TransitionEvent) -> Unit
    )

    fun requestPolling(
        intervalMs: Long,
        onResult: (activityType: Int, confidence: Int) -> Unit
    )

    fun removeAll()

    /**
     * Inicia las actualizaciones de transición de actividad usando la configuración por defecto.
     */
    fun startActivityTransitionUpdates()

    /**
     * Detiene las actualizaciones de transición de actividad.
     */
    fun stopActivityTransitionUpdates()
} 
