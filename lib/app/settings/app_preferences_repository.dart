import 'package:flutter_application_1/app/settings/app_preferences.dart';

abstract interface class AppPreferencesRepository {
  Future<AppPreferences?> load();

  Future<void> save(AppPreferences preferences);
}
