package com.example.parking_detector_plugin.detector

/**
 * Represents a vehicle transition event for driving detection.
 */
enum class VehicleTransition {
    /** Vehicle has entered (start driving) */
    ENTER,
    /** Vehicle has exited (potential parking) */
    EXIT
} 