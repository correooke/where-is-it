package com.okecode.parking_detector_plugin.utils

import android.content.Context
import com.okecode.parking_detector_plugin.core.activity.ActivityRecognitionProvider
import com.okecode.parking_detector_plugin.core.activity.RealActivityRecognitionProvider

class AndroidActivityRecognitionProvider(context: Context) : ActivityRecognitionProvider {
    private val realProvider = RealActivityRecognitionProvider(context)

    override fun requestTransitions(
        transitions: List<ActivityRecognitionProvider.TransitionSpec>,
        onEvent: (ActivityRecognitionProvider.TransitionEvent) -> Unit
    ) {
        realProvider.requestTransitions(transitions, onEvent)
    }

    override fun requestPolling(
        intervalMs: Long,
        onResult: (activityType: Int, confidence: Int) -> Unit
    ) {
        realProvider.requestPolling(intervalMs, onResult)
    }

    override fun removeAll() {
        realProvider.removeAll()
    }

    override fun startActivityTransitionUpdates() {
        realProvider.startActivityTransitionUpdates()
    }

    override fun stopActivityTransitionUpdates() {
        realProvider.stopActivityTransitionUpdates()
    }
} 
