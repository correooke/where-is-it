import 'dart:developer' as dev;

class Logger {
  static const String _mapViewModelTag = 'MapViewModel';
  static const String _detectionStrategyTag = 'ActivityBasedDetectionStrategy';

  // MapViewModel logs
  static void logMapViewModel(String message) {
    dev.log(message, name: _mapViewModelTag);
  }

  static void logMapViewModelError(String message, [Object? error]) {
    dev.log(
      error != null ? '$message: $error' : message,
      name: _mapViewModelTag,
      error: error,
    );
  }

  // Detection Strategy logs
  static void logDetectionStrategy(String message) {
    dev.log(message, name: _detectionStrategyTag);
  }

  static void logDetectionStrategyError(String message, [Object? error]) {
    dev.log(
      error != null ? '$message: $error' : message,
      name: _detectionStrategyTag,
      error: error,
    );
  }
}
