import 'package:flutter/foundation.dart';

class PlansViewModel extends ChangeNotifier {
  bool isMonthly = true;
  bool isLoading = false;
  String? errorMessage;

  void toggleBillingCycle(bool monthly) {
    isMonthly = monthly;
    notifyListeners();
  }

  Future<void> subscribePlan(String planName) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // TODO: Implementar integração com pagamento
      await Future.delayed(const Duration(seconds: 1));
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  String getEssentialPrice() => isMonthly ? '0' : '0';
  String getPremiumPrice() => isMonthly ? '5' : '50';
  String getPricePeriod() => isMonthly ? '/mês' : '/ano';
}
