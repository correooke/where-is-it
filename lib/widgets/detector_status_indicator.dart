import 'package:flutter/material.dart';
import '../application/services/car_exit_strategy/index.dart';

class DetectorStateVisuals {
  final IconData icon;
  final Color color;
  final String text;

  DetectorStateVisuals({
    required this.icon,
    required this.color,
    required this.text,
  });
}

/// Widget que muestra el estado actual del detector de salida del vehículo.
///
/// Se utiliza en la barra de acciones de la pantalla principal (MapScreen)
/// para mostrar visualmente el estado del detector:
/// - Conduciendo: Icono de carro blanco
/// - Detenido: Icono de pausa naranja
/// - Salida: Icono de logout verde claro
/// - Detectando: Icono de ayuda gris claro
///
/// El widget muestra un icono y texto que cambia según el estado del detector.
class DetectorStatusIndicatorWidget extends StatelessWidget {
  final CarExitState state;
  const DetectorStatusIndicatorWidget({required this.state, super.key});

  DetectorStateVisuals _getVisualsForState(CarExitState state) {
    switch (state) {
      case CarExitState.driving:
        return _getDrivingVisuals();
      case CarExitState.stopped:
        return _getStoppedVisuals();
      case CarExitState.exited:
        return _getExitedVisuals();
      case CarExitState.unknown:
        return _getUnknownVisuals();
    }
  }

  DetectorStateVisuals _getDrivingVisuals() {
    return DetectorStateVisuals(
      icon: Icons.directions_car,
      color: Colors.white,
      text: _drivingText,
    );
  }

  DetectorStateVisuals _getStoppedVisuals() {
    return DetectorStateVisuals(
      icon: Icons.pause_circle_filled,
      color: Colors.orange,
      text: _stoppedText,
    );
  }

  DetectorStateVisuals _getExitedVisuals() {
    return DetectorStateVisuals(
      icon: Icons.logout,
      color: Colors.lightGreenAccent,
      text: _exitedText,
    );
  }

  DetectorStateVisuals _getUnknownVisuals() {
    return DetectorStateVisuals(
      icon: Icons.help_outline,
      color: Colors.white70,
      text: _unknownText,
    );
  }

  // Textos para internacionalización
  static const String _drivingText = 'Conduciendo';
  static const String _stoppedText = 'Detenido';
  static const String _exitedText = 'Salida';
  static const String _unknownText = 'Detectando';

  @override
  Widget build(BuildContext context) {
    final visuals = _getVisualsForState(state);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Icon(visuals.icon, color: visuals.color, size: 20),
          const SizedBox(width: 4),
          Text(
            visuals.text,
            style: TextStyle(fontSize: 12, color: visuals.color),
          ),
        ],
      ),
    );
  }
}
