import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../domain/repositories/beacon_repository.dart';

/// Evento emitido cuando se detecta un beacon
class BeaconDetectionEvent {
  final String deviceId;
  final int rssi;
  final double distance;
  final DateTime timestamp;
  final Map<String, dynamic> additionalData;

  BeaconDetectionEvent({
    required this.deviceId,
    required this.rssi,
    required this.distance,
    required this.timestamp,
    this.additionalData = const {},
  });
}

/// Resultado del escaneo de beacons
class BeaconScanResult {
  final List<ScanResult> allDevices;
  final List<ScanResult> detectedBeacons;
  final DateTime timestamp;

  BeaconScanResult({
    required this.allDevices,
    required this.detectedBeacons,
    required this.timestamp,
  });
}

/// Configuración para el escaneo de beacons
class BeaconScanConfig {
  /// Intervalo entre escaneos en milisegundos
  final int scanInterval;

  /// Duración de cada escaneo en milisegundos
  final int scanDuration;

  /// UUIDs para filtrar el escaneo (opcional)
  final List<Guid>? serviceUuids;

  /// Umbral RSSI mínimo para considerar una detección válida
  final int rssiThreshold;

  /// Potencia de transmisión estimada a 1 metro (para cálculo de distancia)
  final int txPower;

  /// Tamaño máximo del historial RSSI para cálculos de suavizado
  final int maxRssiHistorySize;

  /// Modo de diagnóstico para loggear todos los dispositivos
  final bool debugMode;

  BeaconScanConfig({
    this.scanInterval = 5000,
    this.scanDuration = 10000,
    this.serviceUuids,
    this.rssiThreshold = -90,
    this.txPower = -59,
    this.maxRssiHistorySize = 10,
    this.debugMode = false,
  });
}

/// Servicio responsable de manejar operaciones relacionadas con Beacons Bluetooth
class BeaconService {
  final BeaconRepository _beaconRepository;

  // Control del escaneo
  StreamSubscription? _scanSubscription;
  Timer? _scanTimer;
  bool _isScanning = false;

  // Configuración
  BeaconScanConfig _config = BeaconScanConfig();
  BeaconScanConfig get config => _config;

  // Streams para notificar eventos
  final _beaconDetectionController =
      StreamController<BeaconDetectionEvent>.broadcast();
  final _scanResultController = StreamController<BeaconScanResult>.broadcast();

  // Historial RSSI para dispositivos detectados
  final Map<String, List<int>> _rssiHistory = {};

  // Stream con eventos de detección de beacons
  Stream<BeaconDetectionEvent> get onBeaconDetected =>
      _beaconDetectionController.stream;

  // Stream con resultados de cada escaneo
  Stream<BeaconScanResult> get onScanResults => _scanResultController.stream;

  BeaconService(this._beaconRepository);

  /// Asocia un nuevo Beacon al vehículo
  Future<void> associateBeacon(
    String beaconId, {
    Map<String, dynamic>? fingerprint,
  }) async {
    try {
      developer.log('Asociando Beacon con ID: $beaconId');
      await _beaconRepository.saveBeaconId(beaconId);
      if (fingerprint != null) {
        await _beaconRepository.saveBeaconFingerprint(fingerprint);
        developer.log('Fingerprint guardado: \\${fingerprint.toString()}');
      }
      developer.log('Beacon asociado correctamente');
    } catch (e) {
      developer.log('Error al asociar Beacon: $e', error: e);
      throw Exception('Error al asociar el Beacon: $e');
    }
  }

  /// Obtiene el ID del Beacon asociado al vehículo
  Future<String?> getAssociatedBeaconId() async {
    try {
      final beaconId = await _beaconRepository.loadBeaconId();

      // Tratar string vacío como null
      if (beaconId == null || beaconId.isEmpty) {
        developer.log('No hay Beacon asociado');
        return null;
      }

      developer.log('Beacon ID cargado: $beaconId');
      return beaconId;
    } catch (e) {
      developer.log('Error al cargar Beacon ID: $e', error: e);
      throw Exception('Error al obtener el ID del Beacon: $e');
    }
  }

  /// Elimina la asociación con el Beacon actual
  Future<void> dissociateBeacon() async {
    try {
      // Guarda un string vacío para eliminar la asociación
      await _beaconRepository.saveBeaconId('');
      developer.log('Beacon desasociado correctamente');
    } catch (e) {
      developer.log('Error al desasociar Beacon: $e', error: e);
      throw Exception('Error al desasociar el Beacon: $e');
    }
  }

  /// Verifica si el bluetooth está disponible y activado
  Future<bool> isBluetoothAvailable() async {
    try {
      // Verificar si el Bluetooth está disponible en el dispositivo
      if (!(await FlutterBluePlus.isSupported)) {
        developer.log('Bluetooth no disponible en el dispositivo');
        return false;
      }

      // Verificar si el Bluetooth está encendido
      if (!((await FlutterBluePlus.adapterState.first) ==
          BluetoothAdapterState.on)) {
        developer.log('Bluetooth apagado');
        return false;
      }

      return true;
    } catch (e) {
      developer.log(
        'Error al verificar disponibilidad de Bluetooth: $e',
        error: e,
      );
      return false;
    }
  }

  /// Configura el servicio de escaneo de beacons
  void configure(BeaconScanConfig config) {
    _config = config;
  }

  /// Inicia el escaneo periódico de beacons
  Future<bool> startPeriodicScan() async {
    if (!(await isBluetoothAvailable())) {
      return false;
    }

    try {
      // Realizar primer escaneo inmediatamente
      await _startScan();

      // Configurar timer para escaneos periódicos
      _scanTimer = Timer.periodic(
        Duration(milliseconds: _config.scanInterval),
        (_) {
          _startScan();
        },
      );

      return true;
    } catch (e) {
      developer.log('Error al iniciar escaneo periódico: $e', error: e);
      return false;
    }
  }

  /// Detiene el escaneo periódico de beacons
  void stopPeriodicScan() {
    _scanSubscription?.cancel();
    _scanTimer?.cancel();
    _stopScan();

    developer.log('Escaneo periódico de beacons detenido');
  }

  /// Realiza un único escaneo de beacons
  Future<List<ScanResult>> scanOnce({Duration? timeout}) async {
    if (!(await isBluetoothAvailable())) {
      return [];
    }

    final results = <ScanResult>[];
    final completer = Completer<List<ScanResult>>();

    try {
      // Detener escaneos previos
      await FlutterBluePlus.stopScan();

      // Configurar escucha temporal
      final subscription = FlutterBluePlus.scanResults.listen(
        (devices) {
          results.clear();
          results.addAll(devices);
        },
        onError: (e) {
          developer.log('Error durante escaneo único: $e', error: e);
          if (!completer.isCompleted) {
            completer.complete(results);
          }
        },
      );

      // Iniciar escaneo
      await FlutterBluePlus.startScan(
        timeout: timeout ?? Duration(milliseconds: _config.scanDuration),
        withServices: _config.serviceUuids != null ? _config.serviceUuids! : [],
      );

      // Esperar a que termine
      await FlutterBluePlus.isScanning.where((val) => val == false).first;

      // Limpiar
      subscription.cancel();

      if (!completer.isCompleted) {
        completer.complete(results);
      }

      return results;
    } catch (e) {
      developer.log('Error en scanOnce: $e', error: e);
      if (!completer.isCompleted) {
        completer.complete(results);
      }
      return results;
    }
  }

  /// Inicia un escaneo de dispositivos Bluetooth cercanos
  Future<void> _startScan() async {
    if (_isScanning) return;

    try {
      _isScanning = true;

      // Detener escaneos previos
      await FlutterBluePlus.stopScan();

      // Acumular resultados durante el escaneo
      final List<ScanResult> allResults = [];
      final subscription = FlutterBluePlus.scanResults.listen(
        (results) {
          allResults.clear();
          allResults.addAll(results);
        },
        onError: (e) {
          developer.log('Error durante el escaneo de beacons: $e', error: e);
        },
      );

      // Iniciar escaneo con la configuración actual
      await FlutterBluePlus.startScan(
        withServices: _config.serviceUuids != null ? _config.serviceUuids! : [],
        timeout: Duration(milliseconds: _config.scanDuration),
      );

      developer.log(
        "Escaneo de beacons iniciado, duración: \\${_config.scanDuration}ms",
      );

      // Esperar a que termine el escaneo
      await FlutterBluePlus.isScanning.where((val) => val == false).first;

      // Procesar solo una vez al final
      developer.log(
        'Resultado de escaneo emitido a las: \\${DateTime.now().toIso8601String()} con \\${allResults.length} dispositivos',
        name: 'BeaconService',
      );
      _scanResultController.add(
        BeaconScanResult(
          allDevices: allResults,
          detectedBeacons: allResults,
          timestamp: DateTime.now(),
        ),
      );
      for (ScanResult result in allResults) {
        _processBeaconResult(result);
      }

      await subscription.cancel();
    } catch (e) {
      developer.log('Error al iniciar escaneo de beacons: $e', error: e);
    } finally {
      _isScanning = false;
    }
  }

  /// Detiene el escaneo actual
  Future<void> _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      developer.log('Error al detener escaneo: $e', error: e);
    }
  }

  /// Procesa el resultado del escaneo de un dispositivo
  void _processBeaconResult(ScanResult result) {
    // Actualizar historial de RSSI
    final deviceId = result.device.remoteId.toString();
    _rssiHistory.putIfAbsent(deviceId, () => []);

    _rssiHistory[deviceId]!.add(result.rssi);
    if (_rssiHistory[deviceId]!.length > _config.maxRssiHistorySize) {
      _rssiHistory[deviceId]!.removeAt(0);
    }

    // Usar TX Power del anuncio si está disponible
    int txPower = _config.txPower;
    if (result.advertisementData.txPowerLevel != null) {
      txPower = result.advertisementData.txPowerLevel!;
    }

    // Calcular distancia aproximada basada en RSSI
    final double distance = _calculateDistance(
      result.rssi,
      txPower,
      _rssiHistory[deviceId]!,
    );

    // Emitir evento de detección
    final event = BeaconDetectionEvent(
      deviceId: deviceId,
      rssi: result.rssi,
      distance: distance,
      timestamp: DateTime.now(),
      additionalData: {
        'name': result.device.platformName,
        'isConnectable': result.advertisementData.connectable,
        'serviceUuids':
            result.advertisementData.serviceUuids
                .map((u) => u.toString())
                .toList(),
        'manufacturerData': result.advertisementData.manufacturerData,
        'rssiHistory': _rssiHistory[deviceId]!.toList(),
      },
    );

    _beaconDetectionController.add(event);
  }

  /// Verifica si un dispositivo parece ser un beacon basado en sus características
  bool _looksLikeBeacon(ScanResult result) {
    // Si el RSSI está por debajo del umbral, no considerarlo
    if (result.rssi < _config.rssiThreshold) {
      return false;
    }

    // Verificar nombre común de beacons
    final deviceName = result.device.platformName.toLowerCase();
    final commonBeaconNames = [
      'beacon',
      'ibeacon',
      'eddystone',
      'altbeacon',
      'kontakt',
      'estimote',
      'radius',
      'taggy',
      'tile',
      'finder',
    ];

    if (commonBeaconNames.any((name) => deviceName.contains(name))) {
      return true;
    }

    // Verificar manufacturer data para patrones de beacon
    if (result.advertisementData.manufacturerData.isNotEmpty) {
      // iBeacon: Apple (0x004C) en los primeros bytes
      if (result.advertisementData.manufacturerData.containsKey(0x004C)) {
        return true;
      }

      // Otros fabricantes comunes de beacons
      final commonManufacturerIds = [
        0x0059, // Nordic
        0x0157, // Estimote
        0x004C, // Apple
      ];

      if (result.advertisementData.manufacturerData.keys.any(
        (id) => commonManufacturerIds.contains(id),
      )) {
        return true;
      }
    }

    // Verificar service UUIDs
    final serviceUuids = result.advertisementData.serviceUuids;
    if (serviceUuids.isNotEmpty) {
      final beaconUuids = [
        "0000FEAA-0000-1000-8000-00805F9B34FB", // Eddystone
        "D0D0000A-0000-1000-8000-00805F9B0131", // AltBeacon
      ];

      if (serviceUuids.any((uuid) => beaconUuids.contains(uuid.toString()))) {
        return true;
      }
    }

    return false;
  }

  /// Algoritmo para calcular distancia aproximada basada en RSSI
  double _calculateDistance(int rssi, int txPower, List<int> rssiHistory) {
    if (rssi == 0) return -1.0; // No válido

    // Usar un factor de pérdida de señal basado en el entorno
    // 2.0 para espacio libre, 2.5-3.0 para interiores, 3.5-4.0 para edificios complejos
    const double n = 2.7;

    // Modelo logarítmico
    final double ratio = (txPower - rssi) / (10 * n);
    double distance = math.pow(10, ratio).toDouble();

    // Aplicar corrección basada en la historia de RSSI para evitar fluctuaciones
    if (rssiHistory.length > 3) {
      int avgRssi = rssiHistory.reduce((a, b) => a + b) ~/ rssiHistory.length;
      double avgDistance =
          math.pow(10, (txPower - avgRssi) / (10 * n)).toDouble();

      // Combinar distancia actual con promedio histórico para estabilidad
      distance = (distance * 0.3) + (avgDistance * 0.7);
    }

    return distance;
  }

  /// Cierra los recursos del servicio
  void dispose() {
    stopPeriodicScan();
    _beaconDetectionController.close();
    _scanResultController.close();
  }

  /// Devuelve una descripción amigable del dispositivo BLE
  static String describeDevice(ScanResult device) {
    // 1. Nombre del dispositivo si existe
    if (device.device.platformName.isNotEmpty) {
      return device.device.platformName;
    }

    // 2. Manufacturer data
    if (device.advertisementData.manufacturerData.isNotEmpty) {
      final mfrIds = device.advertisementData.manufacturerData.keys;
      if (mfrIds.contains(0x004C)) return 'iBeacon (Apple)';
      if (mfrIds.contains(0x0157)) return 'Estimote Beacon';
      if (mfrIds.contains(0x0059)) return 'Nordic Beacon';
      if (mfrIds.contains(0x0075)) return 'Samsung SmartTag';
      return 'Fabricante: 0x${mfrIds.first.toRadixString(16).toUpperCase()}';
    }

    // 3. UUIDs de servicios
    if (device.advertisementData.serviceUuids.isNotEmpty) {
      final uuid =
          device.advertisementData.serviceUuids.first.toString().toLowerCase();
      if (uuid.contains('feaa')) return 'Eddystone Beacon';
      if (uuid.contains('fd6f')) return 'Tile Tracker';
      // Agrega más UUIDs conocidos aquí
      return 'Servicio: $uuid';
    }

    // 4. Fallback
    return 'Desconocido';
  }

  /// Obtiene el fingerprint del Beacon asociado al vehículo
  Future<Map<String, dynamic>?> getAssociatedBeaconFingerprint() async {
    try {
      final fingerprint = await _beaconRepository.loadBeaconFingerprint();
      if (fingerprint == null) {
        developer.log('No hay fingerprint de Beacon asociado');
        return null;
      }
      developer.log('Fingerprint cargado: \\${fingerprint.toString()}');
      return fingerprint;
    } catch (e) {
      developer.log('Error al cargar fingerprint: $e', error: e);
      throw Exception('Error al obtener el fingerprint del Beacon: $e');
    }
  }
}
