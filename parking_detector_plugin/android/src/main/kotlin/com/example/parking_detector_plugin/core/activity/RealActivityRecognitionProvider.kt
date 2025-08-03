package com.example.parking_detector_plugin.core.activity

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.util.Log
import com.example.parking_detector_plugin.core.Constants
import com.google.android.gms.location.ActivityRecognition
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.ActivityTransitionRequest
import com.google.android.gms.location.DetectedActivity

/**
 * Implementación real del proveedor de reconocimiento de actividad usando ActivityRecognitionClient.
 */
class RealActivityRecognitionProvider(private val context: Context) : ActivityRecognitionProvider {
    private val activityRecognitionClient = ActivityRecognition.getClient(context)
    private val transitionReceiver = TransitionBroadcastReceiver()
    private val pollingReceiver = PollingBroadcastReceiver()
    private var transitionPendingIntent: PendingIntent? = null
    private var pollingPendingIntent: PendingIntent? = null

    private val defaultTransitions = listOf(
        ActivityTransition.Builder()
            .setActivityType(DetectedActivity.IN_VEHICLE)
            .setActivityTransition(ActivityTransition.ACTIVITY_TRANSITION_ENTER)
            .build(),
        ActivityTransition.Builder()
            .setActivityType(DetectedActivity.IN_VEHICLE)
            .setActivityTransition(ActivityTransition.ACTIVITY_TRANSITION_EXIT)
            .build(),
        ActivityTransition.Builder()
            .setActivityType(DetectedActivity.STILL)
            .setActivityTransition(ActivityTransition.ACTIVITY_TRANSITION_ENTER)
            .build(),
        ActivityTransition.Builder()
            .setActivityType(DetectedActivity.STILL)
            .setActivityTransition(ActivityTransition.ACTIVITY_TRANSITION_EXIT)
            .build()
    )

    private val defaultTransitionRequest = ActivityTransitionRequest(defaultTransitions)

    override fun requestTransitions(
        transitions: List<ActivityRecognitionProvider.TransitionSpec>,
        onEvent: (ActivityRecognitionProvider.TransitionEvent) -> Unit
    ) {
        // Registrar el listener en el sistema de callbacks
        ActivityRecognitionCallbacks.addTransitionListener(onEvent)

        // Registra el receptor si aún no lo está
        try {
            context.unregisterReceiver(transitionReceiver)
        } catch (e: IllegalArgumentException) {
            // Ignorar si no estaba registrado
        }
        
        val filter = IntentFilter("com.example.where_is_it.ACTIVITY_TRANSITION")
        context.registerReceiver(transitionReceiver, filter)

        // Crea un PendingIntent para el receptor
        val intent = Intent("com.example.where_is_it.ACTIVITY_TRANSITION")
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        transitionPendingIntent = PendingIntent.getBroadcast(
            context, 0, intent, flags
        )

        // Crea la solicitud de transición
        val transitionList = transitions.map { spec ->
            ActivityTransition.Builder()
                .setActivityType(spec.activityType)
                .setActivityTransition(spec.transitionType)
                .build()
        }
        
        val transitionRequest = ActivityTransitionRequest(transitionList)

        // Solicita las actualizaciones
        activityRecognitionClient.requestActivityTransitionUpdates(
            transitionRequest,
            transitionPendingIntent!!
        ).addOnFailureListener { e ->
            Log.e(Constants.TAG, "Error al solicitar actualizaciones de transición", e)
        }
    }

    override fun requestPolling(
        intervalMs: Long,
        onResult: (activityType: Int, confidence: Int) -> Unit
    ) {
        // Registrar el listener en el sistema de callbacks
        ActivityRecognitionCallbacks.addPollingListener(onResult)

        // Registra el receptor si aún no lo está
        try {
            context.unregisterReceiver(pollingReceiver)
        } catch (e: IllegalArgumentException) {
            // Ignorar si no estaba registrado
        }
        
        val filter = IntentFilter("com.example.where_is_it.ACTIVITY_UPDATES")
        context.registerReceiver(pollingReceiver, filter)

        // Crea un PendingIntent para el receptor
        val intent = Intent("com.example.where_is_it.ACTIVITY_UPDATES")
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        pollingPendingIntent = PendingIntent.getBroadcast(
            context, 1, intent, flags
        )

        // Solicita las actualizaciones
        activityRecognitionClient.requestActivityUpdates(
            intervalMs,
            pollingPendingIntent!!
        ).addOnFailureListener { e ->
            Log.e(Constants.TAG, "Error al solicitar actualizaciones de actividad", e)
        }
    }

    override fun removeAll() {
        // Cancela las solicitudes de transición
        transitionPendingIntent?.let { pendingIntent ->
            activityRecognitionClient.removeActivityTransitionUpdates(pendingIntent)
            pendingIntent.cancel()
            transitionPendingIntent = null
        }

        // Cancela las solicitudes de polling
        pollingPendingIntent?.let { pendingIntent ->
            activityRecognitionClient.removeActivityUpdates(pendingIntent)
            pendingIntent.cancel()
            pollingPendingIntent = null
        }

        // Desregistra los receptores
        try {
            context.unregisterReceiver(transitionReceiver)
        } catch (e: IllegalArgumentException) {
            // Ignorar si no estaba registrado
        }

        try {
            context.unregisterReceiver(pollingReceiver)
        } catch (e: IllegalArgumentException) {
            // Ignorar si no estaba registrado
        }

        // Limpia todos los callbacks
        ActivityRecognitionCallbacks.clearAll()
    }

    override fun startActivityTransitionUpdates() {
        try {
            // Usar las transiciones por defecto
            activityRecognitionClient.requestActivityTransitionUpdates(
                defaultTransitionRequest,
                transitionPendingIntent!!
            ).addOnSuccessListener {
                Log.d(Constants.TAG, "Successfully registered for activity transition updates")
            }.addOnFailureListener { e ->
                Log.e(Constants.TAG, "Failed to register for activity transition updates", e)
            }
        } catch (e: Exception) {
            Log.e(Constants.TAG, "Exception registering for activity transition updates", e)
        }
    }

    override fun stopActivityTransitionUpdates() {
        try {
            transitionPendingIntent?.let { pendingIntent ->
                activityRecognitionClient.removeActivityTransitionUpdates(pendingIntent)
                    .addOnSuccessListener {
                        Log.d(Constants.TAG, "Successfully removed activity transition updates")
                    }
                    .addOnFailureListener { e ->
                        Log.e(Constants.TAG, "Failed to remove activity transition updates", e)
                    }
            }
        } catch (e: Exception) {
            Log.e(Constants.TAG, "Exception removing activity transition updates", e)
        }
    }
} 