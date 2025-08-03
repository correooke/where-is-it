package com.example.parking_detector_plugin.detector

/**
 * Enumerates the possible parking detection states.
 */
enum class ParkingState {
    /**
     * Initial state before any driving or parking data is received.
     */
    UNKNOWN,
    /**
     * Vehicle is actively being driven (speed > DRIVING_SPEED or transition into vehicle).
     */
    DRIVING,
    /**
     * Tentative parked: after driving, a stop is detected (speed < STOP_SPEED or STILL activity).
     */
    TENTATIVE_PARKED,
    /**
     * Confirmed parked: after tentative parked, a confirmation activity is detected (walking, cycling, etc.).
     */
    CONFIRMED_PARKED
} 