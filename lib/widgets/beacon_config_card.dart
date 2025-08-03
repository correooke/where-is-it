import 'package:flutter/material.dart';

/// Widget que muestra la configuración de beacon para el detector de salida del vehículo.
///
/// Se utiliza en la pantalla de configuración para permitir al usuario:
/// - Ver el estado actual del beacon (conectado/desconectado)
/// - Buscar y asociar un nuevo beacon
/// - Desasociar el beacon actual
/// - Ver información del dispositivo conectado
class BeaconConfigCard extends StatelessWidget {
  final String? selectedBeaconId;
  final String? deviceName;
  final bool isScanning;
  final VoidCallback onScan;
  final VoidCallback onDisassociate;

  const BeaconConfigCard({
    super.key,
    required this.selectedBeaconId,
    this.deviceName,
    required this.isScanning,
    required this.onScan,
    required this.onDisassociate,
  });

  // Textos para internacionalización
  static const String _configTitle = 'Configuración de Beacon';
  static const String _beaconConnectedText = 'Beacon conectado';
  static const String _noBeaconAssociatedText = 'No hay beacon asociado';
  static const String _deviceLabel = 'Dispositivo:';
  static const String _idLabel = 'ID:';
  static const String _disassociateButtonText = 'Desasociar beacon';
  static const String _searchAndAssociateButtonText = 'Buscar y asociar beacon';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTitleCard(),
        const SizedBox(height: 8.0),
        _buildConfigurationCard(),
      ],
    );
  }

  Widget _buildTitleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          _configTitle,
          style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildConfigurationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow(),
            if (selectedBeaconId != null) ...[
              const SizedBox(height: 8.0),
              _buildConnectedBeaconInfo(),
              const SizedBox(height: 16.0),
              _buildDisassociateButton(),
            ] else ...[
              const SizedBox(height: 16.0),
              _buildSearchButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    final isConnected = selectedBeaconId != null;
    return Row(
      children: [
        Icon(Icons.bluetooth, color: isConnected ? Colors.blue : Colors.grey),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            isConnected ? _beaconConnectedText : _noBeaconAssociatedText,
            style: TextStyle(
              fontSize: 16.0,
              color: isConnected ? Colors.blue : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedBeaconInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (deviceName != null && deviceName!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text('$_deviceLabel $deviceName'),
          ),
        Text('$_idLabel $selectedBeaconId'),
      ],
    );
  }

  Widget _buildDisassociateButton() {
    return ElevatedButton.icon(
      onPressed: onDisassociate,
      icon: const Icon(Icons.link_off),
      label: Text(_disassociateButtonText),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSearchButton() {
    return ElevatedButton.icon(
      onPressed: onScan,
      icon: const Icon(Icons.bluetooth_searching),
      label: Text(_searchAndAssociateButtonText),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
