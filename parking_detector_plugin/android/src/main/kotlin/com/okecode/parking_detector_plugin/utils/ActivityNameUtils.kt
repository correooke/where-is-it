package com.okecode.parking_detector_plugin.utils

import com.google.android.gms.location.DetectedActivity

/**
 * Extension to get readable name for DetectedActivity types.
 */
fun Int.toActivityName(): String = when (this) {
    DetectedActivity.IN_VEHICLE -> "IN_VEHICLE"
    DetectedActivity.ON_BICYCLE -> "ON_BICYCLE"
    DetectedActivity.ON_FOOT -> "ON_FOOT"
    DetectedActivity.WALKING -> "WALKING"
    DetectedActivity.RUNNING -> "RUNNING"
    DetectedActivity.STILL -> "STILL"
    DetectedActivity.TILTING -> "TILTING"
    else -> "UNKNOWN"
} 
