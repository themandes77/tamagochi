class StoreSnapshot {
  StoreSnapshot({
    required this.coins,
    required Set<String> ownedItemIds,
    required this.equippedSkinId,
    required this.equippedThemeId,
  }) : ownedItemIds = Set.unmodifiable(ownedItemIds);

  factory StoreSnapshot.initial({int coins = 200}) {
    return StoreSnapshot(
      coins: coins,
      ownedItemIds: const {'skin_purple', 'theme_original'},
      equippedSkinId: 'purple',
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
      equippedSkinId: json['equippedSkinId'] as String? ?? 'purple',
      equippedThemeId: json['equippedThemeId'] as String? ?? 'original',
    );
  }

  final int coins;
  final Set<String> ownedItemIds;
  final String equippedSkinId;
  final String equippedThemeId;

  StoreSnapshot copyWith({
    int? coins,
    Set<String>? ownedItemIds,
    String? equippedSkinId,
    String? equippedThemeId,
  }) {
    return StoreSnapshot(
      coins: coins ?? this.coins,
      ownedItemIds: ownedItemIds ?? this.ownedItemIds,
      equippedSkinId: equippedSkinId ?? this.equippedSkinId,
      equippedThemeId: equippedThemeId ?? this.equippedThemeId,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'coins': coins,
      'ownedItemIds': ownedItemIds.toList()..sort(),
      'equippedSkinId': equippedSkinId,
      'equippedThemeId': equippedThemeId,
    };
  }
}
