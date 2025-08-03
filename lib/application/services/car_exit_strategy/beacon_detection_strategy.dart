import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:collection/collection.dart';

import 'car_exit_detection_strategy.dart';
import 'car_exit_state.dart';
import 'location_info.dart';
import '../beacon_service.dart';
import '../../../domain/repositories/beacon_repository.dart';

/// Clase que centraliza los mensajes de log para el sistema de detección de beacons
class BeaconLogMessages {
  static const String strategyName = "BeaconDetectionStrategy";
  // Mensajes de estado
  static const String noBeaconAssociated = "No hay beacon asociado al vehículo";
  static const String bluetoothNotAvailable =
      "Bluetooth no disponible en el dispositivo";
  static const String bluetoothOff = "Bluetooth apagado";
  static const String monitoringAlreadyActive =
      "El monitoreo de beacon ya está activo";
  static const String monitoringStopped = "Monitoreo de beacon detenido";

  // Mensajes de detección
  static String beaconDetected(String deviceId, int rssi, double distance) =>
      "Beacon detectado: $deviceId, RSSI: $rssi, Distancia aprox: ${distance.toStringAsFixed(1)}m";
  static String stateChanged(
    CarExitState oldState,
    CarExitState newState,
    double distance,
  ) =>
      "Cambio de estado por beacon: $oldState -> $newState (distancia: ${distance.toStringAsFixed(1)}m)";

  // Mensajes de error
  static String error(String context, Object? error) =>
      "ERROR: $context: ${error != null ? error.toString() : 'sin detalles'}";
  static String errorInCallback(Object error) =>
      "Error adicional en callback onError: $error";

  // Mensajes de error específicos
  static const String errorBeaconAvailability =
      "Error al verificar disponibilidad de beacon";
  static const String errorInitStrategy =
      "Error al inicializar estrategia de beacon";
  static const String errorInStateChangedCallback =
      "Error en callback onStateChanged";
  static const String errorProcessingLocation = "Error al procesar ubicación";
  static const String errorDuringScan = "Error durante el escaneo de beacons";
  static const String errorStartingScan = "Error al iniciar escaneo de beacon";
  static const String errorStoppingScan = "Error al detener escaneo";
}

/// Estrategia para detectar la salida del vehículo mediante beacons Bluetooth
class BeaconDetectionStrategy extends CarExitDetectionStrategy {
  // Servicio para manejar la gestión de beacons
  final BeaconService _beaconService;

  // Parámetros de configuración
  final double exitThresholdDistance; // RSSI convertido a distancia aproximada

  // Suscripción a eventos de beacon
  StreamSubscription? _beaconDetectionSubscription;

  // Estado del monitoreo
  bool _isMonitoring = false;
  String? _associatedBeaconId;
  Map<String, dynamic>? _associatedBeaconFingerprint;

  // Estado de detección actual
  DateTime? _lastBeaconDetection;

  // Estado actual del detector
  CarExitState _currentState = CarExitState.unknown;

  // Timer para timeout de no detección
  Timer? _beaconTimeoutTimer;
  final Duration beaconTimeoutDuration = const Duration(
    seconds: 15,
  ); // configurable

  BeaconDetectionStrategy({
    required BeaconRepository beaconRepository,
    this.exitThresholdDistance = 2.0, // 2 metros por defecto
    int scanInterval = 5000, // 5 segundos entre escaneos
    int scanDuration = 4000, // 4 segundos duración de cada escaneo
    int rssiThreshold = -55, // Umbral RSSI
    super.context,
    super.priority = 30, // Prioridad más alta que actividad (20)
  }) : _beaconService = BeaconService(beaconRepository) {
    // Configurar el servicio de beacons con los parámetros necesarios
    _beaconService.configure(
      BeaconScanConfig(
        scanInterval: scanInterval,
        scanDuration: scanDuration,
        rssiThreshold: rssiThreshold,
        debugMode:
            true, // Activar modo de depuración para ver todos los dispositivos
      ),
    );
  }

  @override
  Future<bool> checkAvailability() async {
    try {
      // Verificar si hay un beacon asociado
      final beaconId = await _beaconService.getAssociatedBeaconId();
      if (beaconId == null || beaconId.isEmpty) {
        _logger.info(BeaconLogMessages.noBeaconAssociated);
        return false;
      }

      _associatedBeaconId = beaconId;

      // Verificar si el Bluetooth está disponible
      if (!(await _beaconService.isBluetoothAvailable())) {
        _logger.info(BeaconLogMessages.bluetoothNotAvailable);
        return false;
      }

      return true;
    } catch (e) {
      _handleError(BeaconLogMessages.errorBeaconAvailability, e);
      return false;
    }
  }

  @override
  Future<bool> initializeStrategy() async {
    if (_isMonitoring) {
      _logger.info(BeaconLogMessages.monitoringAlreadyActive);
      return true;
    }

    try {
      // Cargar el fingerprint asociado
      _associatedBeaconFingerprint =
          await _beaconService.getAssociatedBeaconFingerprint();
      // Suscribirse a eventos de detección de beacons
      _beaconDetectionSubscription = _beaconService.onBeaconDetected.listen(
        _handleBeaconDetection,
        onError: (e) => _handleError(BeaconLogMessages.errorDuringScan, e),
      );

      // Iniciar escaneo periódico
      final success = await _beaconService.startPeriodicScan();
      if (success) {
        _isMonitoring = true;
        // Lanzar un escaneo único para detección inmediata
        final results = await _beaconService.scanOnce(
          timeout: const Duration(seconds: 3),
        );
        final foundResult = results
            .cast<ScanResult?>()
            .map((result) {
              if (result == null) return null;
              final event = BeaconDetectionEvent(
                deviceId: result.device.remoteId.toString(),
                rssi: result.rssi,
                distance: _calculateDistance(
                  result.rssi,
                  result.advertisementData.txPowerLevel ??
                      _beaconService.config.txPower,
                  [], // No tenemos historial aquí, pero puedes pasar una lista vacía
                ),
                timestamp: DateTime.now(),
                additionalData: {
                  'name': result.device.platformName,
                  'serviceUuids':
                      result.advertisementData.serviceUuids
                          .map((u) => u.toString())
                          .toList(),
                  'manufacturerData': result.advertisementData.manufacturerData,
                },
              );
              return _isAssociatedBeacon(event) ? event : null;
            })
            .firstWhere((e) => e != null, orElse: () => null);
        if (foundResult != null) {
          _updateStateBasedOnDistance(foundResult.distance);
        }
      }
      return success;
    } catch (e) {
      _handleError(BeaconLogMessages.errorInitStrategy, e);
      return false;
    }
  }

  @override
  void dispose() {
    _beaconDetectionSubscription?.cancel();
    _beaconService.stopPeriodicScan();
    _isMonitoring = false;
    _beaconTimeoutTimer?.cancel();
    _logger.info(BeaconLogMessages.monitoringStopped);
  }

  @override
  void handleStateChange(CarExitState newState, CarExitState oldState) {
    try {
      onStateChanged?.call(newState, oldState);
    } catch (e) {
      _handleError(BeaconLogMessages.errorInStateChangedCallback, e);
    }
  }

  @override
  void processLocation(LocationInfo location) {
    // En esta estrategia no procesamos ubicaciones GPS directamente,
    // pero podríamos usarlas para mejorar la precisión
    try {
      // onLocationDetected?.call(location);
    } catch (e) {
      _handleError(BeaconLogMessages.errorProcessingLocation, e);
    }
  }

  @override
  void checkForCarExit() {
    // En nuestra implementación, esto se maneja automáticamente
    // durante el escaneo de beacons
  }

  @override
  void reset() {
    _lastBeaconDetection = null;
    _beaconTimeoutTimer?.cancel();
  }

  // Procesa los eventos de beacons detectados
  void _handleBeaconDetection(BeaconDetectionEvent event) {
    // Verificar si es nuestro beacon asociado usando fingerprint
    if (_isAssociatedBeacon(event)) {
      _lastBeaconDetection = event.timestamp;

      // Reiniciar el timer de timeout
      _resetBeaconTimeoutTimer();

      _logger.debug(
        BeaconLogMessages.beaconDetected(
          event.deviceId,
          event.rssi,
          event.distance,
        ),
      );

      // Determinar el estado basado en la distancia
      _updateStateBasedOnDistance(event.distance);
    }
  }

  // Compara el evento con el fingerprint asociado
  bool _isAssociatedBeacon(BeaconDetectionEvent event) {
    if (_associatedBeaconFingerprint == null) {
      // Fallback: comparar solo por deviceId
      return _associatedBeaconId != null &&
          event.deviceId == _associatedBeaconId;
    }
    // Compara manufacturerData, serviceUuids y nombre
    final eventMfr = event.additionalData['manufacturerData'] as Map?;
    final eventUuids = event.additionalData['serviceUuids'] as List?;
    final eventName =
        (event.additionalData['name'] ?? '').toString().toLowerCase();
    final fMfr = _associatedBeaconFingerprint!['manufacturerData'] as Map?;
    final fUuids = _associatedBeaconFingerprint!['serviceUuids'] as List?;
    final fName =
        (_associatedBeaconFingerprint!['name'] ?? '').toString().toLowerCase();

    bool mfrMatch =
        fMfr != null &&
        eventMfr != null &&
        MapEquality().equals(eventMfr, fMfr);
    bool uuidMatch =
        fUuids != null &&
        eventUuids != null &&
        Set.from(eventUuids).containsAll(fUuids);
    bool nameMatch = fName.isNotEmpty && eventName == fName;

    // Considera match si al menos 2 de 3 coinciden
    int matches =
        (mfrMatch ? 1 : 0) + (uuidMatch ? 1 : 0) + (nameMatch ? 1 : 0);
    return matches >= 2;
  }

  // Actualiza el estado basado en la distancia al beacon
  void _updateStateBasedOnDistance(double distance) {
    CarExitState newState = _currentState;

    // Si la distancia es inválida o muy grande, asumimos que estamos lejos
    if (distance < 0 || distance > exitThresholdDistance) {
      // Si estábamos detenidos y ahora estamos lejos, significa que salimos
      newState = CarExitState.exited;
    } else {
      // Estamos cerca del beacon
      newState = CarExitState.driving;
    }

    if (newState != _currentState) {
      _logger.info(
        BeaconLogMessages.stateChanged(_currentState, newState, distance),
      );
      final oldState = _currentState;
      _currentState = newState;
      handleStateChange(newState, oldState);
    }
  }

  void _resetBeaconTimeoutTimer() {
    _beaconTimeoutTimer?.cancel();
    _beaconTimeoutTimer = Timer(beaconTimeoutDuration, _onBeaconTimeout);
  }

  void _onBeaconTimeout() {
    if (_currentState != CarExitState.exited) {
      _logger.info(
        'No se detectó el beacon en el tiempo esperado. Cambiando a EXITED.',
      );
      final oldState = _currentState;
      _currentState = CarExitState.exited;
      handleStateChange(CarExitState.exited, oldState);
    }
  }

  // Logger interno
  final _logger = BeaconLogger(name: BeaconLogMessages.strategyName);

  // Utilitarios para el manejo de errores y logging
  void _handleError(String message, Object? error) {
    _logger.error(BeaconLogMessages.error(message, error));

    try {
      // onError?.call(message, error);
    } catch (e) {
      _logger.error(BeaconLogMessages.errorInCallback(e));
    }
  }

  @override
  CarExitState getCurrentState() => _currentState;

  double _calculateDistance(int rssi, int txPower, List<int> rssiHistory) {
    if (rssi == 0) return -1.0; // No válido
    const double n = 2.7;
    final double ratio = (txPower - rssi) / (10 * n);
    double distance = math.pow(10, ratio).toDouble();
    if (rssiHistory.length > 3) {
      int avgRssi = rssiHistory.reduce((a, b) => a + b) ~/ rssiHistory.length;
      double avgDistance =
          math.pow(10, (txPower - avgRssi) / (10 * n)).toDouble();
      distance = (distance * 0.3) + (avgDistance * 0.7);
    }
    return distance;
  }
}

/// Niveles de log disponibles
enum LogLevel { debug, info, warning, error }

/// Clase para gestionar logs con niveles y filtrado
class BeaconLogger {
  final String name;
  static LogLevel minLevel = LogLevel.info; // Nivel mínimo de log por defecto

  const BeaconLogger({required this.name});

  void debug(String message) {
    if (minLevel.index <= LogLevel.debug.index) {
      _log(message, 'DEBUG');
    }
  }

  void info(String message) {
    if (minLevel.index <= LogLevel.info.index) {
      _log(message, 'INFO');
    }
  }

  void warning(String message) {
    if (minLevel.index <= LogLevel.warning.index) {
      _log(message, 'WARNING');
    }
  }

  void error(String message) {
    if (minLevel.index <= LogLevel.error.index) {
      _log(message, 'ERROR');
    }
  }

  void _log(String message, String level) {
    dev.log('[$level] $message', name: name);
  }
}
