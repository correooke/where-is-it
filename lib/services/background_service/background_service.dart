import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:where_is_it/application/services/car_exit_strategy/index.dart';
import 'package:where_is_it/infrastructure/repositories/beacon_repository_impl.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:where_is_it/application/services/beacon_service.dart';

import 'background_service_events.dart';
import 'background_service_protocol.dart';
import 'handlers.dart';

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
      initialNotificationTitle: 'Monitoreo activo',
      initialNotificationContent: 'Detectando salida del vehículo',
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
  // Make sure the service runs in foreground after start
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  // BeaconService for persistence operations
  final beaconService = BeaconService(BeaconRepositoryImpl());

  // Suscribir al stream de actividad con el nuevo plugin
  FlutterActivityRecognition.instance.activityStream.listen((activity) {
    service.invoke(BackgroundServiceEvents.onStateChanged, {
      'activity': activity.type.toString(),
      'confidence': activity.confidence.index,
    });
  });

  // Create detector with proper callbacks
  final CarExitDetector detector = CarExitDetector(
    strategies: [
      ActivityBasedDetectionStrategy(),
      BeaconDetectionStrategy(beaconRepository: BeaconRepositoryImpl()),
    ],
    onStateChanged: (newState, oldState) {
      service.invoke(
        BackgroundServiceEvents.onStateChanged,
        CarExitStateChangedEvent(
          newState: newState.toString(),
          oldState: oldState.toString(),
        ).toJson(),
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
    },
    onStrategyChanged: (newStrategy, oldStrategy) {
      service.invoke(
        BackgroundServiceEvents.onStrategyChanged,
        StrategyChangedEvent(
          newStrategy: newStrategy?.runtimeType.toString() ?? 'none',
          oldStrategy: oldStrategy?.runtimeType.toString() ?? 'none',
        ).toJson(),
      );
    },
  );

  // Registrar todos los handlers de eventos del servicio
  _registerEventHandlers(service, detector, beaconService);

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
void _registerEventHandlers(
  ServiceInstance service,
  CarExitDetector detector,
  BeaconService beaconService,
) {
  // Registrar handlers de comandos
  _registerCommandHandlers(service, detector, beaconService);

  // Registrar handlers de eventos
  _registerEventHandlerHandlers(service, detector);
}

/// Registra los handlers de comandos (UI → Servicio).
void _registerCommandHandlers(
  ServiceInstance service,
  CarExitDetector detector,
  BeaconService beaconService,
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

  // ===== Handlers de gestión de beacons =====

  // Handle getAssociatedBeacon command from UI
  handleServiceCommand<String?>(
    service,
    BackgroundServiceCommands.getAssociatedBeacon,
    (_) async => await beaconService.getAssociatedBeaconId(),
    BackgroundServiceEvents.onAssociatedBeacon,
    (id) =>
        AssociatedBeaconEvent(
          beaconId: id ?? '',
          deviceName:
              'Dispositivo asociado', // Valor por defecto para consultas
        ).toJson(),
  );

  // Handle associateBeacon command from UI
  handleServiceCommand<Map<String, dynamic>>(
    service,
    BackgroundServiceCommands.associateBeacon,
    (payload) async {
      final id = payload?['beaconId'] as String;
      final deviceName =
          payload?['deviceName'] as String? ?? 'Dispositivo desconocido';
      final fingerprint = payload?['fingerprint'] as Map<String, dynamic>?;
      await beaconService.associateBeacon(id, fingerprint: fingerprint);
      await detector.changeStrategy();
      return {'beaconId': id, 'deviceName': deviceName};
    },
    BackgroundServiceEvents.onAssociatedBeacon,
    (result) =>
        AssociatedBeaconEvent(
          beaconId: result['beaconId'] as String,
          deviceName: result['deviceName'] as String,
        ).toJson(),
  );

  // Handle dissociateBeacon command from UI
  handleServiceCommand<void>(
    service,
    BackgroundServiceCommands.dissociateBeacon,
    (_) async {
      await beaconService.dissociateBeacon();
      await detector.changeStrategy();
      return;
    },
    BackgroundServiceEvents.onBeaconDissociated,
    (_) => {},
  );

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
