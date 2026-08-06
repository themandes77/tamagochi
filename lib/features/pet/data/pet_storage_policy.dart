import 'dart:convert';

import 'package:flutter_application_1/core/persistence/json_storage_policy.dart';
import 'package:flutter_application_1/core/persistence/storage_migration.dart';
import 'package:flutter_application_1/features/pet/domain/pet_rules.dart';
import 'package:flutter_application_1/features/pet/domain/pet_state.dart';

class PetStoragePolicy implements JsonStoragePolicy {
  PetStoragePolicy({
    this.rules = const PetRules(),
    JsonMigrationRegistry? migrations,
  }) : migrations = migrations ?? JsonMigrationRegistry(currentVersion: 1);

  final PetRules rules;
  final JsonMigrationRegistry migrations;

  @override
  String get moduleKey => 'pet';

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
    PetState.fromJson(payload, rules: rules);
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

    double? findNeed(String key) {
      for (final candidate in ordered) {
        final mapValue = candidate.payload?[key];
        final fromMap = _validNeed(mapValue);
        if (fromMap != null) {
          return fromMap;
        }
        final fromRaw = _extractNumber(candidate.rawText, key);
        final validatedRaw = _validNeed(fromRaw);
        if (validatedRaw != null) {
          return validatedRaw;
        }
      }
      return null;
    }

    DateTime? findDate() {
      for (final candidate in ordered) {
        final mapValue = candidate.payload?['lastSavedAt'];
        final fromMap = _validDate(mapValue);
        if (fromMap != null) {
          return fromMap;
        }
        final fromRaw = _extractString(candidate.rawText, 'lastSavedAt');
        final validatedRaw = _validDate(fromRaw);
        if (validatedRaw != null) {
          return validatedRaw;
        }
      }
      return null;
    }

    final hunger = findNeed('hunger');
    final cleanliness = findNeed('cleanliness');
    final energy = findNeed('energy');
    final fun = findNeed('fun');

    final recoveredCount = <double?>[
      hunger,
      cleanliness,
      energy,
      fun,
    ].whereType<double>().length;
    if (recoveredCount == 0) {
      return null;
    }

    return PetState(
      hunger: hunger ?? rules.initialHunger,
      cleanliness: cleanliness ?? rules.initialCleanliness,
      energy: energy ?? rules.initialEnergy,
      fun: fun ?? rules.initialFun,
      lastSavedAt: findDate() ?? nowUtc,
      rules: rules,
    ).toJson();
  }

  double? _validNeed(Object? value) {
    if (value is! num || (value is double && !value.isFinite)) {
      return null;
    }
    final number = value.toDouble();
    if (number < rules.needMinimum || number > rules.needMaximum) {
      return null;
    }
    return number;
  }

  DateTime? _validDate(Object? value) {
    if (value is! String) {
      return null;
    }
    return DateTime.tryParse(value)?.toUtc();
  }

  num? _extractNumber(String raw, String key) {
    final escaped = RegExp.escape(key);
    final match = RegExp(
      '"$escaped"\\s*:\\s*(-?(?:\\d+\\.?\\d*|\\.\\d+)(?:[eE][+-]?\\d+)?)',
    ).firstMatch(raw);
    if (match == null) {
      return null;
    }
    return num.tryParse(match.group(1)!);
  }

  String? _extractString(String raw, String key) {
    final escaped = RegExp.escape(key);
    final match = RegExp('"$escaped"\\s*:\\s*"([^"]+)"').firstMatch(raw);
    if (match == null) {
      return null;
    }
    try {
      return jsonDecode('"${match.group(1)!}"') as String;
    } catch (_) {
      return null;
    }
  }
}
