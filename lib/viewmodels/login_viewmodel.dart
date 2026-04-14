import 'package:flutter/foundation.dart';

import '../models/database/repositories/user_repository.dart';

class LoginViewModel extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();

  String email = '';
  String password = '';
  String name = '';

  bool isLoading = false;
  bool isLoadingRegister = false;
  String? errorMessage;
  User? currentUser;

  /// Realizar login con email
  Future<bool> loginWithEmail(String emailInput, String passwordInput) async {
    email = emailInput;
    password = passwordInput;

    if (email.isEmpty || password.isEmpty) {
      errorMessage = 'Email y contraseña son requeridos';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = await _userRepository.login(
        email: email,
        password: password,
      );

      currentUser = user;
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

  /// Registrarse
  Future<bool> registerUser({
    required String emailInput,
    required String passwordInput,
    required String nameInput,
    String? phone,
  }) async {
    email = emailInput;
    password = passwordInput;
    name = nameInput;

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      errorMessage = 'Email, contraseña y nombre son requeridos';
      notifyListeners();
      return false;
    }

    if (password.length < 6) {
      errorMessage = 'La contraseña debe tener al menos 6 caracteres';
      notifyListeners();
      return false;
    }

    isLoadingRegister = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = await _userRepository.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      currentUser = user;
      email = '';
      password = '';
      name = '';
      isLoadingRegister = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoadingRegister = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loginWithGoogle() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));
      errorMessage = 'Login Google no implementado aún';
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  /// Logout
  void logout() {
    currentUser = null;
    email = '';
    password = '';
    name = '';
    errorMessage = null;
    notifyListeners();
  }

  /// Verificar si hay sesión activa
  bool get isAuthenticated => currentUser != null;

  /// Cambiar contraseña
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (currentUser == null) {
      errorMessage = 'Usuario no autenticado';
      notifyListeners();
      return false;
    }

    if (newPassword.length < 6) {
      errorMessage = 'La nueva contraseña debe tener al menos 6 caracteres';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _userRepository.changePassword(
        userId: currentUser!.id,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

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
}
