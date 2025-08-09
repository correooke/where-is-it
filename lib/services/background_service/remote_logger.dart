import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:where_is_it/configuration/log_config.dart';

/// Cliente muy simple para enviar logs a un colector HTTP (p.ej. Logtail)
class RemoteLogger {
  static Future<void> send(
    String message, {
    String level = 'INFO',
    Map<String, dynamic>? context,
  }) async {
    if (!LogConfig.enabled) return;
    if (LogConfig.apiKey.isEmpty) return;

    try {
      final payload = {
        'level': level,
        'message': message,
        'app': LogConfig.appName,
        'timestamp': DateTime.now().toIso8601String(),
        if (context != null) ...{'context': context},
      };

      final res = await http.post(
        Uri.parse(LogConfig.endpoint),
        headers: {
          'Content-Type': 'application/json',
          // Logtail usa 'Authorization: Bearer <source-token>'
          'Authorization': 'Bearer ${LogConfig.apiKey}',
        },
        body: jsonEncode(payload),
      );

      // Ignorar errores en envío para no afectar el flujo principal
      if (res.statusCode >= 400 && kDebugMode) {
        // En debug podríamos imprimir el error si se desea
      }
    } catch (_) {
      // Silencioso
    }
  }
}
