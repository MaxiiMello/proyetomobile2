import 'package:flutter/foundation.dart';

import '../models/database/repositories/user_repository.dart';
import '../services/gps_service.dart';

class HomeViewModel extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  final GpsService _gpsService = GpsService();

  String currentLocation = 'Obtener ubicación...';
  int routeCount = 0;
  double currentLatitude = 0;
  double currentLongitude = 0;

  bool isLoadingLocation = false;
  String? errorMessage;
  User? currentUser;

  HomeViewModel({User? user}) {
    currentUser = user;
    _initializeData();
  }

  void _initializeData() {
    // Cargar conteo inicial (puede venir de BD)
    routeCount = 0;
    // La ubicación se obtiene bajo demanda
  }

  /// Refrescar ubicación actual
  Future<void> refreshLocation() async {
    isLoadingLocation = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Primero intentar obtener última ubicación conocida (más rápido)
      final lastLocation = await _gpsService.getLastKnownLocation();

      if (lastLocation != null) {
        currentLatitude = lastLocation.latitude;
        currentLongitude = lastLocation.longitude;
        currentLocation =
            '${lastLocation.latitude.toStringAsFixed(6)}, ${lastLocation.longitude.toStringAsFixed(6)}';
      }

      // Luego obtener la ubicación actual en background
      final location = await _gpsService.getCurrentLocation();
      currentLatitude = location.latitude;
      currentLongitude = location.longitude;
      currentLocation =
          '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';

      isLoadingLocation = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      currentLocation = 'Error obteniendo ubicación';
      isLoadingLocation = false;
      notifyListeners();
    }
  }

  /// Buscar destino
  void searchDestination(String destination) {
    if (destination.isEmpty) {
      errorMessage = 'Ingrese un destino';
      notifyListeners();
      return;
    }

    errorMessage = null;
    notifyListeners();
  }

  /// Obtener stream de ubicación en tiempo real
  Stream<void> getLocationStream() {
    return _gpsService
        .getLocationStream(distanceFilter: 5)
        .map((location) {
      currentLatitude = location.latitude;
      currentLongitude = location.longitude;
      currentLocation =
          '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
      notifyListeners();
    });
  }

  /// Cargar datos del usuario actual
  Future<void> loadUserData(int userId) async {
    try {
      final user = await _userRepository.getUserById(userId);
      if (user != null) {
        currentUser = user;
        routeCount = 0;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}
