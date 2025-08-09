import 'package:flutter/foundation.dart' show kDebugMode;

/// Configuración de logging remoto (solo desarrollo por defecto)
class LogConfig {
  /// Activar/desactivar envío remoto. Por defecto solo en debug.
  static const bool enabled = kDebugMode;

  /// Endpoint del colector de logs (por ejemplo, Logtail)
  /// Para Logtail: https://in.logtail.com
  static const String endpoint = String.fromEnvironment(
    'LOG_ENDPOINT',
    // Host de ingestión provisto: Better Stack Telemetry (HTTP)
    defaultValue: 'https://s1471639.eu-nbg-2.betterstackdata.com',
  );

  /// Token/API key para autenticación con el colector
  /// Para Logtail usar el Source Token
  static const String apiKey = String.fromEnvironment(
    'LOG_API_KEY',
    // No hardcodear secretos. Definir por --dart-define o variables de entorno.
    defaultValue: '',
  );

  /// Nombre de la app para etiquetar los eventos
  static const String appName = 'Where Is It';
}
