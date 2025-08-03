/// Clase para representar una ubicación.
class LocationInfo {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final DateTime timestamp;

  LocationInfo({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'LocationInfo(lat: $latitude, lng: $longitude, accuracy: ${accuracy?.toStringAsFixed(2)}, speed: ${speed?.toStringAsFixed(2)} km/h)';
  }
}
