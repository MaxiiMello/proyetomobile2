import 'package:flutter/foundation.dart';

class LoginViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  Future<void> loginWithEmail(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // TODO: Implementar autenticação real
      await Future.delayed(const Duration(seconds: 1));
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // TODO: Implementar autenticação com Google
      await Future.delayed(const Duration(seconds: 1));
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }
}
