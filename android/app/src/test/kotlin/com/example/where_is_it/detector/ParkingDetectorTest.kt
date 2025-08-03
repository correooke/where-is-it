package com.example.parking_detector_plugin.detector

import android.location.Location
import com.example.parking_detector_plugin.core.Constants
import com.example.parking_detector_plugin.detector.ParkingState
import com.example.parking_detector_plugin.detector.ParkingDetector
import com.google.android.gms.location.DetectedActivity
import io.mockk.clearMocks
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import com.example.parking_detector_plugin.detector.VehicleTransition

/**
 * Tests for ParkingDetector using the ParkingState enum.
 */
class ParkingDetectorTest {
    private lateinit var onStateChanged: (ParkingState) -> Unit
    private lateinit var detector: ParkingDetector

    @Before
    fun setup() {
        onStateChanged = mockk(relaxed = true)
        detector = ParkingDetector(onStateChanged)
    }

    @Test
    fun `initial state is UNKNOWN and no callbacks`() {
        assertEquals(ParkingState.UNKNOWN, detector.getState())
        verify(exactly = 0) { onStateChanged(any()) }
    }

    @Test
    fun `entering vehicle sets DRIVING`() {
        detector.handleActivityTransition(VehicleTransition.ENTER)
        verify { onStateChanged(ParkingState.DRIVING) }
        assertEquals(ParkingState.DRIVING, detector.getState())
    }

    @Test
    fun `high speed sets DRIVING`() {
        val loc = mockk<Location> { every { speed } returns Constants.DRIVING_SPEED + 1f }
        detector.updateLocationData(loc)
        verify { onStateChanged(ParkingState.DRIVING) }
        assertEquals(ParkingState.DRIVING, detector.getState())
    }

    @Test
    fun `speed drop below stop sets TENTATIVE_PARKED`() {
        detector.handleActivityTransition(VehicleTransition.ENTER)
        clearMocks(onStateChanged)

        val loc = mockk<Location> { every { speed } returns Constants.STOP_SPEED - 0.1f }
        detector.updateLocationData(loc)
        verify { onStateChanged(ParkingState.TENTATIVE_PARKED) }
        assertEquals(ParkingState.TENTATIVE_PARKED, detector.getState())
    }

    @Test
    fun `STILL activity sets TENTATIVE_PARKED`() {
        detector.handleActivityTransition(VehicleTransition.ENTER)
        clearMocks(onStateChanged)

        detector.updateActivityRecognition(Constants.STILL_ACTIVITY, Constants.ACTIVITY_CONFIDENCE_THRESHOLD + 1)
        verify { onStateChanged(ParkingState.TENTATIVE_PARKED) }
        assertEquals(ParkingState.TENTATIVE_PARKED, detector.getState())
    }

    @Test
    fun `confirmation activity sets CONFIRMED_PARKED`() {
        detector.handleActivityTransition(VehicleTransition.ENTER)
        detector.updateActivityRecognition(Constants.STILL_ACTIVITY, Constants.ACTIVITY_CONFIDENCE_THRESHOLD + 1)
        clearMocks(onStateChanged)

        detector.updateActivityRecognition(DetectedActivity.WALKING, Constants.ACTIVITY_CONFIDENCE_THRESHOLD + 1)
        verify { onStateChanged(ParkingState.CONFIRMED_PARKED) }
        assertEquals(ParkingState.CONFIRMED_PARKED, detector.getState())
    }

    @Test
    fun `setState transitions to CONFIRMED_PARKED`() {
        detector.handleActivityTransition(VehicleTransition.ENTER)
        detector.updateActivityRecognition(Constants.STILL_ACTIVITY, Constants.ACTIVITY_CONFIDENCE_THRESHOLD + 1)
        clearMocks(onStateChanged)

        detector.setState(ParkingState.CONFIRMED_PARKED)
        verify { onStateChanged(ParkingState.CONFIRMED_PARKED) }
        assertEquals(ParkingState.CONFIRMED_PARKED, detector.getState())
    }

    @Test
    fun `setState can set any state`() {
        // Test setting to DRIVING
        detector.setState(ParkingState.DRIVING)
        verify { onStateChanged(ParkingState.DRIVING) }
        assertEquals(ParkingState.DRIVING, detector.getState())
        clearMocks(onStateChanged)

        // Test setting to TENTATIVE_PARKED
        detector.setState(ParkingState.TENTATIVE_PARKED)
        verify { onStateChanged(ParkingState.TENTATIVE_PARKED) }
        assertEquals(ParkingState.TENTATIVE_PARKED, detector.getState())
        clearMocks(onStateChanged)

        // Test setting to UNKNOWN
        detector.setState(ParkingState.UNKNOWN)
        verify { onStateChanged(ParkingState.UNKNOWN) }
        assertEquals(ParkingState.UNKNOWN, detector.getState())
    }

    @Test
    fun `sequence from tentative parked to confirmed through driving`() {
        // Start in TENTATIVE_PARKED state
        detector.setState(ParkingState.TENTATIVE_PARKED)
        assertEquals(ParkingState.TENTATIVE_PARKED, detector.getState())
        clearMocks(onStateChanged)

        // 1. Transition to DRIVING through high speed
        val locHigh = mockk<Location> { every { speed } returns Constants.DRIVING_SPEED + 2f }
        detector.updateLocationData(locHigh)
        verify { onStateChanged(ParkingState.DRIVING) }
        assertEquals(ParkingState.DRIVING, detector.getState())
        clearMocks(onStateChanged)

        // 2. Back to TENTATIVE_PARKED through STILL activity
        detector.updateActivityRecognition(Constants.STILL_ACTIVITY, Constants.ACTIVITY_CONFIDENCE_THRESHOLD + 1)
        verify { onStateChanged(ParkingState.TENTATIVE_PARKED) }
        assertEquals(ParkingState.TENTATIVE_PARKED, detector.getState())
        clearMocks(onStateChanged)

        // 3. Finally to CONFIRMED_PARKED through walking activity
        detector.updateActivityRecognition(DetectedActivity.WALKING, Constants.ACTIVITY_CONFIDENCE_THRESHOLD + 1)
        verify { onStateChanged(ParkingState.CONFIRMED_PARKED) }
        assertEquals(ParkingState.CONFIRMED_PARKED, detector.getState())
    }

    @Test
    fun `complete cycle of state transitions`() {
        // Initial state should be UNKNOWN
        assertEquals(ParkingState.UNKNOWN, detector.getState())
        clearMocks(onStateChanged)

        // 1. Transition to DRIVING through vehicle enter
        detector.handleActivityTransition(VehicleTransition.ENTER)
        verify { onStateChanged(ParkingState.DRIVING) }
        assertEquals(ParkingState.DRIVING, detector.getState())
        clearMocks(onStateChanged)

        // 2. Transition to TENTATIVE_PARKED through STILL activity
        detector.updateActivityRecognition(Constants.STILL_ACTIVITY, Constants.ACTIVITY_CONFIDENCE_THRESHOLD + 1)
        verify { onStateChanged(ParkingState.TENTATIVE_PARKED) }
        assertEquals(ParkingState.TENTATIVE_PARKED, detector.getState())
        clearMocks(onStateChanged)

        // 3. Transition to CONFIRMED_PARKED through walking activity
        detector.updateActivityRecognition(DetectedActivity.WALKING, Constants.ACTIVITY_CONFIDENCE_THRESHOLD + 1)
        verify { onStateChanged(ParkingState.CONFIRMED_PARKED) }
        assertEquals(ParkingState.CONFIRMED_PARKED, detector.getState())
        clearMocks(onStateChanged)

        // 4. Back to DRIVING through high speed
        val locHigh = mockk<Location> { every { speed } returns Constants.DRIVING_SPEED + 2f }
        detector.updateLocationData(locHigh)
        verify { onStateChanged(ParkingState.DRIVING) }
        assertEquals(ParkingState.DRIVING, detector.getState())
        clearMocks(onStateChanged)

        // 5. Back to TENTATIVE_PARKED through low speed
        val locLow = mockk<Location> { every { speed } returns Constants.STOP_SPEED - 0.1f }
        detector.updateLocationData(locLow)
        verify { onStateChanged(ParkingState.TENTATIVE_PARKED) }
        assertEquals(ParkingState.TENTATIVE_PARKED, detector.getState())
        clearMocks(onStateChanged)

        // 6. Finally back to CONFIRMED_PARKED through walking activity
        detector.updateActivityRecognition(DetectedActivity.WALKING, Constants.ACTIVITY_CONFIDENCE_THRESHOLD + 1)
        verify { onStateChanged(ParkingState.CONFIRMED_PARKED) }
        assertEquals(ParkingState.CONFIRMED_PARKED, detector.getState())
    }

    @Test
    fun `exit confirmed parking when driving resumes`() {
        // Arrange: move to CONFIRMED_PARKED
        detector.handleActivityTransition(VehicleTransition.ENTER)
        detector.updateActivityRecognition(Constants.STILL_ACTIVITY, Constants.ACTIVITY_CONFIDENCE_THRESHOLD + 1)
        detector.updateActivityRecognition(DetectedActivity.WALKING, Constants.ACTIVITY_CONFIDENCE_THRESHOLD + 1)
        assertEquals(ParkingState.CONFIRMED_PARKED, detector.getState())
        clearMocks(onStateChanged)

        // Act: simulate high speed indicating driving
        val locHigh = mockk<Location> { every { speed } returns Constants.DRIVING_SPEED + 2f }
        detector.updateLocationData(locHigh)

        // Assert: state should transition back to DRIVING and callback invoked
        verify { onStateChanged(ParkingState.DRIVING) }
        assertEquals(ParkingState.DRIVING, detector.getState())
    }
} 