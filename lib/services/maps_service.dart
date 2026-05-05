import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapsService {
  MapsService._();

  static final MapsService instance = MapsService._();

  MapController? _mapController;

  MapController? get mapController => _mapController;

  /// Inicializar controlador do mapa
  void setMapController(MapController controller) {
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
    // flutter_map usa 'move' directo para cambiar la cámara
    _mapController!.move(position, zoom);
  }

  /// Atualizar câmera sem animação
  void updateCameraPosition(
    LatLng position, {
    double zoom = 15.0,
  }) {
    if (_mapController == null) return;
    _mapController!.move(position, zoom);
  }

  /// Zoom in
  Future<void> zoomIn() async {
    if (_mapController == null) return;
    final currentZoom = _mapController!.camera.zoom;
    final center = _mapController!.camera.center;
    _mapController!.move(center, currentZoom + 1);
  }

  /// Zoom out
  Future<void> zoomOut() async {
    if (_mapController == null) return;
    final currentZoom = _mapController!.camera.zoom;
    final center = _mapController!.camera.center;
    _mapController!.move(center, currentZoom - 1);
  }

  /// Obter zoom atual
  Future<double> getZoomLevel() async {
    if (_mapController == null) return 15.0;
    return _mapController!.camera.zoom;
  }

  /// Obter posição atual da câmera
  Future<LatLngBounds> getVisibleRegion() async {
    if (_mapController == null) {
      throw Exception('Controlador do mapa não foi inicializado');
    }
    return _mapController!.camera.visibleBounds;
  }

  /// Limpar controlador ao descartar
  void dispose() {
    _mapController = null;
  }
}