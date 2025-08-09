import 'dart:async';
import 'package:flutter/material.dart';
import 'car_exit_state.dart';
import 'location_info.dart';

/// Interfaz que define la estrategia para detectar la salida del vehículo.
abstract class CarExitDetectionStrategy {
  /// Callback para notificar cuando se detecta una ubicación
  void Function(LocationInfo location)? onLocationDetected;

  /// Callback para notificar cuando ocurre una transición de estado
  void Function(CarExitState newState, CarExitState oldState)? onStateChanged;

  /// Callback para notificar errores
  void Function(String message, Object? error)? onError;

  /// Callback de log (opcional) para propagar mensajes hacia capas superiores
  void Function(String message)? onLog;

  /// Contexto de la aplicación, puede ser necesario para algunas implementaciones
  final BuildContext? context;

  /// Prioridad de la estrategia (valores más altos tienen mayor prioridad)
  final int priority;

  /// Constructor de la estrategia
  CarExitDetectionStrategy({this.context, this.priority = 0});

  /// Obtiene el estado actual de la estrategia
  CarExitState getCurrentState() => CarExitState.unknown;

  /// Verifica si la estrategia puede estar disponible (requisitos del sistema)
  Future<bool> checkAvailability();

  /// Inicializa la estrategia y comienza a monitorear
  Future<bool> initialize() async {
    // Verificar disponibilidad directamente
    final available = await checkAvailability();
    if (!available) {
      return false;
    }

    // Continuar con la inicialización específica
    return await initializeStrategy();
  }

  /// Método que debe ser implementado por las clases derivadas
  Future<bool> initializeStrategy();

  /// Detiene el monitoreo y libera recursos
  void dispose();

  /// Procesa un cambio de estado
  void handleStateChange(CarExitState newState, CarExitState oldState);

  /// Procesa una nueva ubicación detectada
  void processLocation(LocationInfo location);

  /// Verificar si se ha producido una salida del vehículo
  void checkForCarExit();

  /// Reinicia la estrategia a su estado inicial
  void reset();
}
