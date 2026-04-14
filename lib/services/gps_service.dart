import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final double? altitude;
  final double? speed;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.altitude,
    this.speed,
  });

  @override
  String toString() => 'LocationData(lat: $latitude, lng: $longitude, acc: $accuracy)';
}

class GpsService {
  static const int maxAttempts = 3;
  static const Duration timeout = Duration(seconds: 10);

  /// Verificar y solicitar permisos de ubicación
  static Future<LocationPermission> _checkAndRequestPermission() async {
    final permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      final requestedPermission = await Geolocator.requestPermission();
      return requestedPermission;
    }

    return permission;
  }

  /// Verificar si el servicio de ubicación está habilitado
  static Future<bool> _isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Obtener ubicación actual con reintentos
  Future<LocationData> getCurrentLocation({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
  }) async {
    try {
      // Verificar si el servicio de ubicación está habilitado
      final isServiceEnabled = await _isLocationServiceEnabled();
      if (!isServiceEnabled) {
        throw Exception('El servicio de localización está desactivado');
      }

      // Verificar y solicitar permisos
      final permission = await _checkAndRequestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception('Permisos de localización denegados');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos de localización denegados permanentemente');
      }

      // Obtener posición actual con reintentos
      Position? position;
      int attempt = 0;

      while (position == null && attempt < maxAttempts) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: desiredAccuracy,
            timeLimit: timeout,
          ).timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException('Timeout obteniendo posición');
            },
          );
        } catch (e) {
          attempt++;
          if (attempt >= maxAttempts) {
            throw Exception('Error al obtener posición después de $maxAttempts intentos: $e');
          }
          // Esperar antes de reintentar
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }

      if (position == null) {
        throw Exception('No se pudo obtener la posición');
      }

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          position.timestamp.millisecondsSinceEpoch,
        ),
        altitude: position.altitude,
        speed: position.speed,
      );
    } catch (e) {
      throw Exception('Error en GPS Service: $e');
    }
  }

  /// Obtener última ubicación conocida (más rápido)
  Future<LocationData?> getLastKnownLocation() async {
    try {
      final isServiceEnabled = await _isLocationServiceEnabled();
      if (!isServiceEnabled) return null;

      final position = await Geolocator.getLastKnownPosition();

      if (position == null) return null;

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          position.timestamp.millisecondsSinceEpoch,
        ),
        altitude: position.altitude,
        speed: position.speed,
      );
    } catch (e) {
      return null;
    }
  }

  /// Stream de ubicación en tiempo real
  Stream<LocationData> getLocationStream({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
    int distanceFilter = 10, // metros
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: desiredAccuracy,
        distanceFilter: distanceFilter,
      ),
    ).map(
      (position) => LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          position.timestamp.millisecondsSinceEpoch,
        ),
        altitude: position.altitude,
        speed: position.speed,
      ),
    );
  }

  /// Calcular distancia entre dos puntos (Haversine)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Radio de la Tierra en km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // km
  }

  static double _toRad(double degree) => degree * 3.14159 / 180;

  /// Para test: usar ubicación mock
  Future<void> setMockLocation(double latitude, double longitude) async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      // En modo de debugging
      throw Exception('Mock location no disponible: $e');
    }
  }
}