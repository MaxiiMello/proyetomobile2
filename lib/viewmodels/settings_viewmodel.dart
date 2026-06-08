import 'package:flutter/foundation.dart';
import '../models/database/repositories/user_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  String selectedLanguage = 'Português (BR)';
  String locationSetting = 'Sempre ativo';
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
  }

  void toggleNotifications(bool value) {
    notificationsEnabled = value;
    notifyListeners();
  }

  void changeLanguage(String language) {
    selectedLanguage = language;
    notifyListeners();
  }

  void updateLocationSetting(String setting) {
    locationSetting = setting;
    notifyListeners();
  }

  void toggleDarkMode(bool value) {
    darkModeEnabled = value;
    notifyListeners();
  }

  Future<void> manageDownloads() async {
    isLoadingSettings = true;
    errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      isLoadingSettings = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoadingSettings = false;
      notifyListeners();
    }
  }

  Future<void> openPrivacyPolicy() async {
  }

  Future<void> openTermsOfService() async {
  }

  void showAboutApp() {
  }

  void logout() {
    currentUser = null;
    _loadSettings();
    notifyListeners();
  }
}