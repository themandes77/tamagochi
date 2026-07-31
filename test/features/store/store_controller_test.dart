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

    test('starts with the free outfit and theme equipped', () {
      expect(controller.coins, 200);
      expect(controller.equippedOutfitId, 'original');
      expect(controller.equippedThemeId, 'original');
      expect(
        controller.ownedItemIds,
        containsAll(['outfit_original', 'theme_original']),
      );
    });

    test('purchases an item and deducts its price', () async {
      final result = await controller.purchase('outfit_anniversary');

      expect(result, PurchaseResult.success);
      expect(controller.coins, 100);
      expect(controller.ownedItemIds, contains('outfit_anniversary'));
    });

    test('does not charge twice for the same item', () async {
      await controller.purchase('outfit_anniversary');
      final result = await controller.purchase('outfit_anniversary');

      expect(result, PurchaseResult.alreadyOwned);
      expect(controller.coins, 100);
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
      expect(controller.selectedOutfit.id, 'anniversary');
    });

    test('equips an owned room background', () async {
      await controller.purchase('theme_normal');

      expect(await controller.equip('theme_normal'), isTrue);
      expect(controller.equippedThemeId, 'normal');
      expect(controller.selectedTheme.id, 'normal');
    });

    test(
      'persists purchases and equipped items through the repository',
      () async {
        await controller.purchase('outfit_anniversary');
        await controller.equip('outfit_anniversary');

        final restored = StoreController(repository: repository);
        await restored.initialize();

        expect(restored.coins, 100);
        expect(restored.equippedOutfitId, 'anniversary');
        expect(restored.ownedItemIds, contains('outfit_anniversary'));
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
