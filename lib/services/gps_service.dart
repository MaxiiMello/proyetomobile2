import 'package:geolocator/geolocator.dart';

class GpsService {
  
  Future<Position> determinarPosicion() async {
    bool servicioHabilitado;
    LocationPermission permiso;

    servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      return Future.error('El servicio de localización está desactivado.');
    }

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

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
  }
}