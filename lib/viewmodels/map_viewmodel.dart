import 'package:flutter/foundation.dart';

import '../models/database/repositories/user_repository.dart';
import '../services/gps_service.dart' show GpsService, LocationData;
import '../services/address_service.dart' show AddressService, AddressSuggestion;

class MapViewModel extends ChangeNotifier {
  final GpsService _gpsService = GpsService();
  final AddressService _addressService = AddressService();

  double currentLatitude = -30.8936; // Santana do Livramento, RS
  double currentLongitude = -55.5205;
  String? selectedDestination;
  double zoomLevel = 15.0;

  bool isLoadingMap = false;
  bool isNavigating = false;
  String? errorMessage;
  User? currentUser;

  // Propriedades para sugestões de endereços
  List<String> addressSuggestions = [];
  bool isLoadingSuggestions = false;

  MapViewModel({User? user}) {
    currentUser = user;
    // Se em web, já começa com coordenadas padrão
    if (kIsWeb) {
      isLoadingMap = false;
    } else {
      // Em mobile, tenta carregar localização real
      loadMap();
    }
  }

  /// Caregar mapa
  Future<void> loadMap() async {
    isLoadingMap = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Primeiro tenta última localização conhecida (mais rápido) com timeout
      LocationData? location;
      try {
        location = await _gpsService.getLastKnownLocation()
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        // Continua mesmo que falhe
        location = null;
      }
      
      // Se não encontrou última localização, obtém atual com timeout
      if (location == null) {
        try {
          location = await _gpsService.getCurrentLocation()
              .timeout(const Duration(seconds: 8));
        } catch (e) {
          // Se GPS falhar, usa localização padrão (Santana do Livramento, RS)
          currentLatitude = -30.8936;
          currentLongitude = -55.5205;
          isLoadingMap = false;
          notifyListeners();
          return;
        }
      }
      
      if (location != null) {
        currentLatitude = location.latitude;
        currentLongitude = location.longitude;
      }

      isLoadingMap = false;
      notifyListeners();
    } catch (e) {
      // Fallback para localização padrão se tudo falhar
      currentLatitude = -30.8936;
      currentLongitude = -55.5205;
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

  /// Buscar sugestões de endereços enquanto o usuário digita
  Future<void> getAddressSuggestions(String input) async {
    if (input.isEmpty) {
      addressSuggestions = [];
      notifyListeners();
      return;
    }

    isLoadingSuggestions = true;
    notifyListeners();

    try {
      final suggestions = await _addressService.getPlacePredictions(input);
      addressSuggestions = suggestions;
    } catch (e) {
      addressSuggestions = [];
      print('Error getting suggestions: $e');
    }

    isLoadingSuggestions = false;
    notifyListeners();
  }

  /// Selecionar um endereço e mover o mapa para lá
  Future<void> selectAddress(String address) async {
    isLoadingMap = true;
    selectedDestination = address;
    addressSuggestions = []; // Limpar sugestões
    notifyListeners();

    try {
      final suggestion = await _addressService.geocodeAddress(address);
      
      if (suggestion != null) {
        currentLatitude = suggestion.latitude;
        currentLongitude = suggestion.longitude;
        zoomLevel = 15.0; // Reset zoom para endereço selecionado
        errorMessage = null;
      } else {
        errorMessage = 'Não foi possível encontrar este local';
      }
    } catch (e) {
      errorMessage = 'Erro ao buscar endereço: $e';
      print('Error selecting address: $e');
    }

    isLoadingMap = false;
    notifyListeners();
  }

  /// Limpar sugestões
  void clearSuggestions() {
    addressSuggestions = [];
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
