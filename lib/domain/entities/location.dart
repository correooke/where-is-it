import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Represents a geographical location with latitude and longitude
class Location {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  Location({
    required this.latitude,
    required this.longitude,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates a Location instance from a LatLng object
  factory Location.fromLatLng(LatLng latLng) {
    return Location(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );
  }

  /// Converts this Location to a LatLng object
  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }

  /// Creates a copy of this Location with optional new values
  Location copyWith({
    double? latitude,
    double? longitude,
    DateTime? timestamp,
  }) {
    return Location(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'Location(latitude: $latitude, longitude: $longitude, timestamp: $timestamp)';
  }
} 