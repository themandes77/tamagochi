import 'package:flutter_application_1/features/store/domain/store_snapshot.dart';
import 'package:flutter_application_1/integration/store/store_storage_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Store schema v3', () {
    test('migrates legacy slime state without losing coins', () {
      final policy = StoreStoragePolicy();

      final migrated = policy.migrate(
        fromVersion: 1,
        payload: <String, Object?>{
          'coins': 135,
          'ownedItemIds': <String>[
            'skin_purple',
            'skin_blue',
            'theme_normal',
            'theme_techno',
          ],
          'equippedSkinId': 'blue',
          'equippedThemeId': 'normal',
        },
      );

      expect(migrated['coins'], 135);
      expect(migrated['equippedOutfitId'], 'original');
      expect(migrated['equippedThemeId'], 'original');
      expect(
        (migrated['ownedItemIds'] as List).toSet(),
        containsAll(<String>{
          'outfit_original',
          'theme_original',
          'theme_techno',
        }),
      );
      expect(
        (migrated['ownedItemIds'] as List).where(
          (id) => (id as String).startsWith('skin_'),
        ),
        isEmpty,
      );
      expect(migrated['foodInventory'], <String, int>{
        'food_1': 0,
        'food_2': 0,
        'food_3': 0,
      });
      policy.validatePayload(migrated);
    });

    test('keeps a phase-1 outfit payload while upgrading schema', () {
      final policy = StoreStoragePolicy();

      final migrated = policy.migrate(
        fromVersion: 1,
        payload: <String, Object?>{
          'coins': 420,
          'ownedItemIds': <String>[
            'outfit_original',
            'outfit_techno',
            'theme_original',
            'theme_normal',
          ],
          'equippedOutfitId': 'techno',
          'equippedThemeId': 'normal',
        },
      );

      expect(StoreSnapshot.fromJson(migrated).equippedOutfitId, 'techno');
      expect(StoreSnapshot.fromJson(migrated).equippedThemeId, 'normal');
      expect(migrated['coins'], 420);
      expect(StoreSnapshot.fromJson(migrated).foodInventory['food_1'], 0);
      policy.validatePayload(migrated);
    });

    test('migrates schema 2 to an empty stackable food inventory', () {
      final policy = StoreStoragePolicy();
      final v2 = <String, Object?>{
        'coins': 250,
        'ownedItemIds': <String>['outfit_original', 'theme_original'],
        'equippedOutfitId': 'original',
        'equippedThemeId': 'original',
      };

      final migrated = policy.migrate(fromVersion: 2, payload: v2);
      final snapshot = StoreSnapshot.fromJson(migrated);

      expect(snapshot.coins, 250);
      expect(snapshot.foodInventory, <String, int>{
        'food_1': 0,
        'food_2': 0,
        'food_3': 0,
      });
      policy.validatePayload(migrated);
    });

    test('preserves food quantities already present in schema 3 payloads', () {
      final snapshot = StoreSnapshot.fromJson(<String, Object?>{
        'coins': 88,
        'ownedItemIds': <String>['outfit_original', 'theme_original'],
        'equippedOutfitId': 'original',
        'equippedThemeId': 'original',
        'foodInventory': <String, int>{
          'food_1': 4,
          'food_2': 1,
          'food_3': 0,
        },
      });

      expect(snapshot.foodInventory['food_1'], 4);
      expect(snapshot.foodInventory['food_2'], 1);
      expect(snapshot.foodInventory['food_3'], 0);
    });

    test('normalizes invalid customization fields independently', () {
      final snapshot = StoreSnapshot.fromJson(<String, Object?>{
        'coins': 88,
        'ownedItemIds': <String>[
          'outfit_original',
          'outfit_unknown',
          'theme_original',
        ],
        'equippedOutfitId': 'unknown',
        'equippedThemeId': 'missing',
        'foodInventory': <String, int>{'food_1': 2},
      });

      expect(snapshot.coins, 88);
      expect(snapshot.equippedOutfitId, 'original');
      expect(snapshot.equippedThemeId, 'original');
      expect(snapshot.ownedItemIds, contains('outfit_original'));
      expect(snapshot.ownedItemIds, contains('theme_original'));
      expect(snapshot.ownedItemIds, isNot(contains('outfit_unknown')));
      expect(snapshot.foodInventory['food_1'], 2);
    });
  });
}
