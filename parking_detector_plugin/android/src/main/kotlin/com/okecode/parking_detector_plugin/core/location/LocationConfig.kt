package com.okecode.parking_detector_plugin.core.location

import com.google.android.gms.location.Priority

data class LocationConfig(
    val updateIntervalMs: Long = 6000,
    val minUpdateIntervalMs: Long = 3000,
    val priority: Int = Priority.PRIORITY_HIGH_ACCURACY,
    val waitForAccurateLocation: Boolean = false
) 
