import 'dart:developer' as dev;
import 'package:flutter_background_service/flutter_background_service.dart';

/// Registra un comando del servicio: escucha el evento, maneja payload y reemite el resultado.
void handleServiceCommand<T>(
  ServiceInstance service,
  String commandEvent,
  Future<T> Function(Map<String, dynamic>? payload) handler,
  String resultEvent,
  Map<String, dynamic> Function(T result) resultMapper,
) {
  service.on(commandEvent).listen((event) async {
    try {
      final result = await handler(event);
      service.invoke(resultEvent, resultMapper(result));
    } catch (e) {
      dev.log('Error handling $commandEvent: $e', name: 'BackgroundService');
    }
  });
}

/// Registra un evento del servicio: opcionalmente ejecuta beforeInvoke y reemite datos.
void handleServiceEvent(
  ServiceInstance service,
  String eventName,
  Map<String, dynamic> Function() getData, {
  void Function()? beforeInvoke,
}) {
  service.on(eventName).listen((event) {
    beforeInvoke?.call();
    service.invoke(eventName, getData());
  });
}
