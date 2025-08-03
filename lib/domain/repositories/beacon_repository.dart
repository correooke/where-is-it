/// Interfaz que define las operaciones para la gestión de Beacons
abstract class BeaconRepository {
  /// Guarda el ID del Beacon asociado al vehículo
  Future<void> saveBeaconId(String id);

  /// Carga el ID del Beacon guardado anteriormente
  /// Retorna null si no hay ningún ID guardado
  Future<String?> loadBeaconId();

  /// Guarda el fingerprint del Beacon asociado al vehículo
  Future<void> saveBeaconFingerprint(Map<String, dynamic> fingerprint);

  /// Carga el fingerprint guardado anteriormente
  /// Retorna null si no hay ningún fingerprint guardado
  Future<Map<String, dynamic>?> loadBeaconFingerprint();
}
