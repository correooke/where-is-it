package com.okecode.parking_detector_plugin.utils

import android.util.Log
import com.okecode.parking_detector_plugin.service.LoggingHandler

class AndroidLoggingHandler(private val tag: String) : LoggingHandler {
    override fun debug(message: String) {
        Log.d(tag, message)
    }

    override fun error(message: String, throwable: Throwable?) {
        if (throwable != null) {
            Log.e(tag, message, throwable)
        } else {
            Log.e(tag, message)
        }
    }
    
    override fun error(message: String) {
        Log.e(tag, message)
    }
} 
