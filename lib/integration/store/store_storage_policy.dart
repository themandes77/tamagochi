import 'dart:convert';

import 'package:flutter_application_1/core/persistence/json_storage_policy.dart';
import 'package:flutter_application_1/core/persistence/storage_migration.dart';
import 'package:flutter_application_1/features/store/domain/store_snapshot.dart';

class StoreStoragePolicy implements JsonStoragePolicy {
  StoreStoragePolicy({JsonMigrationRegistry? migrations})
      : migrations =
            migrations ??
            JsonMigrationRegistry(
              currentVersion: 3,
              steps: <int, JsonMigrationStep>{
                1: _migrateV1ToV2,
                2: _migrateV2ToV3,
              },
            );

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

    final ownedIds = ownedItemIds.whereType<String>().toSet();
    if (ownedIds.any((id) => !StoreSnapshot.supportedItemIds.contains(id))) {
      throw const FormatException(
        'ownedItemIds contiene personalizaciones no soportadas.',
      );
    }



    final foodInventory = payload['foodInventory'];
    if (foodInventory is! Map ||
        foodInventory.entries.any((entry) =>
            entry.key is! String ||
            (entry.key as String).isEmpty ||
            entry.value is! int ||
            (entry.value as int) < 0)) {
      throw const FormatException(
        'foodInventory debe ser un mapa de cantidades no negativas.',
      );
    }

    final outfitId = _requireNonEmptyString(payload, 'equippedOutfitId');
    if (!StoreSnapshot.supportedOutfitIds.contains(outfitId)) {
      throw const FormatException('equippedOutfitId no es válido.');
    }

    final themeId = _requireNonEmptyString(payload, 'equippedThemeId');
    if (!StoreSnapshot.supportedThemeIds.contains(themeId)) {
      throw const FormatException('equippedThemeId no es válido.');
    }

    if (!ownedIds.contains('outfit_$outfitId') ||
        !ownedIds.contains('theme_$themeId')) {
      throw const FormatException(
        'La personalización equipada debe pertenecer al inventario.',
      );
    }

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
          final recovered = value
              .whereType<String>()
              .where((id) => id.isNotEmpty)
              .toSet();
          if (recovered.isNotEmpty) {
            return recovered;
          }
        }
      }
      return null;
    }


    Map<String, int>? findFoodInventory() {
      for (final candidate in ordered) {
        final value = candidate.payload?['foodInventory'];
        if (value is Map) {
          final recovered = <String, int>{};
          for (final entry in value.entries) {
            final key = entry.key;
            final quantity = entry.value;
            if (key is String &&
                key.isNotEmpty &&
                quantity is int &&
                quantity >= 0) {
              recovered[key] = quantity;
            }
          }
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
    final equippedOutfitId = findString('equippedOutfitId');
    final equippedSkinId = findString('equippedSkinId');
    final equippedThemeId = findString('equippedThemeId');
    final foodInventory = findFoodInventory();

    if (coins == null &&
        ownedItems == null &&
        equippedOutfitId == null &&
        equippedSkinId == null &&
        equippedThemeId == null &&
        foodInventory == null) {
      return null;
    }

    final initial = StoreSnapshot.initial();
    final candidate = <String, Object?>{
      'coins': coins ?? initial.coins,
      'ownedItemIds': (ownedItems ?? initial.ownedItemIds).toList(),
      if (equippedOutfitId != null) 'equippedOutfitId': equippedOutfitId,
      if (equippedOutfitId == null && equippedSkinId != null)
        'equippedSkinId': equippedSkinId,
      if (equippedThemeId != null) 'equippedThemeId': equippedThemeId,
      'foodInventory': foodInventory ?? initial.foodInventory,
    };

    return StoreSnapshot.fromJson(candidate).toJson();
  }

  static Map<String, Object?> _migrateV1ToV2(
    Map<String, Object?> payload,
  ) {
    // `fromJson` distingue el Store legacy (equippedSkinId) de una posible
    // versión 1 ya integrada con outfits. Así la migración es segura para ambos
    // estados de desarrollo y siempre produce el esquema canónico v2.
    return StoreSnapshot.fromJson(payload).toJson();
  }


  static Map<String, Object?> _migrateV2ToV3(
    Map<String, Object?> payload,
  ) {
    // Schema 3 incorpora inventario apilable de comida. No hay regalo inicial:
    // tanto saves existentes como nuevas partidas empiezan con cantidades 0 si
    // el payload anterior no tenía inventario de comida.
    return StoreSnapshot.fromJson(<String, Object?>{
      ...payload,
      'foodInventory': payload['foodInventory'] ?? const <String, int>{},
    }).toJson();
  }

  String _requireNonEmptyString(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('$key debe ser un texto no vacío.');
    }
    return value;
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
