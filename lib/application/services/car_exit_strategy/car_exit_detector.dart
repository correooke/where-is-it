import 'dart:async';
import 'dart:collection';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';

import 'car_exit_detection_strategy.dart';
import 'car_exit_state.dart';
import 'location_info.dart';

/// Callback para notificar la detección de la salida del vehículo.
typedef CarExitCallback = void Function(LocationInfo exitLocation);

/// Callback para notificar cambios en el estado de la máquina.
typedef StateChangeCallback =
    void Function(CarExitState newState, CarExitState oldState);

/// Callback para notificar errores durante el monitoreo.
typedef ErrorCallback = void Function(String errorMessage, Object? error);

/// Callback para notificar cambios en la estrategia de detección.
typedef StrategyChangeCallback =
    void Function(
      CarExitDetectionStrategy? newStrategy,
      CarExitDetectionStrategy? oldStrategy,
    );

/// Callback para registrar mensajes de log del detector
typedef LogCallback = void Function(String message);

/// Clase principal para la detección de salida del vehículo utilizando el patrón Strategy.
class CarExitDetector {
  final BuildContext? context;
  final CarExitCallback? onCarExitDetected;
  final StateChangeCallback? onStateChanged;
  final ErrorCallback? onError;
  final StrategyChangeCallback? onStrategyChanged;
  final LogCallback? onLog;

  // Historial de ubicaciones compartido entre estrategias
  final int _maxLocationHistorySize;
  final Queue<LocationInfo> _locationHistory = Queue<LocationInfo>();

  // Lista de estrategias de detección
  final List<CarExitDetectionStrategy> _strategies;
  List<CarExitDetectionStrategy> get strategies =>
      List<CarExitDetectionStrategy>.from(_strategies)
        ..sort((a, b) => b.priority.compareTo(a.priority));

  // Estrategia actualmente activa
  CarExitDetectionStrategy? _activeStrategy;

  // Estado global del detector
  CarExitState _currentState = CarExitState.unknown;
  CarExitState get currentState => _currentState;

  // Estado de monitoreo
  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;

  // Última ubicación conocida
  LocationInfo? _lastKnownLocation;
  LocationInfo? get lastKnownLocation => _lastKnownLocation;

  /// Expose the current active strategy instance
  CarExitDetectionStrategy? get activeStrategy => _activeStrategy;

  /// Provide the name of the current active strategy for UI display
  String get activeStrategyName =>
      _activeStrategy?.runtimeType.toString() ?? 'Ninguna';

  CarExitDetector({
    required List<CarExitDetectionStrategy> strategies,
    this.context,
    this.onCarExitDetected,
    this.onStateChanged,
    this.onError,
    this.onStrategyChanged,
    this.onLog,
    int maxLocationHistorySize = 50,
  }) : _strategies = strategies,
       _maxLocationHistorySize = maxLocationHistorySize {
    // Configurar los callbacks de las estrategias
    for (final strategy in _strategies) {
      _configureStrategy(strategy);
    }
  }

  /// Configura los callbacks de una estrategia
  void _configureStrategy(CarExitDetectionStrategy strategy) {
    // Redirigir eventos de la estrategia a los métodos del detector
    strategy.onLocationDetected = _onLocationDetected;
    strategy.onStateChanged = _onStateChanged;
    strategy.onError = _onError;
  }

  /// Selecciona la estrategia activa con mayor prioridad que esté disponible
  Future<CarExitDetectionStrategy?> _selectBestAvailableStrategy() async {
    // Ya ordenamos las estrategias por prioridad, así que solo buscamos
    // la primera que esté disponible tras verificar
    for (final strategy in strategies) {
      final available = await strategy.checkAvailability();
      if (available) {
        _logMessage(
          "Estrategia disponible: ${strategy.runtimeType} (prioridad: ${strategy.priority})",
        );
        return strategy;
      }
    }

    _logMessage("No hay estrategias disponibles para usar");
    return null;
  }

  /// Inicia el monitoreo usando la estrategia de mayor prioridad disponible
  Future<bool> startMonitoring() async {
    if (_isMonitoring) {
      _logMessage("El monitoreo ya está activo.");
      return true;
    }

    // Inicializar todas las estrategias
    for (final strategy in strategies) {
      await strategy.initialize();
    }

    _isMonitoring = true;
    _logMessage("Monitoreo iniciado");

    // Delegar selección y notificación de estrategia
    return await changeStrategy();
  }

  /// Detiene el monitoreo en todas las estrategias
  void stopMonitoring() {
    for (final strategy in strategies) {
      strategy.dispose();
    }

    _activeStrategy = null;
    _isMonitoring = false;
    _logMessage("Monitoreo detenido");
  }

  /// Maneja la detección de una nueva ubicación desde una estrategia
  void _onLocationDetected(LocationInfo location) {
    // Añadir al historial y mantener tamaño límite
    _addToLocationHistory(location);

    // Actualizar la última ubicación conocida
    _lastKnownLocation = location;
  }

  /// Maneja un cambio de estado reportado por una estrategia
  void _onStateChanged(CarExitState newState, CarExitState oldState) {
    // Solo actualizar si el estado ha cambiado
    if (_currentState == newState) return;

    _logMessage("Cambio de estado: $_currentState --> $newState");
    final oldGlobalState = _currentState;
    _currentState = newState;

    // Si el nuevo estado es EXITED, notificar la detección
    if (newState == CarExitState.exited && _lastKnownLocation != null) {
      try {
        onCarExitDetected?.call(_lastKnownLocation!);
      } catch (e) {
        _onError("Error en callback onCarExitDetected", e);
      }
    }

    // Notificar el cambio de estado global
    try {
      onStateChanged?.call(newState, oldGlobalState);
    } catch (e) {
      _onError("Error en callback onStateChanged", e);
    }
  }

  /// Maneja errores reportados por las estrategias
  void _onError(String message, Object? error) {
    final errorMsg =
        "$message: ${error != null ? error.toString() : 'sin detalles'}";
    _logMessage("ERROR: $errorMsg");

    try {
      onError?.call(message, error);
    } catch (e) {
      _logMessage("Error adicional en callback onError: $e");
    }

    // Si hay un error en la estrategia activa, intentar cambiar a otra
    if (_activeStrategy != null) {
      _logMessage("Error en estrategia activa, intentando cambiar...");
      changeStrategy();
    }
  }

  /// Intenta cambiar a otra estrategia si la actual no está disponible
  Future<bool> changeStrategy() async {
    if (!_isMonitoring) return false;

    final oldStrategy = _activeStrategy;
    final newStrategy = await _selectBestAvailableStrategy();

    if (newStrategy == null) {
      _logMessage("No hay estrategias disponibles, deteniendo monitoreo");
      stopMonitoring();
      return false;
    }

    if (newStrategy == oldStrategy) {
      return true;
    }

    _activeStrategy = newStrategy;

    _logMessage(
      "Cambiando de estrategia: ${oldStrategy?.runtimeType} -> ${newStrategy.runtimeType}",
    );

    try {
      onStrategyChanged?.call(newStrategy, oldStrategy);
    } catch (e) {
      _onError("Error en callback onStrategyChanged", e);
    }

    // Actualizar el estado actual según la nueva estrategia
    final oldState = _currentState;
    // Usar el estado inicial de la estrategia; si no informa, usar unknown
    final CarExitState newState = newStrategy.getCurrentState();

    if (newState != oldState) {
      _logMessage(
        "Actualizando estado por cambio de estrategia: $oldState -> $newState",
      );
      _currentState = newState;

      try {
        onStateChanged?.call(newState, oldState);
      } catch (e) {
        _onError(
          "Error en callback onStateChanged durante cambio de estrategia",
          e,
        );
      }
    }

    return true;
  }

  /// Añade una ubicación al historial y mantiene el tamaño límite
  void _addToLocationHistory(LocationInfo location) {
    _locationHistory.add(location);
    while (_locationHistory.length > _maxLocationHistorySize) {
      _locationHistory.removeFirst();
    }
  }

  /// Obtiene el historial de ubicaciones
  List<LocationInfo> getLocationHistory() {
    return List.unmodifiable(_locationHistory);
  }

  /// Reinicia el detector y todas sus estrategias
  void reset() {
    for (final strategy in _strategies) {
      strategy.reset();
    }

    _currentState = CarExitState.unknown;
    _locationHistory.clear();
    _lastKnownLocation = null;
    _logMessage("Detector reiniciado");
  }

  /// Registra mensajes de log
  void _logMessage(String message) {
    dev.log(message, name: 'CarExitDetector');
    try {
      onLog?.call(message);
    } catch (_) {}
  }

  /// Inicia el monitoreo manualmente
  Future<bool> start() async {
    return await startMonitoring();
  }

  /// Detiene el monitoreo manualmente
  void stop() {
    stopMonitoring();
  }
}
