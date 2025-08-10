/// Constantes para los comandos enviados desde la UI hacia el servicio en segundo plano.
class BackgroundServiceCommands {
  /// Solicita obtener el estado actual del detector de salida
  static const String getCurrentState = 'getCurrentState';

  // Comandos de start/stop del detector ya no se usan (se invoca directo al plugin)
}

/// Constantes para los nombres de evento del servicio en segundo plano.
class BackgroundServiceEvents {
  // ===== Eventos (servicio hacia UI) =====

  /// Notifica cambios en el estado de detección del vehículo
  static const String onStateChanged = 'onStateChanged';

  /// Notifica que se ha detectado la salida del vehículo
  static const String onCarExit = 'onCarExit';

  /// Notifica que ha cambiado la estrategia de detección activa
  // Eliminado: estrategia no usada

  /// Responde con el estado actual del detector
  static const String onCurrentState = 'onCurrentState';

  /// Emite logs del servicio/detector (solo desarrollo)
  static const String onLog = 'onLog';

  /// Actualizaciones crudas de Activity Recognition (solo debug)
  static const String onActivityUpdate = 'onActivityUpdate';
}
