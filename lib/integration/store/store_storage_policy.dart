import 'dart:convert';

import 'package:flutter_application_1/core/persistence/json_storage_policy.dart';
import 'package:flutter_application_1/core/persistence/storage_migration.dart';
import 'package:flutter_application_1/features/store/domain/store_snapshot.dart';

class StoreStoragePolicy implements JsonStoragePolicy {
  StoreStoragePolicy({JsonMigrationRegistry? migrations})
      : migrations = migrations ?? JsonMigrationRegistry(currentVersion: 1);

  final JsonMigrationRegistry migrations;

  @override
  String get moduleKey => 'store';

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
    final coins = payload['coins'];
    if (coins is! int || coins < 0) {
      throw const FormatException('coins debe ser un entero no negativo.');
    }

    final ownedItemIds = payload['ownedItemIds'];
    if (ownedItemIds is! List ||
        ownedItemIds.any((value) => value is! String || value.isEmpty)) {
      throw const FormatException(
        'ownedItemIds debe ser una lista de textos no vacíos.',
      );
    }

    _requireNonEmptyString(payload, 'equippedSkinId');
    _requireNonEmptyString(payload, 'equippedThemeId');
    StoreSnapshot.fromJson(payload);
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

    int? findCoins() {
      for (final candidate in ordered) {
        final mapped = candidate.payload?['coins'];
        if (mapped is int && mapped >= 0) {
          return mapped;
        }
        final raw = _extractInt(candidate.rawText, 'coins');
        if (raw != null && raw >= 0) {
          return raw;
        }
      }
      return null;
    }

    Set<String>? findOwnedItems() {
      for (final candidate in ordered) {
        final value = candidate.payload?['ownedItemIds'];
        if (value is List) {
          final items = value.whereType<String>().where((id) => id.isNotEmpty);
          final recovered = items.toSet();
          if (recovered.isNotEmpty) {
            return recovered;
          }
        }
      }
      return null;
    }

    String? findString(String key) {
      for (final candidate in ordered) {
        final mapped = candidate.payload?[key];
        if (mapped is String && mapped.isNotEmpty) {
          return mapped;
        }
        final raw = _extractString(candidate.rawText, key);
        if (raw != null && raw.isNotEmpty) {
          return raw;
        }
      }
      return null;
    }

    final coins = findCoins();
    final ownedItems = findOwnedItems();
    final equippedSkinId = findString('equippedSkinId');
    final equippedThemeId = findString('equippedThemeId');

    if (coins == null &&
        ownedItems == null &&
        equippedSkinId == null &&
        equippedThemeId == null) {
      return null;
    }

    final initial = StoreSnapshot.initial();
    final skinId = equippedSkinId ?? initial.equippedSkinId;
    final themeId = equippedThemeId ?? initial.equippedThemeId;
    final recoveredOwned = <String>{
      ...initial.ownedItemIds,
      ...?ownedItems,
      'skin_$skinId',
      'theme_$themeId',
    };

    return StoreSnapshot(
      coins: coins ?? initial.coins,
      ownedItemIds: recoveredOwned,
      equippedSkinId: skinId,
      equippedThemeId: themeId,
    ).toJson();
  }

  void _requireNonEmptyString(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('$key debe ser un texto no vacío.');
    }
  }

  int? _extractInt(String raw, String key) {
    final escaped = RegExp.escape(key);
    final match = RegExp('"$escaped"\\s*:\\s*(-?\\d+)').firstMatch(raw);
    return match == null ? null : int.tryParse(match.group(1)!);
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
