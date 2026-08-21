import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/coins.dart';
import 'package:flutter_application_1/features/customization/data/default_customizations.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_application_1/features/customization/domain/theme_option.dart';
import 'package:flutter_application_1/features/food/data/default_food_catalog.dart';
import 'package:flutter_application_1/features/food/domain/food_item.dart';
import 'package:flutter_application_1/features/store/data/default_catalog.dart';
import 'package:flutter_application_1/features/store/domain/shop_item.dart';
import 'package:flutter_application_1/features/store/domain/store_repository.dart';
import 'package:flutter_application_1/features/store/domain/store_snapshot.dart';

class StoreController extends ChangeNotifier {
  static const int maxFoodQuantityPerItem = 99;

  StoreController({
    required this.repository,
    this.catalog = defaultShopCatalog,
    this.outfits = NtiOutfit.values,
    this.themes = defaultThemeOptions,
    this.foodCatalog = defaultFoodCatalog,
    int initialCoins = 250,
  }) : _state = StoreSnapshot.initial(coins: initialCoins);

  final StoreRepository repository;
  final List<ShopItem> catalog;
  final List<NtiOutfit> outfits;
  final List<ThemeOption> themes;
  final List<FoodItem> foodCatalog;

  StoreSnapshot _state;
  bool _isReady = false;
  int? _lastPersistedCoinBalance;
  Future<void> _saveTail = Future<void>.value();
  Future<void> _mutationTail = Future<void>.value();

  bool get isReady => _isReady;

  /// Saldo monetario vivo y compartido con los minijuegos de Marco.
  ///
  /// StoreSnapshot conserva la representación durable del saldo, pero durante
  /// runtime no existe una segunda autoridad monetaria paralela.
  int get coins => CoinStore.instance.balance;

  String get equippedOutfitId => _state.equippedOutfitId;
  String get equippedThemeId => _state.equippedThemeId;
  UnmodifiableSetView<String> get ownedItemIds =>
      UnmodifiableSetView(_state.ownedItemIds);
  UnmodifiableMapView<String, int> get foodInventory =>
      UnmodifiableMapView(_state.foodInventory);

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

    CoinStore.instance.balance = _state.coins;
    _lastPersistedCoinBalance = _state.coins;
    _isReady = true;
    notifyListeners();
  }

  bool isOwned(ShopItem item) => _state.ownedItemIds.contains(item.id);

  bool isEquipped(ShopItem item) {
    return switch (item.kind) {
      ShopItemKind.outfit => item.customizationId == equippedOutfitId,
      ShopItemKind.theme => item.customizationId == equippedThemeId,
      ShopItemKind.food => false,
    };
  }

  List<ShopItem> itemsFor(ShopItemKind kind) {
    return List.unmodifiable(catalog.where((item) => item.kind == kind));
  }

  FoodItem? foodById(String id) {
    for (final food in foodCatalog) {
      if (food.id == id) {
        return food;
      }
    }
    return null;
  }

  int foodQuantity(String foodId) => _state.foodInventory[foodId] ?? 0;

  Future<FoodPurchaseResult> buyFood(String foodId) {
    return _enqueueMutation<FoodPurchaseResult>(() async {
      final food = foodById(foodId);
      if (food == null) {
        return FoodPurchaseResult.itemNotFound;
      }
      if (foodQuantity(food.id) >= maxFoodQuantityPerItem) {
        return FoodPurchaseResult.inventoryFull;
      }
      if (coins < food.price) {
        return FoodPurchaseResult.insufficientFunds;
      }

      final beforeBalance = coins;
      final beforeState = _state;
      if (!CoinStore.instance.trySpend(food.price)) {
        return FoodPurchaseResult.insufficientFunds;
      }

      final updatedInventory = Map<String, int>.from(_state.foodInventory);
      updatedInventory[food.id] =
          (foodQuantity(food.id) + 1)
              .clamp(0, maxFoodQuantityPerItem)
              .toInt();
      _state = _state.copyWith(
        coins: coins,
        foodInventory: updatedInventory,
      );

      try {
        await _saveAndNotify();
        return FoodPurchaseResult.success;
      } catch (_) {
        CoinStore.instance.balance = beforeBalance;
        _state = beforeState;
        rethrow;
      }
    });
  }

  StoreSnapshot snapshotForTransaction() {
    return _state.copyWith(coins: coins);
  }

  /// Actualiza únicamente la autoridad runtime desde una transacción ya
  /// comprometida en el journal. No escribe a disco.
  ///
  /// Esta API existe para la capa de integración Pet + Store: la
  /// materialización durable ocurre después, en la cola write-ahead.
  void applyTransactionSnapshot(StoreSnapshot snapshot) {
    _state = snapshot;
    CoinStore.instance.balance = snapshot.coins;
    notifyListeners();
  }

  StoreSnapshot snapshotAfterFoodConsumption(String foodId) {
    final current = foodQuantity(foodId);
    if (current <= 0) {
      throw StateError('No hay unidades disponibles de $foodId.');
    }
    final updatedInventory = Map<String, int>.from(_state.foodInventory);
    updatedInventory[foodId] = current - 1;
    return _state.copyWith(
      coins: coins,
      foodInventory: updatedInventory,
    );
  }

  Future<PurchaseResult> purchase(String itemId) {
    return _enqueueMutation<PurchaseResult>(() async {
      final item = _findItem(itemId);
      if (item == null) {
        return PurchaseResult.itemNotFound;
      }
      if (isOwned(item)) {
        return PurchaseResult.alreadyOwned;
      }
      if (coins < item.price) {
        return PurchaseResult.insufficientFunds;
      }

      final beforeBalance = coins;
      final beforeState = _state;
      if (!CoinStore.instance.trySpend(item.price)) {
        return PurchaseResult.insufficientFunds;
      }

      final updatedItems = {..._state.ownedItemIds, item.id};
      _state = _state.copyWith(
        coins: coins,
        ownedItemIds: updatedItems,
      );

      try {
        await _saveAndNotify();
        return PurchaseResult.success;
      } catch (_) {
        CoinStore.instance.balance = beforeBalance;
        _state = beforeState;
        rethrow;
      }
    });
  }

  Future<bool> equip(String itemId) {
    return _enqueueMutation<bool>(() async {
      final item = _findItem(itemId);
      if (item == null || !isOwned(item)) {
        return false;
      }

      final beforeState = _state;
      _state = switch (item.kind) {
        ShopItemKind.outfit => _state.copyWith(
          coins: coins,
          equippedOutfitId: item.customizationId,
        ),
        ShopItemKind.theme => _state.copyWith(
          coins: coins,
          equippedThemeId: item.customizationId,
        ),
        ShopItemKind.food => _state,
      };

      if (item.kind == ShopItemKind.food) {
        return false;
      }

      try {
        await _saveAndNotify();
        return true;
      } catch (_) {
        _state = beforeState;
        rethrow;
      }
    });
  }

  Future<void> addCoins(int amount) {
    if (amount <= 0) {
      return Future<void>.error(
        ArgumentError.value(amount, 'amount', 'Debe ser mayor que cero.'),
      );
    }

    return _enqueueMutation<void>(() async {
      final beforeBalance = coins;
      final beforeState = _state;
      CoinStore.instance.add(amount);
      _state = _state.copyWith(coins: coins);

      try {
        await _saveAndNotify();
      } catch (_) {
        CoinStore.instance.balance = beforeBalance;
        _state = beforeState;
        rethrow;
      }
    });
  }

  /// Persiste el saldo runtime compartido con los minijuegos.
  ///
  /// Se usa en Game Over, salida de minijuego, lifecycle y cierre normal. La
  /// operación entra a la misma cola de mutaciones del Store para que nunca se
  /// solape con una compra/equipamiento o con otro checkpoint monetario.
  Future<void> persistRuntimeCoins() {
    return _enqueueMutation<void>(() async {
      final currentBalance = coins;
      final stateAlreadyMatches = _state.coins == currentBalance;
      final balanceAlreadyPersisted =
          _lastPersistedCoinBalance == currentBalance;

      if (stateAlreadyMatches && balanceAlreadyPersisted) {
        await _saveTail;
        return;
      }

      _state = _state.copyWith(coins: currentBalance);
      await _saveAndNotify();
    });
  }

  /// Espera cualquier mutación y escritura ya programada sin crear una nueva.
  Future<void> flushPendingSaves() async {
    await _mutationTail;
    await _saveTail;
  }

  Future<void> _saveAndNotify() {
    final snapshot = _state.copyWith(coins: coins);
    _state = snapshot;

    final operation = _saveTail.then((_) => repository.save(snapshot));
    _saveTail = operation.catchError((_) {});

    return operation.then((_) {
      _lastPersistedCoinBalance = snapshot.coins;
      notifyListeners();
    });
  }

  Future<T> _enqueueMutation<T>(Future<T> Function() operation) {
    final completer = Completer<T>();

    _mutationTail = _mutationTail.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
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
