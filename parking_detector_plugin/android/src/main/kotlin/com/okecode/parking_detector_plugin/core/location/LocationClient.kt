package com.okecode.parking_detector_plugin.core.location

import android.location.Location
import android.os.Looper
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.tasks.Task

interface LocationClient {
    fun requestLocationUpdates(
        config: LocationConfig,
        callback: LocationCallback,
        looper: Looper
    )
    fun removeLocationUpdates(callback: LocationCallback)
    fun getLastLocation(): Task<Location>
} 
