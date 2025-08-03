import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:where_is_it/domain/repositories/beacon_repository.dart';
import 'package:where_is_it/screens/map_screen.dart';
import 'package:where_is_it/configuration/map_config.dart';
import 'package:provider/provider.dart';
import 'package:where_is_it/application/services/location_service.dart';
import 'package:where_is_it/application/services/beacon_service.dart';
import 'package:where_is_it/application/services/permission_service.dart';
import 'package:where_is_it/infrastructure/repositories/location_repository_impl.dart';
import 'package:where_is_it/infrastructure/repositories/beacon_repository_impl.dart';
import 'package:where_is_it/screens/map_view_model.dart';
import 'package:where_is_it/services/background_service/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar la configuración del mapa para web y otras plataformas
  await MapConfig.initialize();

  if (!kIsWeb) {
    await _validateAndRequestPermissions();
  }

  if (!kIsWeb) {
    await setupChannel();
    await initializeBackgroundService();
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<LocationService>(
          create: (_) => LocationService(LocationRepositoryImpl()),
        ),
        Provider<BeaconService>(
          create: (_) => BeaconService(BeaconRepositoryImpl()),
        ),
        Provider<PermissionService>(create: (_) => PermissionService()),
        Provider<BeaconRepository>(create: (_) => BeaconRepositoryImpl()),
        ChangeNotifierProvider<MapViewModel>(
          create:
              (context) => MapViewModel(
                locationService: context.read<LocationService>(),
                permissionService: context.read<PermissionService>(),
              )..loadInitialData(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// Valida y solicita los permisos necesarios para el funcionamiento de la aplicación
Future<void> _validateAndRequestPermissions() async {
  final permissionService = PermissionService();

  // Location when in use
  if (!await permissionService.checkLocationPermission()) {
    if (!await permissionService.requestLocationPermission()) {
      // No se concedió el permiso, cerrar la aplicación
      return;
    }
  }

  // Activity Recognition (Android 10+)
  if (!await permissionService.checkActivityRecognitionPermission()) {
    if (!await permissionService.requestActivityRecognitionPermission()) {
      return;
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Textos para internacionalización
  static const String _appTitle = 'Where Is It';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}
