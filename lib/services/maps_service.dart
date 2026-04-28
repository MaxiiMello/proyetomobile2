import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsService {
  MapsService._();

  static final MapsService instance = MapsService._();

  GoogleMapController? _mapController;

  GoogleMapController? get mapController => _mapController;

  /// Inicializar controlador do mapa
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Mover câmera para uma posição específica
  Future<void> moveCameraTo(
    LatLng position, {
    double zoom = 15.0,
  }) async {
    if (_mapController == null) {
      throw Exception('Controlador do mapa não foi inicializado');
    }

    final cameraUpdate = CameraUpdate.newCameraPosition(
      CameraPosition(
        target: position,
        zoom: zoom,
      ),
    );

    await _mapController!.animateCamera(cameraUpdate);
  }

  /// Atualizar câmera sem animação
  void updateCameraPosition(
    LatLng position, {
    double zoom = 15.0,
  }) {
    if (_mapController == null) return;

    final cameraUpdate = CameraUpdate.newCameraPosition(
      CameraPosition(
        target: position,
        zoom: zoom,
      ),
    );

    _mapController!.moveCamera(cameraUpdate);
  }

  /// Zoom in
  Future<void> zoomIn() async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.zoomIn(),
    );
  }

  /// Zoom out
  Future<void> zoomOut() async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.zoomOut(),
    );
  }

  /// Obter zoom atual
  Future<double> getZoomLevel() async {
    if (_mapController == null) return 15.0;
    return await _mapController!.getZoomLevel();
  }

  /// Obter posição atual da câmera
  Future<LatLngBounds> getVisibleRegion() async {
    if (_mapController == null) {
      throw Exception('Controlador do mapa não foi inicializado');
    }
    return await _mapController!.getVisibleRegion();
  }

  /// Limpar controlador ao descartar
  void dispose() {
    _mapController = null;
  }
}
