import 'package:flutter/foundation.dart';
import '../models/database/repositories/user_repository.dart';
import '../services/session_service.dart';

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

  Future<void> logout() async {
    isLoadingProfile = true;
    errorMessage = null;
    notifyListeners();

    try {
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

  Future<void> refreshProfile() async {
    isLoadingProfile = true;
    errorMessage = null;
    notifyListeners();

    try {
      final userId = currentUser?.id ?? SessionService().currentUserId;

      if (userId == null) {
        errorMessage = 'Usuario no autenticado';
        isLoadingProfile = false;
        notifyListeners();
        return;
      }

      final user = await _userRepository.getUserById(userId);
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

  Future<bool> upgradeToPremium() async {
    isLoadingProfile = true;
    errorMessage = null;
    notifyListeners();

    try {
      final userId = currentUser?.id ?? SessionService().currentUserId;

      if (userId == null) {
        errorMessage = 'Usuario no autenticado';
        isLoadingProfile = false;
        notifyListeners();
        return false;
      }

      final updatedUser = await _userRepository.updateSubscription(
        userId: userId,
        plan: 'premium',
        daysValid: 365,
      );

      if (updatedUser != null) {
        currentUser = updatedUser;
        _initializeData();
      }

      subscriptionPlan = currentUser?.subscriptionPlan ?? 'premium';
      renewalDays = currentUser?.subscriptionEndDate?.toString() ?? renewalDays;

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

  Future<bool> deleteAccount() async {
    if (currentUser == null) return false;
    
    isLoadingProfile = true;
    notifyListeners();
    
    try {
      await _userRepository.deleteAccount(currentUser!.id);
      await logout();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoadingProfile = false;
      notifyListeners();
      return false;
    }
  }
}