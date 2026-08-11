class StoreSnapshot {
  StoreSnapshot({
    required this.coins,
    required Set<String> ownedItemIds,
    required this.equippedOutfitId,
    required this.equippedThemeId,
    required Map<String, int> foodInventory,
  }) : ownedItemIds = Set.unmodifiable(ownedItemIds),
       foodInventory = Map.unmodifiable(foodInventory);

  static const Set<String> supportedOutfitIds = <String>{
    'original',
    'anniversary',
    'techno',
    'adventurer',
  };

  static const Set<String> supportedThemeIds = <String>{
    'original',
    'normal',
    'techno',
    'adventure',
  };

  static const Set<String> supportedItemIds = <String>{
    'outfit_original',
    'outfit_anniversary',
    'outfit_techno',
    'outfit_adventurer',
    'theme_original',
    'theme_normal',
    'theme_techno',
    'theme_adventure',
  };

  static const Set<String> initialFoodIds = <String>{
    'food_1',
    'food_2',
    'food_3',
  };

  factory StoreSnapshot.initial({int coins = 500}) {
    return StoreSnapshot(
      coins: coins,
      ownedItemIds: const {'outfit_original', 'theme_original'},
      equippedOutfitId: 'original',
      equippedThemeId: 'original',
      foodInventory: const <String, int>{
        'food_1': 0,
        'food_2': 0,
        'food_3': 0,
      },
    );
  }

  /// Normaliza tanto el esquema actual como el Store antiguo basado en slimes.
  ///
  /// El esquema legacy se reconoce por `equippedSkinId`. En ese caso cualquier
  /// skin anterior se retira del inventario y se equipa el outfit Original.
  /// El antiguo `theme_normal` representaba el fondo original de la app, por lo
  /// que se migra a `theme_original`; Techno se conserva.
  ///
  /// foodInventory es apilable y tolera IDs adicionales para que futuras
  /// comidas puedan incorporarse sin reescribir la lógica de persistencia.
  factory StoreSnapshot.fromJson(Map<String, Object?> json) {
    final rawCoins = json['coins'];
    final coins = rawCoins is int && rawCoins >= 0 ? rawCoins : 0;

    final rawOwned = json['ownedItemIds'];
    final rawOwnedItems = rawOwned is List
        ? rawOwned.whereType<String>().where((id) => id.isNotEmpty).toSet()
        : <String>{};

    final hasCurrentOutfitField = json['equippedOutfitId'] is String;
    final legacySkinId = json['equippedSkinId'];
    final isLegacy = !hasCurrentOutfitField && legacySkinId is String;

    final rawOutfitId = json['equippedOutfitId'];
    final normalizedOutfitId = isLegacy
        ? 'original'
        : _supportedOrFallback(
            rawOutfitId,
            supportedOutfitIds,
            fallback: 'original',
          );

    final rawThemeId = json['equippedThemeId'];
    final normalizedThemeId = isLegacy
        ? _legacyThemeId(rawThemeId)
        : _supportedOrFallback(
            rawThemeId,
            supportedThemeIds,
            fallback: 'original',
          );

    final normalizedOwned = <String>{
      'outfit_original',
      'theme_original',
    };

    for (final itemId in rawOwnedItems) {
      if (isLegacy) {
        final migrated = _legacyItemId(itemId);
        if (migrated != null) {
          normalizedOwned.add(migrated);
        }
      } else if (supportedItemIds.contains(itemId)) {
        normalizedOwned.add(itemId);
      }
    }

    normalizedOwned
      ..add('outfit_$normalizedOutfitId')
      ..add('theme_$normalizedThemeId');

    final normalizedFoodInventory = <String, int>{
      for (final id in initialFoodIds) id: 0,
    };
    final rawFoodInventory = json['foodInventory'];
    if (rawFoodInventory is Map) {
      for (final entry in rawFoodInventory.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && key.isNotEmpty && value is int && value >= 0) {
          normalizedFoodInventory[key] = value;
        }
      }
    }

    return StoreSnapshot(
      coins: coins,
      ownedItemIds: normalizedOwned,
      equippedOutfitId: normalizedOutfitId,
      equippedThemeId: normalizedThemeId,
      foodInventory: normalizedFoodInventory,
    );
  }

  final int coins;
  final Set<String> ownedItemIds;
  final String equippedOutfitId;
  final String equippedThemeId;
  final Map<String, int> foodInventory;

  StoreSnapshot copyWith({
    int? coins,
    Set<String>? ownedItemIds,
    String? equippedOutfitId,
    String? equippedThemeId,
    Map<String, int>? foodInventory,
  }) {
    return StoreSnapshot(
      coins: coins ?? this.coins,
      ownedItemIds: ownedItemIds ?? this.ownedItemIds,
      equippedOutfitId: equippedOutfitId ?? this.equippedOutfitId,
      equippedThemeId: equippedThemeId ?? this.equippedThemeId,
      foodInventory: foodInventory ?? this.foodInventory,
    );
  }

  Map<String, Object?> toJson() {
    final sortedFoodIds = foodInventory.keys.toList()..sort();
    return <String, Object?>{
      'coins': coins,
      'ownedItemIds': ownedItemIds.toList()..sort(),
      'equippedOutfitId': equippedOutfitId,
      'equippedThemeId': equippedThemeId,
      'foodInventory': <String, int>{
        for (final id in sortedFoodIds) id: foodInventory[id]!,
      },
    };
  }

  static String _supportedOrFallback(
    Object? value,
    Set<String> supported, {
    required String fallback,
  }) {
    return value is String && supported.contains(value) ? value : fallback;
  }

  static String _legacyThemeId(Object? value) {
    if (value == 'techno') {
      return 'techno';
    }
    // En el Store anterior `normal` era el fondo base que ahora se llama
    // Original. Cualquier valor desconocido también cae al tema seguro.
    return 'original';
  }

  static String? _legacyItemId(String itemId) {
    return switch (itemId) {
      'theme_techno' => 'theme_techno',
      'theme_normal' => 'theme_original',
      // Las skins antiguas se retiran por decisión de producto. No se mapean a
      // outfits comprados; Original se garantiza por separado.
      _ => supportedItemIds.contains(itemId) ? itemId : null,
    };
  }
}
