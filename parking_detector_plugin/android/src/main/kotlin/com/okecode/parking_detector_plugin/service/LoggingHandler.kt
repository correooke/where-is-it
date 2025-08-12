package com.okecode.parking_detector_plugin.service

import android.util.Log
import com.okecode.parking_detector_plugin.core.Constants

interface LoggingHandler {
    fun debug(message: String)
    fun error(message: String, throwable: Throwable?)
    fun error(message: String)
}

class LoggingHandlerImpl : LoggingHandler {
    override fun debug(message: String) {
        Log.d(Constants.TAG, message)
    }

    override fun error(message: String, throwable: Throwable?) {
        if (throwable != null) {
            Log.e(Constants.TAG, message, throwable)
        } else {
            Log.e(Constants.TAG, message)
        }
    }
    
    override fun error(message: String) {
        Log.e(Constants.TAG, message)
    }
} 
