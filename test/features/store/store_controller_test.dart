import 'package:flutter_application_1/coins.dart';
import 'package:flutter_application_1/features/food/domain/food_item.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/data/in_memory_store_repository.dart';
import 'package:flutter_application_1/features/store/domain/shop_item.dart';
import 'package:flutter_application_1/features/store/domain/store_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoreController', () {
    late InMemoryStoreRepository repository;
    late StoreController controller;

    setUp(() async {
      CoinStore.instance.balance = 0;
      repository = InMemoryStoreRepository();
      controller = StoreController(repository: repository);
      await controller.initialize();
    });

    test('starts with Original outfit and theme equipped', () {
      expect(controller.coins, 500);
      expect(controller.equippedOutfitId, 'original');
      expect(controller.equippedThemeId, 'original');
      expect(
        controller.ownedItemIds,
        containsAll(['outfit_original', 'theme_original']),
      );
    });

    test('purchases an item using the shared CoinStore balance', () async {
      final result = await controller.purchase('outfit_anniversary');

      expect(result, PurchaseResult.success);
      expect(controller.coins, 400);
      expect(CoinStore.instance.balance, 400);
      expect(controller.ownedItemIds, contains('outfit_anniversary'));
    });

    test('does not charge twice for the same item', () async {
      await controller.purchase('outfit_anniversary');
      final result = await controller.purchase('outfit_anniversary');

      expect(result, PurchaseResult.alreadyOwned);
      expect(controller.coins, 400);
    });

    test('rejects a purchase without enough coins', () async {
      repository = InMemoryStoreRepository(
        initialSnapshot: StoreSnapshot.initial(coins: 10),
      );
      controller = StoreController(repository: repository);
      await controller.initialize();

      final result = await controller.purchase('outfit_anniversary');

      expect(result, PurchaseResult.insufficientFunds);
      expect(controller.coins, 10);
      expect(controller.ownedItemIds, isNot(contains('outfit_anniversary')));
    });

    test('equips only owned items', () async {
      expect(await controller.equip('outfit_anniversary'), isFalse);

      await controller.purchase('outfit_anniversary');

      expect(await controller.equip('outfit_anniversary'), isTrue);
      expect(controller.equippedOutfitId, 'anniversary');
    });

    test('persists purchases and equipped items through repository', () async {
      await controller.purchase('outfit_anniversary');
      await controller.equip('outfit_anniversary');

      final restored = StoreController(repository: repository);
      await restored.initialize();

      expect(restored.coins, 400);
      expect(restored.equippedOutfitId, 'anniversary');
      expect(restored.ownedItemIds, contains('outfit_anniversary'));
    });

    test('persists coins added directly by a minigame', () async {
      CoinStore.instance.add(7);
      await controller.persistRuntimeCoins();

      final restored = StoreController(repository: repository);
      await restored.initialize();

      expect(restored.coins, 507);
    });

    test('adds rewards through the Store API to the same CoinStore', () async {
      await controller.addCoins(25);

      expect(controller.coins, 525);
      expect(CoinStore.instance.balance, 525);
    });

    test('starts with an empty food inventory', () {
      expect(controller.foodQuantity('food_1'), 0);
      expect(controller.foodQuantity('food_2'), 0);
      expect(controller.foodQuantity('food_3'), 0);
    });

    test('buys one food unit per tap and persists it immediately', () async {
      final result = await controller.buyFood('food_2');

      expect(result, FoodPurchaseResult.success);
      expect(controller.coins, 497);
      expect(controller.foodQuantity('food_2'), 1);

      final restored = StoreController(repository: repository);
      await restored.initialize();
      expect(restored.coins, 497);
      expect(restored.foodQuantity('food_2'), 1);
    });

    test(
      'food can be purchased repeatedly while funds are sufficient',
      () async {
        await controller.buyFood('food_1');
        await controller.buyFood('food_1');
        await controller.buyFood('food_1');

        expect(controller.coins, 497);
        expect(controller.foodQuantity('food_1'), 3);
      },
    );

    test(
      'food inventory caps each item at 99 without charging extra',
      () async {
        final initial = StoreSnapshot.initial(coins: 500).copyWith(
          foodInventory: const <String, int>{
            'food_1': 98,
            'food_2': 0,
            'food_3': 0,
          },
        );
        repository = InMemoryStoreRepository(initialSnapshot: initial);
        controller = StoreController(repository: repository);
        await controller.initialize();

        expect(await controller.buyFood('food_1'), FoodPurchaseResult.success);
        expect(controller.foodQuantity('food_1'), 99);
        expect(controller.coins, 499);

        expect(
          await controller.buyFood('food_1'),
          FoodPurchaseResult.inventoryFull,
        );
        expect(controller.foodQuantity('food_1'), 99);
        expect(controller.coins, 499);
      },
    );

    test('rejects invalid rewards', () async {
      await expectLater(controller.addCoins(0), throwsArgumentError);
    });
  });
}
