package com.okecode.parking_detector_plugin.core.location

sealed class LocationException : Exception()
class LocationPermissionException : LocationException()
class LocationDisabledException : LocationException() 
