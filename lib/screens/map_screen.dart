import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/detector_status_indicator.dart';
import '../widgets/map_view.dart';
// import '../widgets/native_detector_debug_panel.dart';
import 'settings_screen.dart';
import 'map_view_model.dart';

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
          right: 16,
          bottom: 16,
          child: _buildMonitoringControl(context, model),
        ),
      ],
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context, MapViewModel model) {
    return [
      if (model.isDetectorRunning)
        DetectorStatusIndicatorWidget(state: model.detectorState),
      IconButton(
        icon: const Icon(Icons.settings),
        tooltip: 'Configuración',
        onPressed: () => _navigateToSettings(context),
      ),
    ];
  }

  Widget _buildMonitoringControl(BuildContext context, MapViewModel model) {
    final isRunning = model.isDetectorRunning;
    final theme = Theme.of(context);
    final bg =
        isRunning
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceVariant;
    final fg = isRunning ? Colors.white : theme.colorScheme.onSurfaceVariant;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              isRunning ? Icons.play_circle_fill : Icons.pause_circle_filled,
              color: fg,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Monitoreo',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isRunning ? 'Detectando' : 'Sin monitoreo',
                    style: theme.textTheme.bodySmall?.copyWith(color: fg),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: isRunning,
              activeColor: Colors.white,
              activeTrackColor: Colors.white.withOpacity(0.6),
              onChanged: (v) async {
                // Haptic feedback sutil
                HapticFeedback.lightImpact();
                if (v) {
                  await model.startDetector();
                } else {
                  await model.stopDetector();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) async {
    final viewModel = Provider.of<MapViewModel>(context, listen: false);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );

    if (mounted) {
      await viewModel.loadInitialData();
    }
  }
}
