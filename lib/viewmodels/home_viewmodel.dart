import 'package:flutter/foundation.dart';

class HomeViewModel extends ChangeNotifier {
  String currentLocation = 'null';
  int routeCount = 0;
  
  bool isLoadingLocation = false;
  String? errorMessage;

  HomeViewModel() {
    _initializeData();
  }

  void _initializeData() {
    // TODO: Carregar localização actual
    // TODO: Carregar contagem de rotas
  }

  Future<void> refreshLocation() async {
    isLoadingLocation = true;
    errorMessage = null;
    notifyListeners();

    try {
      // TODO: Obter localização real via GPS
      await Future.delayed(const Duration(seconds: 1));
      
      isLoadingLocation = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      isLoadingLocation = false;
      notifyListeners();
    }
  }

  void searchDestination(String destination) {
    // TODO: Implementar busca de destinos
  }
}
