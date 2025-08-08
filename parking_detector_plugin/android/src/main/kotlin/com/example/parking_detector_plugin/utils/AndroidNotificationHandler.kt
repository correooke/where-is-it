package com.example.parking_detector_plugin.utils

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import com.example.parking_detector_plugin.R
import com.example.parking_detector_plugin.service.NotificationHandler

class AndroidNotificationHandler(private val context: Context) : NotificationHandler {
    companion object {
        private const val CHANNEL_ID = "parking_detection_channel"
        private const val NOTIFICATION_ID = 1001
    }

    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    override fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Detección de Estacionamiento",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notificaciones del servicio de detección de estacionamiento"
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun createNotification(message: String): Notification {
        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle("Detección de Estacionamiento")
            .setContentText(message)
            .setSmallIcon(R.drawable.ic_bg_service_small)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setOngoing(true)
            .build()
    }

    override fun updateNotification(message: String) {
        val notification = createNotification(message)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
} 