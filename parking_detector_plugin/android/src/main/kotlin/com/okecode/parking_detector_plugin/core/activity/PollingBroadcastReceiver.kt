package com.okecode.parking_detector_plugin.core.activity

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.ActivityRecognitionResult

/**
 * BroadcastReceiver estático para polling de ActivityRecognition.
 */
class PollingBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        ActivityRecognitionResult.extractResult(intent)?.let { result ->
            val top = result.mostProbableActivity
            ActivityRecognitionCallbacks.notifyPollingListeners(top.type, top.confidence)
        }
    }
} 
