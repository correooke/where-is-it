import '../entities/location.dart';

/// Interface that defines the operations for location data persistence
abstract class LocationRepository {
  /// Get the current device location
  Future<Location> getCurrentLocation();
  
  /// Save a location to persistent storage
  Future<void> saveLocation(Location location);
  
  /// Load the last saved location from persistent storage
  /// Returns null if no location has been saved
  Future<Location?> loadLastSavedLocation();
} 