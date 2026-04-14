import 'package:flutter/foundation.dart';

class MapViewModel extends ChangeNotifier {
  bool isLoadingMap = false;
  String? errorMessage;
  String? selectedDestination;

  Future<void> loadMap() async {
    isLoadingMap = true;
    errorMessage = null;
    notifyListeners();

    try {
      // TODO: Implementar carregamento do mapa (flutter_map + .mbtiles)
      await Future.delayed(const Duration(seconds: 1));
      
      isLoadingMap = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      isLoadingMap = false;
      notifyListeners();
    }
  }

  Future<void> requestGPSLocation() async {
    try {
      // TODO: Implementar GPS tracking
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void zoomIn() {
    // TODO: Implementar zoom in
    notifyListeners();
  }

  void zoomOut() {
    // TODO: Implementar zoom out
    notifyListeners();
  }

  void searchDestination(String destination) {
    selectedDestination = destination;
    notifyListeners();
  }
}
