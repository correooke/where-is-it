package com.okecode.parking_detector_plugin.service

import android.content.Context
import android.content.Intent
import com.okecode.parking_detector_plugin.core.Constants
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

interface BroadcastHandler {
    fun sendParkingEvent(isParked: Boolean)
}

class BroadcastHandlerImpl : KoinComponent, BroadcastHandler {
    private val context: Context by inject()

    override fun sendParkingEvent(isParked: Boolean) {
        val intent = Intent(Constants.ACTION_PARKING_STATE_CHANGED).apply {
            putExtra(Constants.EXTRA_IS_PARKED, isParked)
        }
        context.sendBroadcast(intent)
    }
} 
