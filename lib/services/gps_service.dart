import 'package:geolocator/geolocator.dart';

class GpsService {
  
  // Función principal para obtener la posición actual
  Future<Position> determinarPosicion() async {
    bool servicioHabilitado;
    LocationPermission permiso;

    // 1. Verificar si el GPS del celular está encendido
    servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      return Future.error('El servicio de localización está desactivado.');
    }

    // 2. Manejar los permisos
    permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        return Future.error('Los permisos de localización fueron denegados.');
      }
    }
    
    if (permiso == LocationPermission.deniedForever) {
      return Future.error('Los permisos están denegados permanentemente.');
    } 

    // 3. Si todo está bien, obtener la ubicación con alta precisión
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
  }
}