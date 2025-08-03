import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';

extension TypedBackgroundService on FlutterBackgroundService {
  /// Listen to [eventName], automatically cast the incoming Map<String,dynamic>
  /// and convert it to your domain object via [fromJson].
  Stream<T> onEvent<T>(
    String eventName,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return on(eventName)
        .where((e) => e is Map<String, dynamic>)
        .cast<Map<String, dynamic>>()
        .map(fromJson);
  }
}
