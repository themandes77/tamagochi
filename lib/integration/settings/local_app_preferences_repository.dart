import 'package:flutter_application_1/app/settings/app_preferences.dart';
import 'package:flutter_application_1/app/settings/app_preferences_repository.dart';
import 'package:flutter_application_1/core/persistence/json_file_storage.dart';
import 'package:flutter_application_1/core/persistence/storage_notice.dart';

class LocalAppPreferencesRepository implements AppPreferencesRepository {
  LocalAppPreferencesRepository({
    required this.storage,
    required this.noticeCenter,
  });

  final JsonFileStorage storage;
  final StorageNoticeCenter noticeCenter;

  @override
  Future<AppPreferences?> load() async {
    final result = await storage.read();
    switch (result.status) {
      case JsonStorageReadStatus.missing:
        return null;
      case JsonStorageReadStatus.resetRequired:
        const initial = AppPreferences.initial;
        await save(initial);
        noticeCenter.publish(
          const StorageNotice(
            code: 'app_settings_reset_after_failed_recovery',
            message: 'No fue posible recuperar parte de la configuración.',
            moduleKey: 'app_settings',
          ),
        );
        return initial;
      case JsonStorageReadStatus.current:
      case JsonStorageReadStatus.migrated:
      case JsonStorageReadStatus.temporaryRecovered:
      case JsonStorageReadStatus.backupRecovered:
      case JsonStorageReadStatus.partiallyRecovered:
        return AppPreferences.fromJson(result.payload!);
    }
  }

  @override
  Future<void> save(AppPreferences preferences) {
    return storage.write(preferences.toJson());
  }
}
