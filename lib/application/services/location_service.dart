import 'dart:developer' as developer;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/location.dart';
import '../../domain/repositories/location_repository.dart';

/// Service responsible for handling location-related operations
class LocationService {
  final LocationRepository _locationRepository;

  LocationService(this._locationRepository);

  /// Get the current device location
  Future<LatLng> getCurrentLocation() async {
    final location = await _locationRepository.getCurrentLocation();
    developer.log(
      'Ubicación obtenida: Lat: ${location.latitude}, Lng: ${location.longitude}',
    );
    return location.toLatLng();
  }

  /// Save the current location
  ///
  /// This function is designed to be called on external triggers
  /// like a bluetooth disconnect event
  Future<void> onExternalTrigger() async {
    try {
      // Get current location
      final location = await _locationRepository.getCurrentLocation();

      developer.log(
        'onExternalTrigger - Guardando ubicación: Lat: ${location.latitude}, Lng: ${location.longitude}',
      );

      // Save location
      await _locationRepository.saveLocation(location);

      // Additional logic for notification or state updates could be added here

      return;
    } catch (e) {
      developer.log('Error en onExternalTrigger: $e', error: e);
      throw Exception('Error al procesar el evento externo: $e');
    }
  }

  /// Save a specific location
  Future<void> saveLocation(LatLng position) async {
    try {
      final location = Location.fromLatLng(position);
      developer.log(
        'saveLocation - Guardando ubicación específica: Lat: ${location.latitude}, Lng: ${location.longitude}',
      );
      await _locationRepository.saveLocation(location);
    } catch (e) {
      developer.log('Error en saveLocation: $e', error: e);
      throw Exception('Error al guardar la ubicación: $e');
    }
  }

  /// Load the last saved location
  Future<LatLng?> loadLastSavedLocation() async {
    try {
      final location = await _locationRepository.loadLastSavedLocation();
      if (location != null) {
        developer.log(
          'loadLastSavedLocation - Ubicación cargada: Lat: ${location.latitude}, Lng: ${location.longitude}',
        );
      } else {
        developer.log('loadLastSavedLocation - No hay ubicación guardada');
      }
      return location?.toLatLng();
    } catch (e) {
      developer.log('Error en loadLastSavedLocation: $e', error: e);
      throw Exception('Error al cargar la última ubicación guardada: $e');
    }
  }
}
