import 'package:flutter/foundation.dart';

import '../models/database/repositories/user_repository.dart';

class PlansViewModel extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  
  bool isMonthly = true;
  bool isLoading = false;
  String? errorMessage;
  User? currentUser;

  PlansViewModel({User? user}) {
    currentUser = user;
  }

  /// Cambiar ciclo de facturación (Mensual/Anual)
  void toggleBillingCycle(bool monthly) {
    isMonthly = monthly;
    notifyListeners();
  }

  /// Suscribirse a un plan
  Future<bool> subscribePlan(String planName) async {
    if (currentUser == null) {
      errorMessage = 'Usuario no autenticado';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Calcular días válidos
      int daysValid = isMonthly ? 30 : 365;

      // Actualizar suscripción en BD
      final updatedUser = await _userRepository.updateSubscription(
        userId: currentUser!.id,
        plan: planName.toLowerCase(),
        daysValid: daysValid,
      );

      if (updatedUser != null) {
        currentUser = updatedUser;
      }

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Obtener precio del plan
  String getEssentialPrice() => isMonthly ? 'Gratis' : 'Gratis';
  String getPremiumPrice() => isMonthly ? '\$5' : '\$50';
  String getPricePeriod() => isMonthly ? '/mês' : '/ano';

  /// Verificar si usuario actual tiene plan premium activo
  bool get isPremiumActive =>
      currentUser?.subscriptionPlan == 'premium' &&
      (currentUser?.subscriptionEndDate?.isAfter(DateTime.now()) ?? false);
}
