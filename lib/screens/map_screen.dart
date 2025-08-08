import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/detector_status_indicator.dart';
import '../widgets/strategy_indicator.dart';
import '../widgets/map_view.dart';
// import '../widgets/native_detector_debug_panel.dart';
import 'settings_screen.dart';
import 'map_view_model.dart';
import '../domain/repositories/beacon_repository.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    final model = Provider.of<MapViewModel>(context);
    return _buildScaffold(context, model);
  }

  Widget _buildScaffold(BuildContext context, MapViewModel model) {
    return Scaffold(
      appBar: _buildAppBar(context, model),
      body: _buildBody(context, model),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPlayStopButton(context, model),
          const SizedBox(height: 12),
          _buildLocationButton(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, MapViewModel model) {
    return AppBar(
      title: const Text('Where Is It'),
      backgroundColor: Colors.blue,
      actions: _buildAppBarActions(context, model),
    );
  }

  Widget _buildBody(BuildContext context, MapViewModel model) {
    if (model.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        MapView(
          currentLocation: model.currentLocation,
          savedLocation: model.savedLocation,
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: StrategyIndicator(strategyName: model.activeStrategyName),
        ),
        // const NativeDetectorDebugPanel(),
      ],
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context, MapViewModel model) {
    return [
      DetectorStatusIndicatorWidget(state: model.detectorState),
      IconButton(
        icon: const Icon(Icons.settings),
        tooltip: 'Configuración',
        onPressed: () => _navigateToSettings(context),
      ),
    ];
  }

  Widget _buildLocationButton(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'btn1',
      child: const Icon(Icons.my_location),
      onPressed: () async {
        final model = Provider.of<MapViewModel>(context, listen: false);
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        try {
          await model.loadInitialData();
        } catch (e) {
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Error al obtener la ubicación: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  Widget _buildPlayStopButton(BuildContext context, MapViewModel model) {
    final isRunning = model.isDetectorRunning;
    return FloatingActionButton(
      heroTag: 'btnPlayStop',
      // Mostrar estado "stop" al inicio (no corriendo) y cambiar al activarse
      backgroundColor: isRunning ? Colors.green : Colors.red,
      tooltip: isRunning ? 'Detener monitoreo' : 'Iniciar monitoreo',
      onPressed: () async {
        if (isRunning) {
          await model.stopDetector();
        } else {
          await model.startDetector();
        }
      },
      // Icono invertido: al inicio (no corriendo) mostrar stop
      child: Icon(isRunning ? Icons.play_arrow : Icons.stop),
    );
  }

  void _navigateToSettings(BuildContext context) async {
    final viewModel = Provider.of<MapViewModel>(context, listen: false);
    // Obtener el repositorio de beacon del Provider
    final beaconRepository = Provider.of<BeaconRepository>(
      context,
      listen: false,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SettingsScreen(beaconRepository: beaconRepository),
      ),
    );

    if (mounted) {
      await viewModel.loadInitialData();
    }
  }
}
