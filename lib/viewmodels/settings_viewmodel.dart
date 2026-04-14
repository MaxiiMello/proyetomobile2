import 'package:flutter/foundation.dart';

class SettingsViewModel extends ChangeNotifier {
  String selectedLanguage = 'Português (BR)';
  String locationSetting = 'Sempre ativo';
  bool notificationsEnabled = true;
  String mapStorageSize = '2.5 GB';
  String appVersion = 'v1.0.0';

  void toggleNotifications(bool value) {
    notificationsEnabled = value;
    // TODO: Persistir configuração no banco de dados
    notifyListeners();
  }

  void changeLanguage(String language) {
    selectedLanguage = language;
    // TODO: Aplicar no aplicativo
    notifyListeners();
  }

  void updateLocationSetting(String setting) {
    locationSetting = setting;
    // TODO: Persistir configuração
    notifyListeners();
  }

  Future<void> manageDownloads() async {
    // TODO: Implementar gerenciador de downloads
  }

  void openPrivacyPolicy() {
    // TODO: Abrir politica de privacidade
  }

  void openTermsOfService() {
    // TODO: Abrir termos de serviço
  }
}
