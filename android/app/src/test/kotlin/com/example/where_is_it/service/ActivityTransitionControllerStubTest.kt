package com.example.parking_detector_plugin.service

import android.location.Location
import com.example.parking_detector_plugin.core.Constants
import com.example.parking_detector_plugin.core.activity.ActivityRecognitionProvider
import com.example.parking_detector_plugin.core.location.LocationProvider
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.DetectedActivity
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import io.mockk.clearMocks
import org.junit.Before
import org.junit.Test
import com.example.parking_detector_plugin.service.NotificationHandler
import com.example.parking_detector_plugin.service.BroadcastHandler
import com.example.parking_detector_plugin.service.ServiceLifecycleManager
import com.example.parking_detector_plugin.service.LoggingHandler
import com.example.parking_detector_plugin.service.ActivityTransitionController

/**
 * Additional integration-like tests for ActivityTransitionController using stub providers.
 * Does not modify existing tests.
 */
class ActivityTransitionControllerStubTest {
    // Mocks for handlers
    private lateinit var notificationHandler: NotificationHandler
    private lateinit var broadcastHandler: BroadcastHandler
    private lateinit var serviceLifecycleManager: ServiceLifecycleManager
    private lateinit var loggingHandler: LoggingHandler

    // Stub providers
    private lateinit var locationProvider: LocationProvider
    private lateinit var activityProvider: ActivityRecognitionProvider

    // Captured callbacks
    private lateinit var locationCallback: (Location?) -> Unit
    private lateinit var locationErrorCallback: (Exception) -> Unit
    private lateinit var transitionCallback: (ActivityRecognitionProvider.TransitionEvent) -> Unit
    private lateinit var pollingCallback: (Int, Int) -> Unit

    private lateinit var controller: ActivityTransitionController

    @Before
    fun setUp() {
        notificationHandler = mockk(relaxed = true)
        broadcastHandler = mockk(relaxed = true)
        serviceLifecycleManager = mockk(relaxed = true)
        loggingHandler = mockk(relaxed = true)

        locationProvider = object : LocationProvider {
            override fun requestLocationUpdates(
                onLocation: (Location?) -> Unit,
                onError: (Exception) -> Unit
            ) {
                locationCallback = onLocation
                locationErrorCallback = onError
            }
            override fun removeUpdates() {}
            override fun getLastKnownLocation(): Location? = null
            override fun isUpdating(): Boolean = false
        }

        activityProvider = object : ActivityRecognitionProvider {
            override fun requestTransitions(
                transitions: List<ActivityRecognitionProvider.TransitionSpec>,
                onEvent: (ActivityRecognitionProvider.TransitionEvent) -> Unit
            ) {
                transitionCallback = onEvent
            }
            override fun requestPolling(
                intervalMs: Long,
                onResult: (Int, Int) -> Unit
            ) {
                pollingCallback = onResult
            }
            override fun removeAll() {}
            override fun startActivityTransitionUpdates() {}
            override fun stopActivityTransitionUpdates() {}
        }

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
    fun `complete driving sequence with stubs`() {
        // Start controller
        controller.start()
        verify { notificationHandler.createNotificationChannel() }
        verify { notificationHandler.createNotification("Monitoring activity...") }
        verify { serviceLifecycleManager.startForeground(any()) }
        clearMocks(notificationHandler, serviceLifecycleManager)

        // 1. Enter vehicle -> treated as driving
        transitionCallback(
            ActivityRecognitionProvider.TransitionEvent(
                DetectedActivity.IN_VEHICLE,
                ActivityTransition.ACTIVITY_TRANSITION_ENTER
            )
        )
        // on enter vehicle we set DRIVING (parked = false)
        verify { notificationHandler.updateNotification("Driving") }
        verify { broadcastHandler.sendParkingEvent(false) }
        clearMocks(notificationHandler, broadcastHandler)

        // 2. High speed -> Driving
        val fastLocation = mockk<Location> {
            every { speed } returns Constants.DRIVING_SPEED + 1f
        }
        locationCallback(fastLocation)
        clearMocks(notificationHandler, broadcastHandler)

        // 3. Stop speed -> Possible parking
        val slowLocation = mockk<Location> {
            every { speed } returns Constants.STOP_SPEED - 0.1f
        }
        locationCallback(slowLocation)
        verify { notificationHandler.updateNotification("Possible parking detected") }
        clearMocks(notificationHandler)

        // 4. Walking activity -> Confirm parked
        pollingCallback(DetectedActivity.WALKING, 80)
        verify { notificationHandler.updateNotification("Parked") }
        verify { broadcastHandler.sendParkingEvent(true) }
        clearMocks(notificationHandler, broadcastHandler)

        // 5. Exit vehicle -> no state change
        transitionCallback(
            ActivityRecognitionProvider.TransitionEvent(
                DetectedActivity.IN_VEHICLE,
                ActivityTransition.ACTIVITY_TRANSITION_EXIT
            )
        )
        verify(exactly = 0) { notificationHandler.updateNotification(any()) }
        verify(exactly = 0) { broadcastHandler.sendParkingEvent(any()) }

        // Stop controller
        controller.stop()

        verify { serviceLifecycleManager.stopForeground() }
    }
} 