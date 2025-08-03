package com.example.parking_detector_plugin.core.activity

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.example.parking_detector_plugin.core.Constants
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.ActivityTransitionEvent
import com.google.android.gms.location.ActivityTransitionResult
import com.google.android.gms.location.DetectedActivity

/**
 * Receptor de difusión para manejar las transiciones de actividad.
 */
class TransitionBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (ActivityTransitionResult.hasResult(intent)) {
            val result = ActivityTransitionResult.extractResult(intent)
            result?.let {
                for (event in it.transitionEvents) {
                    handleTransitionEvent(context, event)
                }
            }
        }
    }

    private fun handleTransitionEvent(context: Context, event: ActivityTransitionEvent) {
        val activityType = when (event.activityType) {
            DetectedActivity.IN_VEHICLE -> "IN_VEHICLE"
            DetectedActivity.STILL -> "STILL"
            else -> "UNKNOWN"
        }

        val transitionType = when (event.transitionType) {
            ActivityTransition.ACTIVITY_TRANSITION_ENTER -> "ENTER"
            ActivityTransition.ACTIVITY_TRANSITION_EXIT -> "EXIT"
            else -> "UNKNOWN"
        }

        Log.d(Constants.TAG, "Activity Transition: $activityType $transitionType")
        
        // Enviar un broadcast local para que el servicio pueda actualizar su estado
        val localIntent = Intent(Constants.ACTION_ACTIVITY_TRANSITION_UPDATE)
        localIntent.putExtra(Constants.EXTRA_ACTIVITY_TYPE, event.activityType)
        localIntent.putExtra(Constants.EXTRA_TRANSITION_TYPE, event.transitionType)
        context.sendBroadcast(localIntent)

        // Notificar a todos los listeners registrados
        ActivityRecognitionCallbacks.notifyTransitionListeners(
            ActivityRecognitionProvider.TransitionEvent(
                activityType = event.activityType,
                transitionType = event.transitionType
            )
        )
    }
} 