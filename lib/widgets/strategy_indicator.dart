import 'package:flutter/material.dart';

/// Widget pequeño para mostrar la estrategia activa en la pantalla principal.
///
/// Se utiliza en MapScreen como un indicador flotante en la esquina inferior izquierda
/// del mapa. Proporciona información rápida sobre qué estrategia de detección
/// está activa sin ocupar mucho espacio en la interfaz principal.
///
/// Diferencias con ActiveStrategyCard:
/// - ActiveStrategyCard: Se usa en SettingsScreen, es más grande y detallado
/// - StrategyIndicator: Se usa en MapScreen, es compacto y discreto
///
/// Ejemplo de uso: Muestra "Actividad" o "Beacon" en un indicador pequeño sobre el mapa
class StrategyIndicator extends StatelessWidget {
  final String strategyName;

  const StrategyIndicator({super.key, required this.strategyName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.radar, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            _formatStrategyName(strategyName),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Formatea el nombre de la estrategia para mejor visualización
  String _formatStrategyName(String name) {
    if (name.isEmpty) {
      return 'Sin estrategia';
    }
    return name;
  }
}
