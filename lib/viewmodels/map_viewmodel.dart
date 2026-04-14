import 'package:flutter/foundation.dart';

import '../models/database/repositories/user_repository.dart';
import '../services/gps_service.dart';

class MapViewModel extends ChangeNotifier {
  final GpsService _gpsService = GpsService();

  double currentLatitude = 0;
  double currentLongitude = 0;
  String? selectedDestination;
  double zoomLevel = 15.0;

  bool isLoadingMap = false;
  bool isNavigating = false;
  String? errorMessage;
  User? currentUser;

  MapViewModel({User? user}) {
    currentUser = user;
  }

  /// Cargar mapa
  Future<void> loadMap() async {
    isLoadingMap = true;
    errorMessage = null;
    notifyListeners();

    try {
      final location = await _gpsService.getLastKnownLocation();
      if (location != null) {
        currentLatitude = location.latitude;
        currentLongitude = location.longitude;
      }

      isLoadingMap = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoadingMap = false;
      notifyListeners();
    }
  }

  /// Solicitar y obtener ubicación GPS
  Future<void> requestGPSLocation() async {
    try {
      final location = await _gpsService.getCurrentLocation();
      currentLatitude = location.latitude;
      currentLongitude = location.longitude;
      isLoadingMap = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Zoom in
  void zoomIn() {
    if (zoomLevel < 20) {
      zoomLevel += 1;
      notifyListeners();
    }
  }

  /// Zoom out
  void zoomOut() {
    if (zoomLevel > 5) {
      zoomLevel -= 1;
      notifyListeners();
    }
  }

  /// Buscar y establecer destino
  void searchDestination(String destination) {
    if (destination.isEmpty) {
      errorMessage = 'Ingrese un destino';
      notifyListeners();
      return;
    }

    selectedDestination = destination;
    errorMessage = null;
    notifyListeners();
  }

  /// Obtener stream de ubicación en tiempo real para mapa
  Stream<void> getMapLocationStream() {
    return _gpsService
        .getLocationStream(distanceFilter: 5)
        .map((location) {
      currentLatitude = location.latitude;
      currentLongitude = location.longitude;
      notifyListeners();
    });
  }
}
