import 'dart:async';
// import 'package:flutter/services.dart';
import 'car_exit_detection_strategy.dart';
import 'car_exit_state.dart';
import 'location_info.dart';
import '../../../utils/logger.dart';
import 'package:parking_detector_plugin/parking_detector_plugin.dart';

/// Estrategia de detección basada en el reconocimiento de actividad nativo (Kotlin).
class ActivityBasedDetectionStrategy extends CarExitDetectionStrategy {
  // Suscripción al stream de eventos
  StreamSubscription<dynamic>? _parkingStateSubscription;

  // Estado actual del detector
  CarExitState _currentState = CarExitState.unknown;
  CarExitState get currentState => _currentState;

  // Última ubicación conocida (provisional) al pasar a STOPPED.
  LocationInfo? _lastKnownLocation;

  // Momento en que se entró en estado STOPPED
  DateTime? _enteredStoppedStateTime;

  // Parámetros específicos para detección
  final double drivingSpeedThreshold;
  final int stoppedDurationSeconds;
  final int minStoppedBeforeExitSeconds;

  // Callback específico para notificar que se ha detectado la salida del vehículo
  final void Function(LocationInfo location)? onCarExitDetected;

  ActivityBasedDetectionStrategy({
    this.drivingSpeedThreshold = 10.0,
    this.stoppedDurationSeconds = 10,
    this.minStoppedBeforeExitSeconds = 30,
    this.onCarExitDetected,
    super.context,
    super.priority = 10, // Prioridad media-alta por defecto
  });

  /// Mapeo de estados de ParkingState (Kotlin) a CarExitState (Dart)
  CarExitState _mapNativeStateToCarExitState(String nativeState) {
    switch (nativeState) {
      case 'DRIVING':
        return CarExitState.driving;
      case 'TENTATIVE_PARKED':
        return CarExitState.stopped;
      case 'CONFIRMED_PARKED':
        return CarExitState.exited;
      case 'UNKNOWN':
      default:
        return CarExitState.unknown;
    }
  }

  @override
  Future<bool> checkAvailability() async {
    // Verificar si el servicio nativo está disponible
    try {
      await ParkingDetectorPlugin.getCurrentState();
      return true;
    } catch (e) {
      Logger.logDetectionStrategyError('Error checking availability', e);
      return false;
    }
  }

  @override
  Future<bool> initializeStrategy() async {
    try {
      Logger.logDetectionStrategy(
        'ActivityBasedDetectionStrategy: initializeStrategy() start',
      );

      // Suscribirse al stream de eventos de estado
      _parkingStateSubscription = ParkingDetectorPlugin.parkingEvents.listen(
        _handleParkingStateEvent,
        onError: (error) {
          Logger.logDetectionStrategyError(
            'Error receiving parking state events',
            error,
          );
        },
      );

      // Iniciar el servicio nativo
      final bool success = await ParkingDetectorPlugin.startParkingDetection();

      // Estado inicial
      _changeState(CarExitState.unknown);

      Logger.logDetectionStrategy(
        'ActivityBased: monitor started. Initial state: $_currentState, success: $success',
      );
      return success;
    } catch (e) {
      Logger.logDetectionStrategyError(
        'ActivityBasedDetectionStrategy: initializeStrategy error',
        e,
      );
      return false;
    }
  }

  /// Maneja eventos de estado recibidos desde el código nativo
  void _handleParkingStateEvent(dynamic event) {
    if (event is! Map) {
      Logger.logDetectionStrategy('Received invalid event format: $event');
      return;
    }

    final String? stateStr = event['state'] as String?;
    if (stateStr == null) {
      Logger.logDetectionStrategy('Received event without state: $event');
      return;
    }

    final CarExitState newState = _mapNativeStateToCarExitState(stateStr);
    Logger.logDetectionStrategy(
      'Received native state: $stateStr -> $newState',
    );

    // Cambiar estado según el evento recibido
    _changeState(newState);
  }

  @override
  void dispose() {
    try {
      // Detener el servicio nativo
      ParkingDetectorPlugin.stopParkingDetection();

      // Cancelar suscripción a eventos
      _parkingStateSubscription?.cancel();
      _parkingStateSubscription = null;

      Logger.logDetectionStrategy('Monitorización detenida.');
    } catch (e) {
      _handleError('Error al detener el monitoreo', e);
    }
  }

  @override
  void handleStateChange(CarExitState newState, CarExitState oldState) {
    try {
      onStateChanged?.call(newState, oldState);
    } catch (e) {
      _handleError('Error en callback onStateChanged', e);
    }
  }

  @override
  void processLocation(LocationInfo location) {
    try {
      // Almacenar la última ubicación conocida para enviarla cuando se detecte la salida
      _lastKnownLocation = location;

      onLocationDetected?.call(location);
    } catch (e) {
      _handleError('Error al procesar datos de ubicación', e);
    }
  }

  @override
  void checkForCarExit() {
    if (_enteredStoppedStateTime != null) {
      final stoppedDuration = DateTime.now().difference(
        _enteredStoppedStateTime!,
      );
      if (stoppedDuration.inSeconds < minStoppedBeforeExitSeconds) {
        Logger.logDetectionStrategy(
          'Ignorando posible salida - tiempo detenido insuficiente (${stoppedDuration.inSeconds}s < ${minStoppedBeforeExitSeconds}s)',
        );
        return; // No realizar la transición aún
      }
      _changeState(CarExitState.exited);
    } else {
      Logger.logDetectionStrategy(
        'No se puede confirmar salida - desconocemos cuándo se entró en STOPPED',
      );
    }
  }

  @override
  void reset() {
    _changeState(CarExitState.unknown);
    _lastKnownLocation = null;
    _enteredStoppedStateTime = null;
    Logger.logDetectionStrategy('Estrategia reiniciada');

    // Forzar reinicio del servicio nativo
    ParkingDetectorPlugin.stopParkingDetection()
        .then((_) => ParkingDetectorPlugin.startParkingDetection())
        .catchError((e) => _handleError('Error al reiniciar el servicio', e));
  }

  /// Cambia el estado interno y notifica el cambio
  void _changeState(CarExitState newState) {
    if (_currentState == newState) return;

    final oldState = _currentState;
    Logger.logDetectionStrategy('Transición: $_currentState --> $newState');
    _currentState = newState;

    // Notificar el cambio de estado
    handleStateChange(newState, oldState);

    // Lógica específica para cada estado
    switch (newState) {
      case CarExitState.stopped:
        _enteredStoppedStateTime = DateTime.now();
        break;

      case CarExitState.exited:
        // Al confirmar la salida, se notifica la ubicación definitiva
        if (_lastKnownLocation != null) {
          try {
            onCarExitDetected?.call(_lastKnownLocation!);
          } catch (e) {
            _handleError('Error en callback onCarExitDetected', e);
          }
          Logger.logDetectionStrategy(
            'Salida confirmada en: $_lastKnownLocation',
          );
        } else {
          Logger.logDetectionStrategy(
            'Salida confirmada pero no se ha recibido ubicación.',
          );
        }
        break;

      case CarExitState.driving:
        // Reiniciamos variables de estado
        _enteredStoppedStateTime = null;
        break;

      case CarExitState.unknown:
        // Estado inicial: sin acción específica
        break;
    }
  }

  /// Maneja errores y notifica si es necesario
  void _handleError(String message, Object? error) {
    final errorMsg =
        "$message: ${error != null ? error.toString() : 'sin detalles'}";
    Logger.logDetectionStrategyError(errorMsg);
  }

  @override
  CarExitState getCurrentState() => _currentState;
}
