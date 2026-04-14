import 'package:flutter/foundation.dart';

import '../models/database/repositories/user_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();

  String userName = 'Usuario';
  String userEmail = '';
  String? userPhone = '';
  
  int travelCount = 0;
  double totalKilometers = 0.0;
  String totalTime = '0h';
  
  String subscriptionPlan = 'essential';
  String renewalDays = 'Sin fecha';
  
  bool isLoadingProfile = false;
  String? errorMessage;
  User? currentUser;

  ProfileViewModel({User? user}) {
    currentUser = user;
    if (user != null) {
      _initializeData();
    }
  }

  void _initializeData() {
    if (currentUser != null) {
      userName = currentUser!.name;
      userEmail = currentUser!.email;
      userPhone = currentUser!.phone;
      subscriptionPlan = currentUser!.subscriptionPlan;
      renewalDays = currentUser!.subscriptionEndDate?.toString() ?? 'Sin fecha';
    }
  }

  /// Actualizar perfil del usuario
  Future<bool> updateProfile({
    required String name,
    String? phone,
  }) async {
    if (currentUser == null) {
      errorMessage = 'Usuario no autenticado';
      notifyListeners();
      return false;
    }

    isLoadingProfile = true;
    errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _userRepository.updateProfile(
        userId: currentUser!.id,
        name: name,
        phone: phone,
      );

      if (updatedUser != null) {
        currentUser = updatedUser;
        _initializeData();
      }

      isLoadingProfile = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoadingProfile = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout seguro
  Future<void> logout() async {
    isLoadingProfile = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Limpiar datos
      currentUser = null;
      userName = 'Usuario';
      userEmail = '';
      userPhone = '';
      subscriptionPlan = 'essential';
      renewalDays = 'Sin fecha';
      
      isLoadingProfile = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      isLoadingProfile = false;
      notifyListeners();
    }
  }

  /// Refrescar datos del perfil
  Future<void> refreshProfile() async {
    if (currentUser == null) {
      errorMessage = 'Usuario no autenticado';
      notifyListeners();
      return;
    }

    isLoadingProfile = true;
    notifyListeners();

    try {
      final user = await _userRepository.getUserById(currentUser!.id);
      if (user != null) {
        currentUser = user;
        _initializeData();
      }
      
      isLoadingProfile = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoadingProfile = false;
      notifyListeners();
    }
  }
}
