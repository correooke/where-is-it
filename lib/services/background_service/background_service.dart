import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:where_is_it/application/services/car_exit_strategy/index.dart';
// Beacon removido
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
// Registrador explícito innecesario en versiones modernas; mantener simple
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// Beacon removido

import 'background_service_events.dart';
import 'background_service_protocol.dart';
import 'handlers.dart';
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

  // Suscribir al stream de actividad con el nuevo plugin
  FlutterActivityRecognition.instance.activityStream.listen((activity) {
    service.invoke(BackgroundServiceEvents.onStateChanged, {
      'activity': activity.type.toString(),
      'confidence': activity.confidence.index,
    });
    // Emitir también evento de actividad crudo para depuración
    service.invoke(BackgroundServiceEvents.onActivityUpdate, {
      'type': activity.type.toString(),
      'confidence': activity.confidence.index,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  });

  // Create detector with proper callbacks
  final CarExitDetector detector = CarExitDetector(
    strategies: [
      ActivityBasedDetectionStrategy(
        onCarExitDetected: (loc) {
          // Propagar a detector superior a través de onCarExitDetected ya definido
        },
      ),
    ],
    onStateChanged: (newState, oldState) {
      service.invoke(
        BackgroundServiceEvents.onStateChanged,
        CarExitStateChangedEvent(
          newState: newState.toString(),
          oldState: oldState.toString(),
        ).toJson(),
      );
      RemoteLogger.send(
        'Estado detector cambiado: $oldState -> $newState',
        level: 'INFO',
        context: {'event': 'onStateChanged'},
      );
    },
    onCarExitDetected: (exitLocation) {
      service.invoke(
        BackgroundServiceEvents.onCarExit,
        CarExitDetectedEvent(
          latitude: exitLocation.latitude,
          longitude: exitLocation.longitude,
          timestamp: exitLocation.timestamp.millisecondsSinceEpoch,
        ).toJson(),
      );
      RemoteLogger.send(
        'Salida detectada @ ${exitLocation.latitude}, ${exitLocation.longitude}',
        level: 'INFO',
        context: {
          'event': 'onCarExit',
          'lat': exitLocation.latitude,
          'lng': exitLocation.longitude,
          'ts': exitLocation.timestamp.millisecondsSinceEpoch,
        },
      );
    },
    onStrategyChanged: (newStrategy, oldStrategy) {
      service.invoke(
        BackgroundServiceEvents.onStrategyChanged,
        StrategyChangedEvent(
          newStrategy: newStrategy?.runtimeType.toString() ?? 'none',
          oldStrategy: oldStrategy?.runtimeType.toString() ?? 'none',
        ).toJson(),
      );
      RemoteLogger.send(
        'Estrategia cambiada: ${oldStrategy?.runtimeType} -> ${newStrategy?.runtimeType}',
        level: 'INFO',
        context: {'event': 'onStrategyChanged'},
      );
    },
    onLog: (message) {
      // Emitir logs hacia la UI (puede filtrarse en UI por kDebugMode)
      service.invoke(BackgroundServiceEvents.onLog, {'message': message});
      // Enviar también a un colector remoto si está habilitado
      RemoteLogger.send(message, level: 'INFO');
    },
  );

  // Registrar todos los handlers de eventos del servicio
  _registerEventHandlers(service, detector);

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

/// Registra todos los handlers de eventos del servicio en segundo plano.
void _registerEventHandlers(ServiceInstance service, CarExitDetector detector) {
  // Registrar handlers de comandos
  _registerCommandHandlers(service, detector);

  // Registrar handlers de eventos
  _registerEventHandlerHandlers(service, detector);
}

/// Registra los handlers de comandos (UI → Servicio).
void _registerCommandHandlers(
  ServiceInstance service,
  CarExitDetector detector,
) {
  // ===== Handlers de control del detector =====

  // Handler para iniciar el detector
  handleServiceEvent(service, BackgroundServiceCommands.startDetector, () {
    detector.start();
    return {'status': 'started'};
  });

  // Handler para detener el detector
  handleServiceEvent(service, BackgroundServiceCommands.stopDetector, () {
    detector.stop();
    return {'status': 'stopped'};
  });

  // Handlers de gestión de beacons eliminados

  // ===== Handlers de consulta de estado =====

  // Get active strategy event
  handleServiceEvent(
    service,
    BackgroundServiceCommands.getActiveStrategy,
    () =>
        ActiveStrategyEvent(
          strategyName:
              detector.activeStrategy?.runtimeType.toString() ?? 'none',
        ).toJson(),
  );

  // Get current detector state event
  handleServiceEvent(
    service,
    BackgroundServiceCommands.getCurrentState,
    () =>
        CurrentStateEvent(stateName: detector.currentState.toString()).toJson(),
  );
}

/// Registra los handlers de eventos (Servicio → UI).
void _registerEventHandlerHandlers(
  ServiceInstance service,
  CarExitDetector detector,
) {
  // Los eventos se emiten desde los callbacks del detector
  // que ya están configurados en la creación del CarExitDetector
}
