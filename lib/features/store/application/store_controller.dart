import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/features/customization/data/default_customizations.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_application_1/features/customization/domain/theme_option.dart';
import 'package:flutter_application_1/features/store/data/default_catalog.dart';
import 'package:flutter_application_1/features/store/domain/shop_item.dart';
import 'package:flutter_application_1/features/store/domain/store_repository.dart';
import 'package:flutter_application_1/features/store/domain/store_snapshot.dart';

class StoreController extends ChangeNotifier {
  StoreController({
    required this.repository,
    this.catalog = defaultShopCatalog,
    this.outfits = NtiOutfit.values,
    this.themes = defaultThemeOptions,
    int initialCoins = 200,
  }) : _state = StoreSnapshot.initial(coins: initialCoins);

  final StoreRepository repository;
  final List<ShopItem> catalog;
  final List<NtiOutfit> outfits;
  final List<ThemeOption> themes;

  StoreSnapshot _state;
  bool _isReady = false;

  bool get isReady => _isReady;
  int get coins => _state.coins;
  String get equippedOutfitId => _state.equippedOutfitId;
  String get equippedThemeId => _state.equippedThemeId;
  UnmodifiableSetView<String> get ownedItemIds =>
      UnmodifiableSetView(_state.ownedItemIds);

  NtiOutfit get selectedOutfit =>
      _findOutfit(equippedOutfitId) ?? outfits.first;

  ThemeOption get selectedTheme => _findTheme(equippedThemeId) ?? themes.first;

  Future<void> initialize() async {
    final savedState = await repository.load();
    if (savedState != null) {
      _state = savedState;
    } else {
      await repository.save(_state);
    }
    _isReady = true;
    notifyListeners();
  }

  bool isOwned(ShopItem item) => _state.ownedItemIds.contains(item.id);

  bool isEquipped(ShopItem item) {
    return switch (item.kind) {
      ShopItemKind.outfit => item.customizationId == equippedOutfitId,
      ShopItemKind.theme => item.customizationId == equippedThemeId,
    };
  }

  List<ShopItem> itemsFor(ShopItemKind kind) {
    return List.unmodifiable(catalog.where((item) => item.kind == kind));
  }

  Future<PurchaseResult> purchase(String itemId) async {
    final item = _findItem(itemId);
    if (item == null) {
      return PurchaseResult.itemNotFound;
    }
    if (isOwned(item)) {
      return PurchaseResult.alreadyOwned;
    }
    if (_state.coins < item.price) {
      return PurchaseResult.insufficientFunds;
    }

    final updatedItems = {..._state.ownedItemIds, item.id};
    _state = _state.copyWith(
      coins: _state.coins - item.price,
      ownedItemIds: updatedItems,
    );
    await _saveAndNotify();
    return PurchaseResult.success;
  }

  Future<bool> equip(String itemId) async {
    final item = _findItem(itemId);
    if (item == null || !isOwned(item)) {
      return false;
    }

    _state = switch (item.kind) {
      ShopItemKind.outfit => _state.copyWith(
        equippedOutfitId: item.customizationId,
      ),
      ShopItemKind.theme => _state.copyWith(
        equippedThemeId: item.customizationId,
      ),
    };
    await _saveAndNotify();
    return true;
  }

  Future<void> addCoins(int amount) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Debe ser mayor que cero.');
    }
    _state = _state.copyWith(coins: _state.coins + amount);
    await _saveAndNotify();
  }

  Future<void> _saveAndNotify() async {
    await repository.save(_state);
    notifyListeners();
  }

  ShopItem? _findItem(String id) {
    for (final item in catalog) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  NtiOutfit? _findOutfit(String id) {
    for (final outfit in outfits) {
      if (outfit.id == id) {
        return outfit;
      }
    }
    return null;
  }

  ThemeOption? _findTheme(String id) {
    for (final theme in themes) {
      if (theme.id == id) {
        return theme;
      }
    }
    return null;
  }
}
