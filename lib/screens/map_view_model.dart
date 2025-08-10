import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../application/services/location_service.dart';
import '../infrastructure/repositories/location_repository_impl.dart';
import '../application/services/permission_service.dart';
import 'dart:async';
import '../application/models/car_exit_state.dart';
import '../utils/logger.dart';
import 'package:parking_detector_plugin/parking_detector_plugin.dart';

// MapViewModel actúa como puente entre la UI y la capa de datos,
// gestionando el estado y la lógica de negocio para la pantalla del mapa.
class MapViewModel extends ChangeNotifier {
  // Servicios
  final LocationService _locationService;
  final PermissionService _permissionService;
  // Eliminado uso de FlutterBackgroundService; manejamos eventos directo del plugin

  // Estado de ubicación
  LatLng? _currentLocation;
  LatLng? _savedLocation;

  // Estado del detector
  CarExitState _detectorState = CarExitState.unknown;

  // Estado de la UI
  bool _isLoading = true;
  bool _isDetectorRunning = false;
  // Polling deshabilitado temporalmente para validar mensajería directa
  Timer? _statePoller;

  // Solo polling para estado actual
  StreamSubscription<dynamic>?
  _pluginSubscription; // (no usado cuando hay solo polling)

  MapViewModel({
    LocationService? locationService,
    PermissionService? permissionService,
  }) : _locationService =
           locationService ?? LocationService(LocationRepositoryImpl()),
       _permissionService = permissionService ?? PermissionService();

  // Mensajería directa deshabilitada; usamos solo polling
  Future<void> _pollCurrentStateOnce() async {
    try {
      final native = await ParkingDetectorPlugin.getCurrentState();
      final mapped = _mapNativeStateToCarExitState(native);
      if (_detectorState != mapped) {
        _detectorState = mapped;
        Logger.logMapViewModel('Estado (poll) actualizado: $_detectorState');
        if (mapped == CarExitState.exited) {
          await _handleCarExitDetected();
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  CarExitState _mapNativeStateToCarExitState(String nativeState) {
    switch (nativeState) {
      case 'DRIVING':
        return CarExitState.driving;
      case 'TENTATIVE_PARKED':
        return CarExitState.stopped;
      case 'CONFIRMED_PARKED':
        return CarExitState.exited;
      case 'UNKNOWN':
      default:
        return CarExitState.unknown;
    }
  }

  LatLng? get currentLocation => _currentLocation;
  LatLng? get savedLocation => _savedLocation;
  CarExitState get detectorState => _detectorState;
  bool get isLoading => _isLoading;
  // Eliminado: ya no se usa estrategia

  // Estado de ejecución del detector
  bool get isDetectorRunning => _isDetectorRunning;

  Future<void> _loadSavedLocation() async {
    try {
      _savedLocation = await _locationService.loadLastSavedLocation();
    } catch (e) {
      Logger.logMapViewModelError('Error cargando ubicación guardada', e);
    }
  }

  Future<void> _loadCurrentLocation() async {
    try {
      Logger.logMapViewModel('Intentando cargar ubicación actual...');
      _currentLocation = await _locationService.getCurrentLocation();
      Logger.logMapViewModel('Ubicación actual cargada: $_currentLocation');
    } catch (e) {
      Logger.logMapViewModelError('Error cargando ubicación actual', e);
      // Usar ubicación por defecto si no se puede obtener la actual
      _currentLocation = const LatLng(
        19.4326,
        -99.1332,
      ); // Ciudad de México por defecto
      Logger.logMapViewModel('Usando ubicación por defecto: $_currentLocation');
    }
  }

  Future<bool> _ensurePermissionsGranted() async {
    try {
      Logger.logMapViewModel('Verificando permisos de ubicación...');

      // En Android, los permisos los maneja el servicio nativo
      // Aquí solo verificamos que estén disponibles
      bool hasPermission = true;

      if (kIsWeb) {
        hasPermission = await _permissionService.checkLocationPermission();
        if (!hasPermission) {
          hasPermission = await _permissionService.requestLocationPermission();
        }
      }

      Logger.logMapViewModel('Permisos de ubicación: $hasPermission');
      return hasPermission;
    } catch (e) {
      Logger.logMapViewModelError('Error verificando permisos', e);
      return true; // Asumir que están disponibles en Android
    }
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    try {
      Logger.logMapViewModel('Iniciando carga de datos iniciales...');
      final hasPermissions = await _ensurePermissionsGranted();
      if (!hasPermissions) {
        Logger.logMapViewModel(
          'Sin permisos de ubicación, usando datos limitados',
        );
      }
      await Future.wait([_loadSavedLocation(), _loadCurrentLocation()]);

      Logger.logMapViewModel('Carga de datos iniciales completada');
    } catch (e) {
      Logger.logMapViewModelError('Error cargando datos iniciales', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startDetector() async {
    try {
      await ParkingDetectorPlugin.startParkingDetection();
      Logger.logMapViewModel('Detector nativo iniciado');
      _isDetectorRunning = true;
      // Iniciar polling del estado
      await _pollCurrentStateOnce();
      _statePoller?.cancel();
      _statePoller = Timer.periodic(const Duration(seconds: 2), (_) {
        _pollCurrentStateOnce();
      });
      notifyListeners();
    } catch (e) {
      Logger.logMapViewModelError('Error iniciando detector', e);
    }
  }

  Future<void> stopDetector() async {
    try {
      await ParkingDetectorPlugin.stopParkingDetection();
      Logger.logMapViewModel('Detector nativo detenido');
      _isDetectorRunning = false;
      _statePoller?.cancel();
      _statePoller = null;
      notifyListeners();
    } catch (e) {
      Logger.logMapViewModelError('Error deteniendo detector', e);
    }
  }

  Future<void> _handleCarExitDetected() async {
    try {
      final current = await _locationService.getCurrentLocation();
      _savedLocation = current;
      await _locationService.saveLocation(current);
      Logger.logMapViewModel(
        'Ubicación de estacionamiento guardada: $_savedLocation',
      );
      notifyListeners();
    } catch (e) {
      Logger.logMapViewModelError('Error guardando ubicación de salida', e);
    }
  }

  @override
  void dispose() {
    _pluginSubscription?.cancel();
    _statePoller?.cancel();
    super.dispose();
  }
}
