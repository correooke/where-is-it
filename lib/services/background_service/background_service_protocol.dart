/// Protocolo de eventos para la comunicación con el servicio en segundo plano
library;

/// Representa el evento de cambio de estado global del carro
class CarExitStateChangedEvent {
  final String newState;
  final String oldState;

  CarExitStateChangedEvent({required this.newState, required this.oldState});

  Map<String, dynamic> toJson() => {'newState': newState, 'oldState': oldState};

  factory CarExitStateChangedEvent.fromJson(Map<String, dynamic> json) {
    return CarExitStateChangedEvent(
      newState: json['newState'] as String,
      oldState: json['oldState'] as String,
    );
  }
}

/// Representa el evento de detección de salida del vehículo
class CarExitDetectedEvent {
  final double latitude;
  final double longitude;
  final int timestamp;

  CarExitDetectedEvent({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp,
  };

  factory CarExitDetectedEvent.fromJson(Map<String, dynamic> json) {
    return CarExitDetectedEvent(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      timestamp: json['timestamp'] as int,
    );
  }
}

/// Representa el evento de cambio de estrategia de detección
class StrategyChangedEvent {
  final String newStrategy;
  final String oldStrategy;

  StrategyChangedEvent({required this.newStrategy, required this.oldStrategy});

  Map<String, dynamic> toJson() => {
    'newStrategy': newStrategy,
    'oldStrategy': oldStrategy,
  };

  factory StrategyChangedEvent.fromJson(Map<String, dynamic> json) {
    return StrategyChangedEvent(
      newStrategy: json['newStrategy'] as String,
      oldStrategy: json['oldStrategy'] as String,
    );
  }
}

/// Representa el evento de consulta de estrategia activa
class ActiveStrategyEvent {
  final String strategyName;

  ActiveStrategyEvent({required this.strategyName});

  Map<String, dynamic> toJson() => {'strategyName': strategyName};

  factory ActiveStrategyEvent.fromJson(Map<String, dynamic> json) {
    return ActiveStrategyEvent(strategyName: json['strategyName'] as String);
  }
}

/// Representa el evento de reevaluación de estrategias
class ReevaluatedEvent {
  final String strategy;

  ReevaluatedEvent({required this.strategy});

  Map<String, dynamic> toJson() => {'strategy': strategy};

  factory ReevaluatedEvent.fromJson(Map<String, dynamic> json) {
    return ReevaluatedEvent(strategy: json['strategy'] as String);
  }
}

/// Evento que representa un beacon asociado al vehículo.
class AssociatedBeaconEvent {
  final String beaconId;
  final String deviceName;

  AssociatedBeaconEvent({
    required this.beaconId,
    this.deviceName = 'Dispositivo desconocido',
  });

  Map<String, dynamic> toJson() => {
    'beaconId': beaconId,
    'deviceName': deviceName,
  };

  factory AssociatedBeaconEvent.fromJson(Map<String, dynamic> json) {
    return AssociatedBeaconEvent(
      beaconId: json['beaconId'] as String,
      deviceName: json['deviceName'] as String? ?? 'Dispositivo desconocido',
    );
  }
}

/// Representa el evento de consulta del estado actual del detector
class CurrentStateEvent {
  final String stateName;

  CurrentStateEvent({required this.stateName});

  Map<String, dynamic> toJson() => {'stateName': stateName};

  factory CurrentStateEvent.fromJson(Map<String, dynamic> json) {
    return CurrentStateEvent(stateName: json['stateName'] as String);
  }
}
