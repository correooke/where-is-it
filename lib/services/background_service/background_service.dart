import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
// Beacon removido
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
// Registrador explícito innecesario en versiones modernas; mantener simple
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// Beacon removido

import 'background_service_events.dart';
import 'remote_logger.dart';

const channelId = 'where_is_it_channel';
const channelName = 'Servicio de estacionamiento';
const channelDesc = 'Canal para servicio de ubicación';

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> setupChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    channelId, // debe coincidir luego en configure()
    channelName, // nombre visible en ajustes
    description: channelDesc,
    importance: Importance.low,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(
        channel,
      ); // crea el canal :contentReference[oaicite:2]{index=2}
}

/// Inicializa el servicio en segundo plano para la detección de salida de vehículo.
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onBackgroundServiceStart,
      isForegroundMode: false,
      autoStart: true,
      notificationChannelId: channelId,
      // No mostrar como activo hasta que el usuario lo inicie desde la UI
      initialNotificationTitle: 'Servicio listo',
      initialNotificationContent: 'Presiona Iniciar para comenzar el monitoreo',
      foregroundServiceNotificationId: 1,
      foregroundServiceTypes: [
        // si monitorizas ubicación
        AndroidForegroundType.location,
      ],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onBackgroundServiceStart,
      onBackground: onIosBackground,
    ),
  );
  service.startService();
}

/// Callback que corre en un isolate separado y mantiene activa la detección.
@pragma('vm:entry-point')
Future<void> onBackgroundServiceStart(ServiceInstance service) async {
  // Asegurar foreground y continuar
  // Make sure the service runs in foreground after start
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  // Beacon removido

  // Suscribir al stream de actividad solo para debug (NO emitir onStateChanged aquí)
  FlutterActivityRecognition.instance.activityStream.listen((activity) {
    service.invoke(BackgroundServiceEvents.onActivityUpdate, {
      'type': activity.type.toString(),
      'confidence': activity.confidence.index,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  });

  // Sin Strategy: no registramos CarExitDetector

  // Ping de verificación al iniciar servicio
  RemoteLogger.send(
    'Servicio de fondo iniciado',
    level: 'INFO',
    context: {'event': 'service_start'},
  );

  // El monitoreo se inicia manualmente desde la UI (por evento)

  // Keep the service running even when the app is in the background
  void handleServiceMode(Map<String, dynamic>? event) {
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }
  }

  service.on('setAsBackground').listen(handleServiceMode);
  service.on('setAsForeground').listen(handleServiceMode);
}

/// Callback requerido para iOS background fetch (regresa true si se ejecutó).
@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  onBackgroundServiceStart(service);
  return true;
}

// Eliminados handlers ligados a Strategy
