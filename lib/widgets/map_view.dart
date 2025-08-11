import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:developer' as dev;
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;

class MapView extends StatefulWidget {
  final LatLng? currentLocation;
  final LatLng? savedLocation;
  const MapView({this.currentLocation, this.savedLocation, super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  BitmapDescriptor? _carIcon;

  // Ubicación por defecto: Ciudad de México
  static const LatLng _defaultLocation = LatLng(19.4326, -99.1332);
  static const double _defaultZoom = 15.0;
  static const String _currentLocationMarkerId = 'current_location';
  static const String _savedLocationMarkerId = 'saved_location';

  // Textos para internacionalización
  static const String _currentLocationTitle = 'Mi ubicación actual';
  static const String _savedLocationTitle = 'Ubicación del vehículo';
  static const String _logMapCreatedSuccessMessage = 'Mapa creado exitosamente';
  static const String _logCurrentLocationMessage =
      'MapView - Ubicación actual:';
  static const String _logSavedLocationMessage =
      'MapView - Ubicación guardada:';
  static const String _logEffectiveLocationMessage =
      'MapView - Ubicación efectiva:';

  /// Obtiene la ubicación actual o la ubicación por defecto si no está disponible
  LatLng get _effectiveLocation => widget.currentLocation ?? _defaultLocation;

  @override
  Widget build(BuildContext context) {
    _logLocationInfo();

    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: _effectiveLocation,
            zoom: _defaultZoom,
          ),
          markers: _buildMarkers(),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          compassEnabled: true,
          onMapCreated: _onMapCreated,
        ),
      ],
    );
  }

  void _logLocationInfo() {
    dev.log(
      '$_logCurrentLocationMessage ${widget.currentLocation}',
      name: 'MapView',
    );
    dev.log(
      '$_logSavedLocationMessage ${widget.savedLocation}',
      name: 'MapView',
    );
    dev.log(
      '$_logEffectiveLocationMessage $_effectiveLocation',
      name: 'MapView',
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    dev.log(_logMapCreatedSuccessMessage, name: 'MapView');
    _ensureCarIcon();
  }

  void _addMarker(
    Set<Marker> markers,
    String markerId,
    LatLng position,
    String title,
    BitmapDescriptor icon,
  ) {
    markers.add(
      Marker(
        markerId: MarkerId(markerId),
        position: position,
        infoWindow: InfoWindow(title: title),
        icon: icon,
        onTap: () => _onMarkerTap(markerId, position),
      ),
    );
  }

  Future<void> _onMarkerTap(String markerId, LatLng position) async {
    if (markerId != _savedLocationMarkerId) return;
    final lat = position.latitude;
    final lng = position.longitude;
    // Intentar abrir Google Maps con navegación al destino
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};

    // Si hay ubicación guardada, mostrar icono de auto en esa posición
    if (widget.savedLocation != null) {
      // Marcador de auto para ubicación guardada (ícono de coche)
      _addMarker(
        markers,
        _savedLocationMarkerId,
        widget.savedLocation!,
        _savedLocationTitle,
        _carIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    } else {
      // Sin ubicación guardada: pequeño indicador de posición actual
      _addMarker(
        markers,
        _currentLocationMarkerId,
        _effectiveLocation,
        _currentLocationTitle,
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    }

    return markers;
  }

  Future<void> _ensureCarIcon() async {
    if (_carIcon != null) return;
    try {
      final icon = await _createCarMarkerIcon(
        size: 96,
        background: Colors.blue,
        foreground: Colors.white,
      );
      if (mounted) setState(() => _carIcon = icon);
    } catch (_) {}
  }

  Future<BitmapDescriptor> _createCarMarkerIcon({
    required int size,
    required Color background,
    required Color foreground,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double s = size.toDouble();
    final Paint paint = Paint()..color = background;
    canvas.drawCircle(Offset(s / 2, s / 2), s / 2, paint);

    final TextPainter tp = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    final TextSpan span = TextSpan(
      text: String.fromCharCode(Icons.directions_car.codePoint),
      style: TextStyle(
        fontSize: s * 0.6,
        fontFamily: Icons.directions_car.fontFamily,
        package: Icons.directions_car.fontPackage,
        color: foreground,
      ),
    );
    tp.text = span;
    tp.layout();
    final double dx = (s - tp.width) / 2;
    final double dy = (s - tp.height) / 2;
    tp.paint(canvas, Offset(dx, dy));

    final ui.Image img = await recorder.endRecording().toImage(size, size);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(bytes);
  }
}
