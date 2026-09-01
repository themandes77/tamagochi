import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app/settings/app_preferences.dart';
import 'package:flutter_application_1/integration/settings/app_preferences_storage_policy.dart';

void main() {
  test('schema 1 migra notificaciones a estado no preguntado', () {
    final policy = AppPreferencesStoragePolicy();
    final migrated = policy.migrate(
      fromVersion: 1,
      payload: const <String, Object?>{
        'musicVolume': 1.0,
        'effectsVolume': 0.7,
        'vibrationEnabled': true,
      },
    );

    final preferences = AppPreferences.fromJson(migrated);
    expect(
      preferences.notificationPromptDecision,
      NotificationPromptDecision.notAsked,
    );
    expect(preferences.notificationLastVariants, isEmpty);
  });
}
