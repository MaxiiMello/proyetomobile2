import 'package:flutter/foundation.dart';

import '../models/database/repositories/user_repository.dart';

class SettingsViewModel extends ChangeNotifier {

  String selectedLanguage = 'Português (BR)';
  String locationSetting = 'Siempre activo';
  bool notificationsEnabled = true;
  String mapStorageSize = '2.5 GB';
  String appVersion = 'v1.0.0';
  bool darkModeEnabled = false;

  User? currentUser;
  bool isLoadingSettings = false;
  String? errorMessage;

  SettingsViewModel({User? user}) {
    currentUser = user;
    _loadSettings();
  }

  void _loadSettings() {
    // Cargar configuraciones por defecto
  }

  /// Cambiar notificaciones
  void toggleNotifications(bool value) {
    notificationsEnabled = value;
    notifyListeners();
  }

  /// Cambiar idioma
  void changeLanguage(String language) {
    selectedLanguage = language;
    notifyListeners();
  }

  /// Actualizar configuración de ubicación
  void updateLocationSetting(String setting) {
    locationSetting = setting;
    notifyListeners();
  }

  /// Cambiar tema oscuro
  void toggleDarkMode(bool value) {
    darkModeEnabled = value;
    notifyListeners();
  }

  /// Administrar descargas de mapas
  Future<void> manageDownloads() async {
    isLoadingSettings = true;
    errorMessage = null;
    notifyListeners();

    try {
      // TODO: Listar mapas descargados
      // TODO: Permitir borrar mapas
      await Future.delayed(const Duration(milliseconds: 500));

      isLoadingSettings = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoadingSettings = false;
      notifyListeners();
    }
  }

  /// Abrir política de privacidad
  Future<void> openPrivacyPolicy() async {
    // TODO: Abrir URL en navegador o mostrar en webview
    // TODO: URL: https://sinalverde.app/privacy
  }

  /// Abrir términos de servicio
  Future<void> openTermsOfService() async {
    // TODO: Abrir URL en navegador o mostrar en webview
    // TODO: URL: https://sinalverde.app/terms
  }

  /// Acerca de la app
  void showAboutApp() {
    // TODO: Mostrar información de la app
  }

  /// Cerrar sesión
  void logout() {
    currentUser = null;
    _loadSettings();
    notifyListeners();
  }
}
