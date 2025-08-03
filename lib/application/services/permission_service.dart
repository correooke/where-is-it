import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Solicita permiso de Activity Recognition (Android 10+)
  Future<bool> requestActivityRecognitionPermission() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  /// Verifica si el permiso de Activity Recognition ya está concedido
  Future<bool> checkActivityRecognitionPermission() async {
    final status = await Permission.activityRecognition.status;
    return status.isGranted;
  }
}
