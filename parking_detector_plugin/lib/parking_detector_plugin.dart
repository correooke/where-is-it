import 'package:flutter/services.dart';

class ParkingDetectorPlugin {
  static const MethodChannel _channel = MethodChannel(
    'com.example.parking_detector_plugin/parking_detection',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.example.parking_detector_plugin/parking_events',
  );

  static Future<bool> startParkingDetection() async {
    return await _channel.invokeMethod('startParkingDetection');
  }

  static Future<bool> stopParkingDetection() async {
    return await _channel.invokeMethod('stopParkingDetection');
  }

  static Future<String> getCurrentState() async {
    return await _channel.invokeMethod('getCurrentState');
  }

  static Stream<dynamic> get parkingEvents =>
      _eventChannel.receiveBroadcastStream();

  /// Emite un evento de prueba desde el plugin nativo (para diagnóstico)
  static Future<bool> emitTestEvent() async {
    return await _channel.invokeMethod('emitTestEvent');
  }
}
