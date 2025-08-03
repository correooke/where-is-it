import 'package:flutter/material.dart';

/// Widget que muestra la estrategia de detección activa en la pantalla de configuración.
///
/// Se utiliza en SettingsScreen para mostrar al usuario qué estrategia de detección
/// está actualmente activa. Muestra el nombre de la estrategia en una tarjeta
/// con un icono de seguimiento, proporcionando información clara sobre el
/// método de detección que se está utilizando.
///
/// Ejemplo de uso: Muestra "Estrategia basada en actividad" o "Estrategia basada en beacon"
class ActiveStrategyCard extends StatelessWidget {
  final String activeStrategyName;

  const ActiveStrategyCard({super.key, required this.activeStrategyName});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.track_changes, color: Colors.blue),
        title: const Text('Estrategia activa'),
        subtitle: Text(activeStrategyName),
      ),
    );
  }
}
