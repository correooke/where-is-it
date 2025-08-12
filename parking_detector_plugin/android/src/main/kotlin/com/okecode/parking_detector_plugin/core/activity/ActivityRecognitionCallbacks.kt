package com.okecode.parking_detector_plugin.core.activity

import java.util.concurrent.CopyOnWriteArrayList

/**
 * Clase singleton para manejar los callbacks de reconocimiento de actividad de manera thread-safe.
 */
object ActivityRecognitionCallbacks {
    private val transitionListeners = CopyOnWriteArrayList<(ActivityRecognitionProvider.TransitionEvent) -> Unit>()
    private val pollingListeners = CopyOnWriteArrayList<(activityType: Int, confidence: Int) -> Unit>()

    fun addTransitionListener(listener: (ActivityRecognitionProvider.TransitionEvent) -> Unit) {
        transitionListeners.add(listener)
    }

    fun removeTransitionListener(listener: (ActivityRecognitionProvider.TransitionEvent) -> Unit) {
        transitionListeners.remove(listener)
    }

    fun notifyTransitionListeners(event: ActivityRecognitionProvider.TransitionEvent) {
        transitionListeners.forEach { listener ->
            try {
                listener(event)
            } catch (e: Exception) {
                // Log error but continue with other listeners
                e.printStackTrace()
            }
        }
    }

    fun addPollingListener(listener: (activityType: Int, confidence: Int) -> Unit) {
        pollingListeners.add(listener)
    }

    fun removePollingListener(listener: (activityType: Int, confidence: Int) -> Unit) {
        pollingListeners.remove(listener)
    }

    fun notifyPollingListeners(activityType: Int, confidence: Int) {
        pollingListeners.forEach { listener ->
            try {
                listener(activityType, confidence)
            } catch (e: Exception) {
                // Log error but continue with other listeners
                e.printStackTrace()
            }
        }
    }

    fun clearAll() {
        transitionListeners.clear()
        pollingListeners.clear()
    }
} 
