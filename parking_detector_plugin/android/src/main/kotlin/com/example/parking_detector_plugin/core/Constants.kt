package com.example.parking_detector_plugin.core

import com.google.android.gms.location.DetectedActivity

/**
 * Constantes utilizadas en toda la aplicación.
 */
object Constants {
    const val TAG = "WhereIsIt"
    
    // Notificaciones
    const val NOTIFICATION_CHANNEL_ID = "activity_transition_channel"
    const val NOTIFICATION_ID = 1001
    
    // Intents y acciones
    const val ACTION_START_SERVICE = "com.example.where_is_it.START_SERVICE"
    const val ACTION_STOP_SERVICE = "com.example.where_is_it.STOP_SERVICE"
    const val ACTION_ACTIVITY_TRANSITION_UPDATE = "com.example.where_is_it.ACTIVITY_TRANSITION_UPDATE"
    
    // Extras
    const val EXTRA_ACTIVITY_TYPE = "activity_type"
    const val EXTRA_TRANSITION_TYPE = "transition_type"
    
    // Ubicación
    const val LOCATION_UPDATE_INTERVAL = 30000L  // 30 segundos

    const val CHANNEL_ID = "parking_channel"
    const val NOTIF_ID = 12345
    const val POLLING_INTERVAL_MS = 5000L
    const val ACTION_PARKING_DATA = "com.example.where_is_it.PARKING_DATA"

    // Umbrales (m/s)
    // STOP_SPEED ≈ 0.5 m/s (~1.8 km/h) para tolerar pequeñas variaciones/ruido
    const val STOP_SPEED = 0.1f
    // DRIVING_SPEED ≈ 3.5 m/s (~12.6 km/h) por encima de caminar/trote
    const val DRIVING_SPEED = 0.7f

    // Activity detection thresholds
    const val STILL_ACTIVITY = com.google.android.gms.location.DetectedActivity.STILL
    const val ACTIVITY_CONFIDENCE_THRESHOLD = 70

    // Broadcast actions
    const val ACTION_PARKING_STATE_CHANGED = "com.example.where_is_it.ACTION_PARKING_STATE_CHANGED"
    
    // Broadcast extras
    const val EXTRA_IS_PARKED = "is_parked"

    val CONFIRM_ACTIVITIES = setOf(
        DetectedActivity.ON_FOOT,
        DetectedActivity.WALKING,
        DetectedActivity.RUNNING,
        DetectedActivity.ON_BICYCLE
    )
} 