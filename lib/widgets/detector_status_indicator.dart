import 'package:flutter/material.dart';
import '../application/models/car_exit_state.dart';

class DetectorStateVisuals {
  final IconData icon;
  final Color backgroundColor;
  final String text;

  const DetectorStateVisuals({
    required this.icon,
    required this.backgroundColor,
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
    return const DetectorStateVisuals(
      icon: Icons.directions_car,
      backgroundColor: Colors.blue,
      text: _drivingText,
    );
  }

  DetectorStateVisuals _getStoppedVisuals() {
    return const DetectorStateVisuals(
      icon: Icons.pause_circle_filled,
      backgroundColor: Colors.amber,
      text: _stoppedText,
    );
  }

  DetectorStateVisuals _getExitedVisuals() {
    return const DetectorStateVisuals(
      icon: Icons.local_parking,
      backgroundColor: Colors.green,
      text: _exitedText,
    );
  }

  DetectorStateVisuals _getUnknownVisuals() {
    return const DetectorStateVisuals(
      icon: Icons.hourglass_top,
      backgroundColor: Colors.grey,
      text: _unknownText,
    );
  }

  // Textos para internacionalización
  static const String _drivingText = 'Conduciendo';
  static const String _stoppedText = 'Detenido';
  static const String _exitedText = 'Estacionado';
  static const String _unknownText = 'Detectando';

  @override
  Widget build(BuildContext context) {
    final visuals = _getVisualsForState(state);
    return Chip(
      avatar: Icon(visuals.icon, color: Colors.white, size: 16),
      label: Text(
        visuals.text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: visuals.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: StadiumBorder(side: BorderSide(color: visuals.backgroundColor)),
    );
  }
}
