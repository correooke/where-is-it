import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:where_is_it/services/background_service/background_service_events.dart';
import 'package:where_is_it/services/background_service/background_service_protocol.dart';
import 'package:where_is_it/services/background_service/typed_listeners.dart';
import 'package:where_is_it/widgets/active_strategy_card.dart';
import 'package:where_is_it/widgets/beacon_config_card.dart';
import 'dart:developer' as dev;
import 'package:where_is_it/application/services/beacon_service.dart';
import 'package:where_is_it/domain/repositories/beacon_repository.dart';

class SettingsScreen extends StatefulWidget {
  final BeaconRepository beaconRepository;

  const SettingsScreen({super.key, required this.beaconRepository});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Durations for beacon scanning
  static const Duration _scanTimeout = Duration(seconds: 10);
  static const Duration _scanResultBufferDelay = Duration(milliseconds: 500);
  static const Duration _scanRetryDelay = Duration(seconds: 3);

  String? _selectedBeaconId;
  String? _deviceName;
  bool _isScanning = false;
  final FlutterBackgroundService _backgroundService =
      FlutterBackgroundService();
  String _activeStrategyName = 'Ninguna';
  final List<StreamSubscription> _subscriptions = [];

  // Servicio de beacon para manejar escaneos
  late BeaconService _beaconService;

  // Lista de resultados de escaneo para mostrar al usuario
  List<ScanResult> _scanResults = [];

  @override
  void initState() {
    super.initState();
    // Inicializar el servicio de beacon con el repositorio proporcionado
    _beaconService = BeaconService(widget.beaconRepository);

    _subscriptions.add(_getStrategyChangedListener());
    _subscriptions.add(_getInitialActiveStrategyListener());
    _subscriptions.add(_getAssociatedBeaconListener());
    _subscriptions.add(_getBeaconDissociatedListener());
    _backgroundService.invoke(BackgroundServiceCommands.getAssociatedBeacon);
    _backgroundService.invoke(BackgroundServiceCommands.getActiveStrategy);
  }

  StreamSubscription _getStrategyChangedListener() {
    return _backgroundService
        .onEvent<StrategyChangedEvent>(
          BackgroundServiceEvents.onStrategyChanged,
          StrategyChangedEvent.fromJson,
        )
        .listen((payload) {
          if (!mounted) return;
          setState(() => _activeStrategyName = payload.newStrategy);
        });
  }

  StreamSubscription _getInitialActiveStrategyListener() {
    return _backgroundService
        .onEvent<ActiveStrategyEvent>(
          BackgroundServiceCommands.getActiveStrategy,
          ActiveStrategyEvent.fromJson,
        )
        .listen((payload) {
          if (!mounted) return;
          setState(() => _activeStrategyName = payload.strategyName);
        });
  }

  StreamSubscription _getAssociatedBeaconListener() {
    return _backgroundService
        .onEvent<AssociatedBeaconEvent>(
          BackgroundServiceEvents.onAssociatedBeacon,
          AssociatedBeaconEvent.fromJson,
        )
        .listen((event) {
          if (!mounted) return;
          if (event.beaconId.isNotEmpty) {
            setState(() {
              _selectedBeaconId = event.beaconId;
              _deviceName = event.deviceName;
            });
            _showSnackBar(
              'Beacon asociado correctamente.',
              backgroundColor: Colors.green,
              debugMessage:
                  'Beacon asociado: ${event.deviceName} (${event.beaconId})',
            );
          }
        });
  }

  StreamSubscription _getBeaconDissociatedListener() {
    return _backgroundService
        .onEvent<void>(BackgroundServiceEvents.onBeaconDissociated, (_) {})
        .listen((_) {
          if (!mounted) return;
          setState(() {
            _selectedBeaconId = null;
            _deviceName = null;
          });
          _showSnackBar(
            'Beacon desasociado correctamente.',
            backgroundColor: Colors.green,
          );
        });
  }

  // Muestra un SnackBar para el usuario y registra un log para debug
  void _showSnackBar(
    String userMessage, {
    String? debugMessage,
    Color backgroundColor = Colors.red,
  }) {
    // Loguear detalle para debug
    dev.log(debugMessage ?? userMessage, name: 'SettingsScreen');

    // Mostrar mensaje amigable al usuario
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(userMessage), backgroundColor: backgroundColor),
    );
  }

  // Método para verificar y solicitar los permisos necesarios
  Future<bool> _checkAndRequestPermissions() async {
    if (kIsWeb) return true; // En web no necesitamos los mismos permisos

    final permissionsToRequest = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    // Verificar estado actual de los permisos
    Map<Permission, PermissionStatus> statuses =
        await permissionsToRequest.request();

    // Verificar si alguno fue denegado
    final allGranted = statuses.values.every(
      (status) => status.isGranted || status.isLimited,
    );

    if (!allGranted) {
      _showSnackBar(
        'Necesitamos permisos de Bluetooth y ubicación para funcionar.',
        debugMessage: 'Permisos denegados: ${statuses.toString()}',
      );
      return false;
    }

    return true;
  }

  /// Muestra el diálogo de búsqueda de beacons.
  Future<void> _showScanningDialog() async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Impedir cerrar con botón atrás
          child: AlertDialog(
            title: const Text('Buscando beacons...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Escaneando dispositivos cercanos...'),
              ],
            ),
          ),
        );
      },
    );
    // Asegurar que el diálogo se muestre antes de continuar
    await Future.delayed(_scanResultBufferDelay);
  }

  /// Cierra el diálogo de búsqueda si está abierto.
  void _dismissScanningDialog() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// Muestra un diálogo con la lista de beacons encontrados
  Future<void> _showBeaconSelectionDialog(List<ScanResult> beacons) async {
    if (!mounted) return;

    // Ordenar por intensidad de señal (RSSI)
    beacons.sort((a, b) => b.rssi.compareTo(a.rssi));

    final selectedBeacon = await showDialog<ScanResult>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Beacons encontrados'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child:
                  beacons.isEmpty
                      ? const Text('No se encontraron beacons cercanos.')
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: beacons.length,
                        itemBuilder: (context, index) {
                          final device = beacons[index];
                          final deviceName = BeaconService.describeDevice(
                            device,
                          );
                          final deviceId = device.device.remoteId.toString();
                          final rssi = device.rssi;
                          // Calcular distancia aproximada
                          final txPower =
                              device.advertisementData.txPowerLevel ?? -59;
                          final n = 2.7; // Factor de pérdida de señal
                          final ratio = (txPower - rssi) / (10 * n);
                          final distance = double.parse(
                            (math.pow(10, ratio)).toStringAsFixed(1),
                          );
                          return ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deviceName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'ID: $deviceId',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  'RSSI: $rssi dBm (~${distance}m)',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            onTap: () => Navigator.of(context).pop(device),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );

    // Si el usuario seleccionó un beacon, confirmar la asociación
    if (selectedBeacon != null) {
      final deviceId = selectedBeacon.device.remoteId.toString();
      final deviceName = BeaconService.describeDevice(selectedBeacon);
      final deviceRssi = selectedBeacon.rssi;

      await _confirmAssociateBeacon(deviceName, deviceId, deviceRssi);
    }
  }

  /// Muestra un diálogo de confirmación genérico.
  Future<bool?> _showConfirmationDialog({
    required String title,
    required Widget content,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    bool destructive = false,
  }) async {
    if (!mounted) return false;
    return showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: content,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelText),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style:
                    destructive
                        ? TextButton.styleFrom(foregroundColor: Colors.red)
                        : null,
                child: Text(confirmText),
              ),
            ],
          ),
    );
  }

  /// Solicita confirmación para asociar un beacon.
  Future<bool> _showAssociateBeaconConfirmation(
    String deviceName,
    String deviceId,
    int deviceRssi,
  ) async {
    final payload = await _showConfirmationDialog(
      title: 'Asociar beacon',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nombre: $deviceName'),
          Text('ID: $deviceId'),
          Text('Intensidad de señal: $deviceRssi dBm'),
          const SizedBox(height: 16),
          const Text('¿Deseas asociar este beacon a tu vehículo?'),
        ],
      ),
    );
    return payload ?? false;
  }

  /// Confirma y ejecuta la asociación del beacon.
  Future<void> _confirmAssociateBeacon(
    String deviceName,
    String deviceId,
    int deviceRssi,
  ) async {
    final confirmed = await _showAssociateBeaconConfirmation(
      deviceName,
      deviceId,
      deviceRssi,
    );
    if (confirmed) {
      _backgroundService.invoke(BackgroundServiceCommands.associateBeacon, {
        'beaconId': deviceId,
        'deviceName': deviceName,
      });
    }
  }

  // Método para iniciar el escaneo de beacons
  Future<void> _startBeaconScan() async {
    if (kIsWeb) {
      _showSnackBar('La detección de beacons no está disponible en la web.');
      return;
    }

    // Evitar escaneos múltiples
    if (_isScanning) {
      _showSnackBar('Escaneo en progreso. Por favor espera.');
      return;
    }

    // Verificar permisos antes de iniciar el escaneo
    final hasPermissions = await _checkAndRequestPermissions();
    if (!hasPermissions) {
      return;
    }

    // Verificar disponibilidad de Bluetooth
    if (!(await _beaconService.isBluetoothAvailable())) {
      _showSnackBar(
        'Bluetooth no está disponible o está apagado. Por favor actívalo e intenta de nuevo.',
      );
      return;
    }

    // Actualizar estado de escaneo
    setState(() {
      _isScanning = true;
      _scanResults = [];
    });

    // Mostrar diálogo de progreso de búsqueda
    await _showScanningDialog();

    // Variable para controlar si debemos cerrar el diálogo
    bool shouldCloseDialog = true;

    try {
      // Configurar el servicio para detección óptima de beacons
      _beaconService.configure(
        BeaconScanConfig(
          scanDuration: _scanTimeout.inMilliseconds,
          rssiThreshold:
              -90, // Aceptar señales más débiles para mostrar más opciones
          debugMode: true, // Activar logs para diagnóstico
        ),
      );

      // Usar el servicio para escanear
      final results = await _beaconService.scanOnce(timeout: _scanTimeout);

      // Cerrar el diálogo de búsqueda
      if (shouldCloseDialog) {
        _dismissScanningDialog();
        shouldCloseDialog = false;
      }

      // Actualizar estado
      setState(() {
        _isScanning = false;
        _scanResults = results;
      });

      // Verificar si se encontraron dispositivos
      if (results.isEmpty) {
        _showSnackBar(
          'No se encontró ningún dispositivo Bluetooth.',
          backgroundColor: Colors.orange,
        );
        return;
      }

      // Mostrar diálogo de selección de beacon
      await _showBeaconSelectionDialog(results);
    } catch (e) {
      // Cerrar el diálogo si hay un error
      if (shouldCloseDialog) {
        _dismissScanningDialog();
      }

      _showSnackBar(
        'Error al escanear dispositivos Bluetooth.',
        debugMessage: 'Error al escanear dispositivos: $e',
      );
    } finally {
      // Asegurar que el estado de escaneo se restablezca
      setState(() {
        _isScanning = false;
      });
    }
  }

  // A helper method to show the confirmation dialog for beacon disassociation.
  Future<bool> _showDisassociateBeaconConfirmation() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Desasociar beacon',
      content: const Text(
        '¿Estás seguro que deseas desasociar el beacon de tu vehículo?',
      ),
      confirmText: 'Desasociar',
      destructive: true,
    );
    return confirmed ?? false;
  }

  // Método para confirmar la desasociación del beacon
  Future<void> _confirmDisassociateBeacon() async {
    final confirmed = await _showDisassociateBeaconConfirmation();
    if (confirmed) {
      _backgroundService.invoke(BackgroundServiceCommands.dissociateBeacon);
    }
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Tarjeta de estrategia activa
          ActiveStrategyCard(activeStrategyName: _activeStrategyName),
          const SizedBox(height: 16.0),
          // Tarjeta de configuración de beacon
          BeaconConfigCard(
            selectedBeaconId: _selectedBeaconId,
            deviceName: _deviceName,
            isScanning: _isScanning,
            onScan: _startBeaconScan,
            onDisassociate: _confirmDisassociateBeacon,
          ),

          // Si hay resultados de escaneo recientes, mostrarlos
          if (_scanResults.isNotEmpty && !_isScanning) ...[
            const SizedBox(height: 16.0),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dispositivos encontrados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Toca para asociar con tu vehículo:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _scanResults.length.clamp(
                        0,
                        5,
                      ), // Mostrar máximo 5
                      itemBuilder: (context, index) {
                        final device = _scanResults[index];
                        final deviceName = BeaconService.describeDevice(device);
                        return ListTile(
                          title: Text(deviceName),
                          subtitle: Text('RSSI: ${device.rssi} dBm'),
                          leading: const Icon(Icons.bluetooth),
                          onTap: () {
                            final deviceId = device.device.remoteId.toString();
                            final rssi = device.rssi;
                            _confirmAssociateBeacon(deviceName, deviceId, rssi);
                          },
                        );
                      },
                    ),
                    if (_scanResults.length > 5) ...[
                      TextButton(
                        onPressed:
                            () => _showBeaconSelectionDialog(_scanResults),
                        child: const Text('Ver todos los dispositivos'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
