package com.okecode.parking_detector_plugin.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import com.okecode.parking_detector_plugin.R
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

interface NotificationHandler {
    fun createNotificationChannel()
    fun createNotification(message: String): Notification
    fun updateNotification(message: String)
}

class NotificationHandlerImpl : KoinComponent, NotificationHandler {
    private val context: Context by inject()
    private val notificationManager: NotificationManager by inject()

    override fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Monitoreo de actividad",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitorea la actividad del usuario"
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun createNotification(message: String): Notification {
        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle("WhereIsIt")
            .setContentText(message)
            .setSmallIcon(R.drawable.ic_notification)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun updateNotification(message: String) {
        val notification = createNotification(message)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    companion object {
        private const val CHANNEL_ID = "activity_monitoring_channel"
        private const val NOTIFICATION_ID = 1
    }
} 
