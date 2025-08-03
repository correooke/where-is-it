/// Constantes para los comandos enviados desde la UI hacia el servicio en segundo plano.
class BackgroundServiceCommands {
  /// Solicita detener el servicio en segundo plano
  static const String stopService = 'stopService';

  /// Solicita asociar un beacon específico al vehículo
  static const String associateBeacon = 'associateBeacon';

  /// Solicita desasociar el beacon actual del vehículo
  static const String dissociateBeacon = 'dissociateBeacon';

  /// Solicita obtener el ID del beacon actualmente asociado
  static const String getAssociatedBeacon = 'getAssociatedBeacon';

  /// Solicita información sobre la estrategia de detección activa
  static const String getActiveStrategy = 'getActiveStrategy';

  /// Solicita reevaluar y posiblemente cambiar la estrategia de detección
  static const String reevaluateStrategies = 'reevaluateStrategies';

  /// Solicita obtener el estado actual del detector de salida
  static const String getCurrentState = 'getCurrentState';

  /// Inicia el detector de salida del vehículo
  static const String startDetector = 'startDetector';

  /// Detiene el detector de salida del vehículo
  static const String stopDetector = 'stopDetector';
}

/// Constantes para los nombres de evento del servicio en segundo plano.
class BackgroundServiceEvents {
  // ===== Eventos (servicio hacia UI) =====

  /// Notifica cambios en el estado de detección del vehículo
  static const String onStateChanged = 'onStateChanged';

  /// Notifica que se ha detectado la salida del vehículo
  static const String onCarExit = 'onCarExit';

  /// Notifica que ha cambiado la estrategia de detección activa
  static const String onStrategyChanged = 'onStrategyChanged';

  /// Responde con información del beacon asociado actualmente
  static const String onAssociatedBeacon = 'onAssociatedBeacon';

  /// Notifica que el beacon ha sido desasociado con éxito
  static const String onBeaconDissociated = 'onBeaconDissociated';

  /// Responde con el estado actual del detector
  static const String onCurrentState = 'onCurrentState';
}
