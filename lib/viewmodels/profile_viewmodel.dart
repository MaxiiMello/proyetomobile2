import 'package:flutter/foundation.dart';

class ProfileViewModel extends ChangeNotifier {
  String userName = 'User';
  String userEmail = 'paidetodos@gmail.com';
  
  int travelCount = 0;
  double totalKilometers = 0;
  String totalTime = '0h';
  
  String subscriptionPlan = 'Premium';
  String renewalDays = '99 dias';
  
  bool isLoadingProfile = false;
  String? errorMessage;

  ProfileViewModel() {
    _initializeData();
  }

  void _initializeData() {
    // TODO: Carregar dados do usuário
  }

  Future<void> logout() async {
    isLoadingProfile = true;
    errorMessage = null;
    notifyListeners();

    try {
      // TODO: Implementar logout real (limpar tokens, cache, etc)
      await Future.delayed(const Duration(milliseconds: 500));
      
      isLoadingProfile = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    isLoadingProfile = true;
    notifyListeners();

    try {
      // TODO: Buscar dados atualizados do backend
      await Future.delayed(const Duration(seconds: 1));
      
      isLoadingProfile = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      isLoadingProfile = false;
      notifyListeners();
    }
  }
}
