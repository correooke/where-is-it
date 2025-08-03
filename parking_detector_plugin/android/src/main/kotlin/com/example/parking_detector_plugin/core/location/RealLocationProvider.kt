package com.example.parking_detector_plugin.core.location

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Looper
import android.util.Log
import androidx.core.app.ActivityCompat
import com.example.parking_detector_plugin.core.Constants
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority

/**
 * Implementación real del proveedor de ubicación.
 * Esta clase maneja la obtención de actualizaciones de ubicación y proporciona
 * funcionalidades para verificar permisos y estado del GPS.
 */
class RealLocationProvider(
    private val context: Context,
    private val locationClient: LocationClient = FusedLocationClientWrapper(
        LocationServices.getFusedLocationProviderClient(context)
    ),
    private val config: LocationConfig = LocationConfig()
) : LocationProvider {
    private var locationCallback: LocationCallback? = null
    private var isUpdating = false
    private var lastKnownLocation: Location? = null

    override fun requestLocationUpdates(
        onLocation: (Location?) -> Unit,
        onError: (Exception) -> Unit
    ) {
        if (!hasLocationPermission()) {
            onError(LocationPermissionException())
            return
        }

        if (!isLocationEnabled()) {
            onError(LocationDisabledException())
            return
        }

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { location ->
                    lastKnownLocation = location
                    onLocation(location)
                }
            }
        }

        try {
            locationClient.requestLocationUpdates(
                config,
                locationCallback!!,
                Looper.getMainLooper()
            )
            isUpdating = true
        } catch (e: Exception) {
            onError(e)
        }
    }

    override fun removeUpdates() {
        locationCallback?.let {
            locationClient.removeLocationUpdates(it)
            locationCallback = null
            isUpdating = false
        }
    }

    override fun getLastKnownLocation(): Location? = lastKnownLocation

    override fun isUpdating(): Boolean = isUpdating

    private fun hasLocationPermission(): Boolean {
        return ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun isLocationEnabled(): Boolean {
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
    }
} 