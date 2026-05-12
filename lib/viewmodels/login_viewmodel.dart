import 'package:flutter/foundation.dart';

import '../models/database/repositories/user_repository.dart';
import '../services/session_service.dart';

class LoginViewModel extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  final SessionService _sessionService = SessionService();

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
      errorMessage = 'Email e senha são obrigatórios';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      print('🔐 [LoginViewModel] Iniciando login...');
      
      final user = await _userRepository.login(
        email: email,
        password: password,
      );

      currentUser = user;
      print('✅ [LoginViewModel] Login exitoso, usuario: ${user.email}');
      
      // Salvar sessão para manter logado
      try {
        await _sessionService.saveSession(user);
        print('✅ [LoginViewModel] Sesión guardada');
      } catch (e) {
        print('⚠️ [LoginViewModel] Error al guardar sesión: $e');
        // Continua mesmo se a sessão não salvar (usuário ainda pode fazer login)
      }

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      print('❌ [LoginViewModel] Error: $e');
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
      print('📝 [LoginViewModel] Iniciando registro para: $email');
      
      final user = await _userRepository.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      currentUser = user;
      print('✅ [LoginViewModel] Registro exitoso para: ${user.email}');
      
      // Salvar sessão após registro bem-sucedido
      try {
        await _sessionService.saveSession(user);
        print('✅ [LoginViewModel] Sesión guardada después de registro');
      } catch (e) {
        print('⚠️ [LoginViewModel] Error al guardar sesión después de registro: $e');
        // Continua mesmo se a sessão não salvar
      }

      email = '';
      password = '';
      name = '';
      isLoadingRegister = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      print('❌ [LoginViewModel] Error en registro: $e');
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
  Future<void> logout() async {
    currentUser = null;
    email = '';
    password = '';
    name = '';
    errorMessage = null;
    
    // Limpar sessão do dispositivo
    await _sessionService.clearSession();
    
    notifyListeners();
  }

  /// Restaurar sessão salva no dispositivo
  Future<bool> restoreSession() async {
    try {
      final user = await _sessionService.restoreSession();
      if (user != null) {
        currentUser = user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      errorMessage = 'Erro ao restaurar sessão: $e';
      notifyListeners();
      return false;
    }
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
