import 'dart:convert';

import 'package:flutter_application_1/app/settings/app_preferences.dart';
import 'package:flutter_application_1/core/persistence/json_storage_policy.dart';
import 'package:flutter_application_1/core/persistence/storage_migration.dart';

class AppPreferencesStoragePolicy implements JsonStoragePolicy {
  AppPreferencesStoragePolicy({JsonMigrationRegistry? migrations})
      : migrations = migrations ??
            JsonMigrationRegistry(
              currentVersion: 2,
              steps: <int, JsonMigrationStep>{
                1: _migrateV1ToV2,
              },
            );

  final JsonMigrationRegistry migrations;

  @override
  String get moduleKey => 'app_settings';

  @override
  int get currentSchemaVersion => migrations.currentVersion;

  @override
  Map<String, Object?> migrate({
    required int fromVersion,
    required Map<String, Object?> payload,
  }) {
    return migrations.migrate(fromVersion: fromVersion, payload: payload);
  }

  @override
  void validatePayload(Map<String, Object?> payload) {
    final preferences = AppPreferences.fromJson(payload);
    _validateVolume(preferences.musicVolume, 'musicVolume');
    _validateVolume(preferences.effectsVolume, 'effectsVolume');
  }

  @override
  Map<String, Object?>? recoverPartial({
    required List<JsonRecoveryCandidate> candidates,
    required DateTime nowUtc,
  }) {
    final ordered = <JsonRecoveryCandidate>[
      ...candidates.where((item) => item.source == JsonRecoverySource.current),
      ...candidates.where((item) => item.source == JsonRecoverySource.backup),
      ...candidates.where(
        (item) => item.source == JsonRecoverySource.temporary,
      ),
    ];

    double? findVolume(String key) {
      for (final candidate in ordered) {
        final mapped = candidate.payload?[key];
        if (mapped is num) {
          final value = mapped.toDouble();
          if (value.isFinite && value >= 0.0 && value <= 1.0) {
            return value;
          }
        }
        final raw = _extractNumber(candidate.rawText, key);
        if (raw != null && raw >= 0.0 && raw <= 1.0) {
          return raw;
        }
      }
      return null;
    }

    bool? findBool(String key) {
      for (final candidate in ordered) {
        final mapped = candidate.payload?[key];
        if (mapped is bool) {
          return mapped;
        }
        final raw = _extractBool(candidate.rawText, key);
        if (raw != null) {
          return raw;
        }
      }
      return null;
    }

    final musicVolume = findVolume('musicVolume');
    final effectsVolume = findVolume('effectsVolume');
    final vibrationEnabled = findBool('vibrationEnabled');

    if (musicVolume == null &&
        effectsVolume == null &&
        vibrationEnabled == null) {
      return null;
    }

    return AppPreferences.initial
        .copyWith(
          musicVolume: musicVolume,
          effectsVolume: effectsVolume,
          vibrationEnabled: vibrationEnabled,
        )
        .toJson();
  }

  void _validateVolume(double value, String key) {
    if (!value.isFinite || value < 0.0 || value > 1.0) {
      throw FormatException('$key debe estar entre 0.0 y 1.0.');
    }
  }

  double? _extractNumber(String raw, String key) {
    final escaped = RegExp.escape(key);
    final match = RegExp(
      '"$escaped"\\s*:\\s*(-?\\d+(?:\\.\\d+)?)',
    ).firstMatch(raw);
    return match == null ? null : double.tryParse(match.group(1)!);
  }

  bool? _extractBool(String raw, String key) {
    final escaped = RegExp.escape(key);
    final match = RegExp(
      '"$escaped"\\s*:\\s*(true|false)',
    ).firstMatch(raw);
    if (match == null) {
      return null;
    }
    return jsonDecode(match.group(1)!) as bool;
  }

  static Map<String, Object?> _migrateV1ToV2(Map<String, Object?> payload) {
    return <String, Object?>{
      ...payload,
      'notificationPromptDecision': NotificationPromptDecision.notAsked.name,
      'notificationLastVariants': <String, String>{},
    };
  }
}
