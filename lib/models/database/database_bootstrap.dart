import 'repositories/app_settings_repository.dart';
import 'app_database.dart';

class DatabaseBootstrap {
  static Future<void> initialize() async {
    await AppDatabase.instance.database;
    await AppSettingsRepository().ensureDefaultSettings();
  }
}
