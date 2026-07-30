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
      repository = InMemoryStoreRepository();
      controller = StoreController(repository: repository);
      await controller.initialize();
    });

    test('starts with the free skin and theme equipped', () {
      expect(controller.coins, 200);
      expect(controller.equippedSkinId, 'purple');
      expect(controller.equippedThemeId, 'original');
      expect(
        controller.ownedItemIds,
        containsAll(['skin_purple', 'theme_original']),
      );
    });

    test('purchases an item and deducts its price', () async {
      final result = await controller.purchase('skin_blue');

      expect(result, PurchaseResult.success);
      expect(controller.coins, 150);
      expect(controller.ownedItemIds, contains('skin_blue'));
    });

    test('does not charge twice for the same item', () async {
      await controller.purchase('skin_blue');
      final result = await controller.purchase('skin_blue');

      expect(result, PurchaseResult.alreadyOwned);
      expect(controller.coins, 150);
    });

    test('rejects a purchase without enough coins', () async {
      repository = InMemoryStoreRepository(
        initialSnapshot: StoreSnapshot.initial(coins: 10),
      );
      controller = StoreController(repository: repository);
      await controller.initialize();

      final result = await controller.purchase('skin_blue');

      expect(result, PurchaseResult.insufficientFunds);
      expect(controller.coins, 10);
      expect(controller.ownedItemIds, isNot(contains('skin_blue')));
    });

    test('equips only owned items', () async {
      expect(await controller.equip('skin_blue'), isFalse);

      await controller.purchase('skin_blue');

      expect(await controller.equip('skin_blue'), isTrue);
      expect(controller.equippedSkinId, 'blue');
    });

    test(
      'persists purchases and equipped items through the repository',
      () async {
        await controller.purchase('skin_blue');
        await controller.equip('skin_blue');

        final restored = StoreController(repository: repository);
        await restored.initialize();

        expect(restored.coins, 150);
        expect(restored.equippedSkinId, 'blue');
        expect(restored.ownedItemIds, contains('skin_blue'));
      },
    );

    test('adds rewards from a minigame', () async {
      await controller.addCoins(25);

      expect(controller.coins, 225);
    });

    test('rejects invalid rewards', () {
      expect(() => controller.addCoins(0), throwsArgumentError);
    });
  });
}
