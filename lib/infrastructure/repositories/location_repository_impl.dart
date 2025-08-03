import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:sembast/sembast.dart';
import '../database/app_database.dart';
import '../../domain/entities/location.dart';
import '../../domain/repositories/location_repository.dart';

/// Implementation of the LocationRepository interface using geolocator and shared_preferences
class LocationRepositoryImpl implements LocationRepository {
  static final StoreRef<String, Map<String, dynamic>> _store =
      stringMapStoreFactory.store('settings');
  static const String _recordKey = 'last_location';

  /// Get the current device location using geolocator
  @override
  Future<Location> getCurrentLocation() async {
    if (kIsWeb) {
      // En la web, manejar la obtención de ubicación de manera diferente
      try {
        final position = await _getWebPosition();
        return Location(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
        );
      } catch (e) {
        // Lanzar excepción en vez de devolver ubicación predeterminada
        throw Exception('Error al obtener la ubicación en web: $e');
      }
    }

    // Para plataformas móviles
    try {
      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return Location(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      // Lanzar excepción en vez de devolver ubicación predeterminada
      throw Exception('Error al obtener la ubicación del dispositivo: $e');
    }
  }

  /// Método auxiliar para obtener la posición en web
  Future<Position> _getWebPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    // En web, no se puede solicitar permisos, pero se puede intentar obtener la ubicación
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Save location to SharedPreferences
  @override
  Future<void> saveLocation(Location location) async {
    final db = await AppDatabase.instance.database;
    await _store.record(_recordKey).put(db, {
      'latitude': location.latitude,
      'longitude': location.longitude,
      'timestamp': location.timestamp.toIso8601String(),
    });
  }

  /// Load the last saved location from SharedPreferences
  @override
  Future<Location?> loadLastSavedLocation() async {
    final db = await AppDatabase.instance.database;
    final record = await _store.record(_recordKey).get(db);
    if (record == null) return null;
    final latitude = record['latitude'] as double?;
    final longitude = record['longitude'] as double?;
    final timestampStr = record['timestamp'] as String?;
    if (latitude == null || longitude == null || timestampStr == null) {
      return null;
    }
    DateTime timestamp;
    try {
      timestamp = DateTime.parse(timestampStr);
    } catch (_) {
      timestamp = DateTime.now();
    }
    return Location(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
    );
  }
}
