import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:where_is_it/services/background_service/background_service_events.dart';
import 'package:where_is_it/services/background_service/background_service_protocol.dart';
import 'package:where_is_it/services/background_service/typed_listeners.dart';
import 'package:where_is_it/widgets/active_strategy_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FlutterBackgroundService _backgroundService =
      FlutterBackgroundService();
  String _activeStrategyName = 'Ninguna';
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _subscriptions.add(_getStrategyChangedListener());
    _subscriptions.add(_getInitialActiveStrategyListener());
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
          // Tarjeta de estrategia activa
          ActiveStrategyCard(activeStrategyName: _activeStrategyName),
        ],
      ),
    );
  }
}
