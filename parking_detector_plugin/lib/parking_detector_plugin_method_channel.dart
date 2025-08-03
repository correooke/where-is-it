import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'parking_detector_plugin_platform_interface.dart';

/// An implementation of [ParkingDetectorPluginPlatform] that uses method channels.
class MethodChannelParkingDetectorPlugin extends ParkingDetectorPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('parking_detector_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
