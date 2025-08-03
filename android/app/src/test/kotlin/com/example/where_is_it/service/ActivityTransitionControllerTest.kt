package com.example.parking_detector_plugin.service

import android.location.Location
import com.example.parking_detector_plugin.core.Constants
import com.example.parking_detector_plugin.core.activity.ActivityRecognitionProvider
import com.example.parking_detector_plugin.core.location.LocationProvider
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.DetectedActivity
import io.mockk.*
import com.example.parking_detector_plugin.service.NotificationHandler
import com.example.parking_detector_plugin.service.BroadcastHandler
import com.example.parking_detector_plugin.service.ServiceLifecycleManager
import com.example.parking_detector_plugin.service.LoggingHandler
import com.example.parking_detector_plugin.service.ActivityTransitionController
import org.junit.Before
import org.junit.Test

class ActivityTransitionControllerTest {
    private lateinit var locationProvider: LocationProvider
    private lateinit var activityProvider: ActivityRecognitionProvider
    private lateinit var notificationHandler: NotificationHandler
    private lateinit var broadcastHandler: BroadcastHandler
    private lateinit var serviceLifecycleManager: ServiceLifecycleManager
    private lateinit var loggingHandler: LoggingHandler
    private lateinit var controller: ActivityTransitionController

    @Before
    fun setup() {
        // Mocks con comportamientos relajados
        locationProvider = mockk<LocationProvider>(relaxed = true)
        activityProvider = mockk<ActivityRecognitionProvider>(relaxed = true)
        notificationHandler = mockk<NotificationHandler>(relaxed = true)
        broadcastHandler = mockk<BroadcastHandler>(relaxed = true)
        serviceLifecycleManager = mockk<ServiceLifecycleManager>(relaxed = true)
        loggingHandler = mockk<LoggingHandler>(relaxed = true)

        controller = ActivityTransitionController(
            locationProvider,
            activityProvider,
            notificationHandler,
            broadcastHandler,
            serviceLifecycleManager,
            loggingHandler
        )
    }

    @Test
    fun `start should set up all providers`() {
        // Capturar lambdas pasadas a providers
        val locSlot = slot<(Location?) -> Unit>()
        val errSlot = slot<(Exception) -> Unit>()
        every { locationProvider.requestLocationUpdates(capture(locSlot), capture(errSlot)) } just Runs

        val transSpecs = slot<List<ActivityRecognitionProvider.TransitionSpec>>()
        val transCallback = slot<(ActivityRecognitionProvider.TransitionEvent) -> Unit>()
        every { activityProvider.requestTransitions(capture(transSpecs), capture(transCallback)) } just Runs

        val pollCallback = slot<(Int, Int) -> Unit>()
        every { activityProvider.requestPolling(Constants.POLLING_INTERVAL_MS, capture(pollCallback)) } just Runs

        // Ejecutar
        controller.start()

        // Verificar inicialización de notificaciones y foreground
        verify { notificationHandler.createNotificationChannel() }
        verify { notificationHandler.createNotification(any()) }
        verify { serviceLifecycleManager.startForeground(any()) }

        // Verificar llamadas a los providers
        verify { locationProvider.requestLocationUpdates(any(), any()) }
        verify { activityProvider.requestTransitions(any(), any()) }
        verify { activityProvider.requestPolling(Constants.POLLING_INTERVAL_MS, any()) }
    }

    @Test
    fun `stop should cancel all flows and stop foreground`() {
        // Ejecutar stop
        controller.stop()

        // Verificar limpieza
        verify { locationProvider.removeUpdates() }
        verify { activityProvider.removeAll() }
        verify { serviceLifecycleManager.stopForeground() }
    }
} 