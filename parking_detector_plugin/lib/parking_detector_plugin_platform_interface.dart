import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'parking_detector_plugin_method_channel.dart';

abstract class ParkingDetectorPluginPlatform extends PlatformInterface {
  /// Constructs a ParkingDetectorPluginPlatform.
  ParkingDetectorPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static ParkingDetectorPluginPlatform _instance = MethodChannelParkingDetectorPlugin();

  /// The default instance of [ParkingDetectorPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelParkingDetectorPlugin].
  static ParkingDetectorPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ParkingDetectorPluginPlatform] when
  /// they register themselves.
  static set instance(ParkingDetectorPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
