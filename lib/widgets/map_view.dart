import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:developer' as dev;

class MapView extends StatefulWidget {
  final LatLng? currentLocation;
  final LatLng? savedLocation;
  const MapView({this.currentLocation, this.savedLocation, super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _controller;

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
    _controller = controller;
    dev.log(_logMapCreatedSuccessMessage, name: 'MapView');
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
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};

    _addMarker(
      markers,
      _currentLocationMarkerId,
      _effectiveLocation,
      _currentLocationTitle,
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    if (widget.savedLocation != null) {
      _addMarker(
        markers,
        _savedLocationMarkerId,
        widget.savedLocation!,
        _savedLocationTitle,
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    }

    return markers;
  }
}
