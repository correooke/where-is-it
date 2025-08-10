import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:parking_detector_plugin/parking_detector_plugin.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:convert';
import 'package:where_is_it/services/background_service/background_service_events.dart';
// Imports eliminados de estrategia y typed listeners

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FlutterBackgroundService _backgroundService =
      FlutterBackgroundService();
  // Eliminado indicador de estrategia
  final List<StreamSubscription> _subscriptions = [];

  // Debug-only state
  String _currentDetectorState = 'unknown';
  final List<String> _rawEvents = <String>[]; // newest first
  bool _captureEnabled = true;

  @override
  void initState() {
    super.initState();
    // Sin estrategia

    if (kDebugMode) {
      _subscriptions.add(_listenRaw(BackgroundServiceEvents.onStateChanged));
      // Eliminado onStrategyChanged (no usado)
      _subscriptions.add(_listenRaw(BackgroundServiceEvents.onCarExit));
      _subscriptions.add(_listenRaw(BackgroundServiceEvents.onActivityUpdate));
      _subscriptions.add(_listenCurrentStateResponses());
      _subscriptions.add(_listenLogs());
      // Escucha directa al canal del plugin (diagnóstico)
      _subscriptions.add(
        ParkingDetectorPlugin.parkingEvents.listen((event) {
          if (!kDebugMode || !_captureEnabled || !mounted) return;
          setState(() {
            _rawEvents.insert(0, _formatEvent('plugin.parking_events', event));
            if (_rawEvents.length > 100) _rawEvents.removeLast();
            // Actualizar también el estado actual mostrado en el panel
            if (event is Map && event.containsKey('state')) {
              final dynamic stateVal = event['state'];
              _currentDetectorState = _mapNativeStateToDisplay(
                stateVal?.toString(),
              );
            }
          });
        }),
      );
      // Solicitar estado actual al abrir
      _backgroundService.invoke(BackgroundServiceCommands.getCurrentState);
    }
  }

  // Escucha genérica para eventos crudos y actualiza panel de debug
  StreamSubscription _listenRaw(String eventName) {
    return _backgroundService.on(eventName).listen((event) {
      if (!kDebugMode) return;
      if (!_captureEnabled) return;
      if (!mounted) return;
      setState(() {
        final formatted = _formatEvent(eventName, event);
        _rawEvents.insert(0, formatted);
        if (_rawEvents.length > 100) {
          _rawEvents.removeLast();
        }
        // Intentar actualizar estado si viene en el payload
        if (event is Map && (event as Map).containsKey('newState')) {
          final map = event as Map;
          final dynamic stateVal = map['newState'];
          _currentDetectorState = stateVal?.toString() ?? _currentDetectorState;
        }
      });
    });
  }

  // Escucha respuestas de getCurrentState
  StreamSubscription _listenCurrentStateResponses() {
    // La respuesta llega en el mismo nombre de evento que el comando
    return _backgroundService
        .on(BackgroundServiceCommands.getCurrentState)
        .listen((event) {
          if (!kDebugMode) return;
          if (!_captureEnabled) return;
          if (!mounted) return;
          setState(() {
            _rawEvents.insert(
              0,
              _formatEvent(BackgroundServiceCommands.getCurrentState, event),
            );
            if (event is Map && (event as Map).containsKey('stateName')) {
              final map = event as Map;
              final dynamic stateVal = map['stateName'];
              _currentDetectorState =
                  stateVal?.toString() ?? _currentDetectorState;
            }
          });
        });
  }

  StreamSubscription _listenLogs() {
    return _backgroundService.on(BackgroundServiceEvents.onLog).listen((event) {
      if (!kDebugMode) return;
      if (!_captureEnabled) return;
      if (!mounted) return;
      setState(() {
        String msg;
        if (event is Map && (event as Map).containsKey('message')) {
          final map = event as Map;
          msg = map['message']?.toString() ?? event.toString();
        } else {
          msg = event.toString();
        }
        _rawEvents.insert(
          0,
          _formatEvent(BackgroundServiceEvents.onLog, {'message': msg}),
        );
        if (_rawEvents.length > 100) {
          _rawEvents.removeLast();
        }
      });
    });
  }

  String _formatEvent(String name, dynamic data) {
    try {
      final ts = DateTime.now().toIso8601String();
      final payload =
          data is Map ? jsonEncode(data) : data?.toString() ?? 'null';
      return '[$ts] $name: $payload';
    } catch (_) {
      return '[$name] $data';
    }
  }

  String _mapNativeStateToDisplay(String? native) {
    switch (native) {
      case 'DRIVING':
        return 'CarExitState.driving';
      case 'TENTATIVE_PARKED':
        return 'CarExitState.stopped';
      case 'CONFIRMED_PARKED':
        return 'CarExitState.exited';
      case 'UNKNOWN':
      default:
        return 'CarExitState.unknown';
    }
  }

  // Eliminados listeners de estrategia

  // (Eliminado) _showSnackBar no es necesario sin flujo de beacons

  // (Eliminado) _showConfirmationDialog no es necesario sin flujo de beacons

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
          // (Sin estrategia)
          if (kDebugMode) ...[
            const SizedBox(height: 16.0),
            _buildDebugPanel(context),
          ],
        ],
      ),
    );
  }

  Widget _buildDebugPanel(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Depuración del servicio (solo desarrollo)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Sin indicador de estrategia
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'Estado actual: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Flexible(child: Text(_currentDetectorState)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: Text(_captureEnabled ? 'Captura ON' : 'Captura OFF'),
                  selected: _captureEnabled,
                  onSelected: (v) {
                    setState(() {
                      _captureEnabled = v;
                    });
                  },
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _backgroundService.invoke(
                      BackgroundServiceCommands.getCurrentState,
                    );
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Solicitar estado actual'),
                ),
                // Botón de solicitar estrategia eliminado
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _rawEvents.clear();
                    });
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Limpiar eventos'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final ok = await ParkingDetectorPlugin.emitTestEvent();
                      if (!mounted) return;
                      setState(() {
                        _rawEvents.insert(
                          0,
                          _formatEvent('emitTestEvent', {'status': ok}),
                        );
                      });
                    } catch (e) {
                      if (!mounted) return;
                      setState(() {
                        _rawEvents.insert(
                          0,
                          _formatEvent('emitTestEvent', {
                            'error': e.toString(),
                          }),
                        );
                      });
                    }
                  },
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Emitir evento de prueba'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Eventos crudos recientes:'),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _rawEvents.length,
                itemBuilder:
                    (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Text(
                        _rawEvents[i],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
