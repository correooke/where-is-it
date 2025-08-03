package com.example.parking_detector_plugin.core.location

import android.location.Location
import android.os.Looper
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.tasks.Task

class FusedLocationClientWrapper(
    private val fusedLocationClient: FusedLocationProviderClient
) : LocationClient {
    override fun requestLocationUpdates(
        config: LocationConfig,
        callback: LocationCallback,
        looper: Looper
    ) {
        val locationRequest = LocationRequest.create().apply {
            priority = config.priority
            interval = config.updateIntervalMs
            fastestInterval = config.minUpdateIntervalMs
        }

        fusedLocationClient.requestLocationUpdates(locationRequest, callback, looper)
    }

    override fun removeLocationUpdates(callback: LocationCallback) {
        fusedLocationClient.removeLocationUpdates(callback)
    }

    override fun getLastLocation(): Task<Location> {
        return fusedLocationClient.lastLocation
    }
} 