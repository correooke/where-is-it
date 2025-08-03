package com.example.parking_detector_plugin.core.location

import android.location.Location

/**
 * Proveedor de ubicación abstraído para facilitar testeo.
 */
interface LocationProvider {
    /**
     * Solicita actualizaciones de ubicación.
     */
    fun requestLocationUpdates(
        onLocation: (Location?) -> Unit,
        onError: (Exception) -> Unit
    )

    /**
     * Cancela las actualizaciones.
     */
    fun removeUpdates()

    fun getLastKnownLocation(): Location?

    fun isUpdating(): Boolean
} 