import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../application/services/location_service.dart';
import '../infrastructure/repositories/location_repository_impl.dart';
import '../application/services/permission_service.dart';
import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../application/services/car_exit_strategy/car_exit_state.dart';
import '../services/background_service/background_service_events.dart';
import '../services/background_service/background_service_protocol.dart';
import '../utils/logger.dart';

// MapViewModel actúa como puente entre la UI y la capa de datos,
// gestionando el estado y la lógica de negocio para la pantalla del mapa.
class MapViewModel extends ChangeNotifier {
  // Servicios
  final LocationService _locationService;
  final PermissionService _permissionService;
  final FlutterBackgroundService _backgroundService =
      FlutterBackgroundService();

  // Estado de ubicación
  LatLng? _currentLocation;
  LatLng? _savedLocation;

  // Estado del detector
  CarExitState _detectorState = CarExitState.unknown;

  // Estado de la UI
  bool _isLoading = true;
  bool _isDetectorRunning = false;

  // Suscripción a eventos del servicio
  StreamSubscription<Map<String, dynamic>?>? _serviceSubscription;

  MapViewModel({
    LocationService? locationService,
    PermissionService? permissionService,
  }) : _locationService =
           locationService ?? LocationService(LocationRepositoryImpl()),
       _permissionService = permissionService ?? PermissionService() {
    _listenToServiceEvents();
  }

  void _listenToServiceEvents() {
    _serviceSubscription = _backgroundService
        .on(BackgroundServiceEvents.onStateChanged)
        .listen((event) {
          if (event != null) {
            // Validar payload esperado { newState, oldState }
            final hasNewState =
                event.containsKey('newState') && event['newState'] is String;
            final hasOldState =
                event.containsKey('oldState') && event['oldState'] is String;
            if (!hasNewState || !hasOldState) {
              // Ignorar eventos malformados (p.ej., actividad cruda)
              return;
            }

            final stateEvent = CarExitStateChangedEvent.fromJson(event);
            final newState = CarExitState.values.firstWhere(
              (state) => state.toString() == stateEvent.newState,
              orElse: () => CarExitState.unknown,
            );

            if (_detectorState != newState) {
              _detectorState = newState;
              Logger.logMapViewModel(
                'Estado del detector actualizado: $_detectorState',
              );
              notifyListeners();
            }
          }
        });

    _backgroundService.on(BackgroundServiceEvents.onCarExit).listen((event) {
      if (event != null) {
        final exitEvent = CarExitDetectedEvent.fromJson(event);
        _savedLocation = LatLng(exitEvent.latitude, exitEvent.longitude);
        Logger.logMapViewModel(
          'Ubicación de estacionamiento guardada: $_savedLocation',
        );
        notifyListeners();
      }
    });
  }

  LatLng? get currentLocation => _currentLocation;
  LatLng? get savedLocation => _savedLocation;
  CarExitState get detectorState => _detectorState;
  bool get isLoading => _isLoading;
  String get activeStrategyName => 'Detección Nativa';

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

      // Solicitar estado actual del servicio
      _backgroundService.invoke(BackgroundServiceCommands.getCurrentState);

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
      _backgroundService.invoke(BackgroundServiceCommands.startDetector);
      Logger.logMapViewModel('Solicitud de inicio de detector enviada');
      _isDetectorRunning = true;
      notifyListeners();
    } catch (e) {
      Logger.logMapViewModelError('Error iniciando detector', e);
    }
  }

  Future<void> stopDetector() async {
    try {
      _backgroundService.invoke(BackgroundServiceCommands.stopDetector);
      Logger.logMapViewModel('Solicitud de detención de detector enviada');
      _isDetectorRunning = false;
      notifyListeners();
    } catch (e) {
      Logger.logMapViewModelError('Error deteniendo detector', e);
    }
  }

  @override
  void dispose() {
    _serviceSubscription?.cancel();
    super.dispose();
  }
}
