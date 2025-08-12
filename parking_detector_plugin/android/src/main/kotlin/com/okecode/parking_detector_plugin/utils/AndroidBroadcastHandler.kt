package com.okecode.parking_detector_plugin.utils

import android.content.Context
import android.content.Intent
import com.okecode.parking_detector_plugin.core.Constants
import com.okecode.parking_detector_plugin.service.BroadcastHandler

class AndroidBroadcastHandler(private val context: Context) : BroadcastHandler {
    override fun sendParkingEvent(isParked: Boolean) {
        val intent = Intent(Constants.ACTION_PARKING_STATE_CHANGED).apply {
            putExtra(Constants.EXTRA_IS_PARKED, isParked)
        }
        context.sendBroadcast(intent)
    }
} 
