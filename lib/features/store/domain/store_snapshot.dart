class StoreSnapshot {
  StoreSnapshot({
    required this.coins,
    required Set<String> ownedItemIds,
    required this.equippedOutfitId,
    required this.equippedThemeId,
  }) : ownedItemIds = Set.unmodifiable(ownedItemIds);

  factory StoreSnapshot.initial({int coins = 500}) {
    return StoreSnapshot(
      coins: coins,
      ownedItemIds: const {'outfit_original', 'theme_original'},
      equippedOutfitId: 'original',
      equippedThemeId: 'original',
    );
  }

  factory StoreSnapshot.fromJson(Map<String, Object?> json) {
    final ownedItems = json['ownedItemIds'];

    return StoreSnapshot(
      coins: json['coins'] as int? ?? 0,
      ownedItemIds: ownedItems is List
          ? ownedItems.whereType<String>().toSet()
          : const <String>{},
      equippedOutfitId:
          json['equippedOutfitId'] as String? ??
          json['equippedSkinId'] as String? ??
          'original',
      equippedThemeId: json['equippedThemeId'] as String? ?? 'original',
    );
  }

  final int coins;
  final Set<String> ownedItemIds;
  final String equippedOutfitId;
  final String equippedThemeId;

  StoreSnapshot copyWith({
    int? coins,
    Set<String>? ownedItemIds,
    String? equippedOutfitId,
    String? equippedThemeId,
  }) {
    return StoreSnapshot(
      coins: coins ?? this.coins,
      ownedItemIds: ownedItemIds ?? this.ownedItemIds,
      equippedOutfitId: equippedOutfitId ?? this.equippedOutfitId,
      equippedThemeId: equippedThemeId ?? this.equippedThemeId,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'coins': coins,
      'ownedItemIds': ownedItemIds.toList()..sort(),
      'equippedOutfitId': equippedOutfitId,
      'equippedThemeId': equippedThemeId,
    };
  }
}
