import 'package:flutter_application_1/features/customization/data/default_customizations.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_application_1/features/food/data/default_food_catalog.dart';
import 'package:flutter_application_1/features/store/data/default_catalog.dart';
import 'package:flutter_application_1/features/store/domain/shop_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog IDs are unique and prices are valid', () {
    final ids = defaultShopCatalog.map((item) => item.id).toSet();

    expect(ids, hasLength(defaultShopCatalog.length));
    expect(defaultShopCatalog.every((item) => item.price >= 0), isTrue);
  });

  test('catalog items reference existing customizations', () {
    for (final item in defaultShopCatalog) {
      final exists = switch (item.kind) {
        ShopItemKind.outfit => NtiOutfit.values.any(
          (outfit) => outfit.id == item.customizationId,
        ),
        ShopItemKind.theme => defaultThemeOptions.any(
          (theme) => theme.id == item.customizationId,
        ),
        ShopItemKind.food => false,
      };

      expect(exists, isTrue, reason: 'Missing customization for ${item.id}');
    }
  });

  test('food catalog is extensible data with expected provisional values', () {
    expect(defaultFoodCatalog.map((item) => item.id).toSet(), hasLength(3));
    expect(defaultFoodCatalog[0].price, 1);
    expect(defaultFoodCatalog[0].satiety, 1);
    expect(defaultFoodCatalog[1].price, 3);
    expect(defaultFoodCatalog[1].satiety, 5);
    expect(defaultFoodCatalog[2].price, 5);
    expect(defaultFoodCatalog[2].satiety, 10);
    expect(
      defaultFoodCatalog.map((item) => item.assetPath).toList(),
      const <String?>[
        'assets/images/ui/food_hashtag.png',
        'assets/images/ui/food_like.png',
        'assets/images/ui/food_anniversary_cake.png',
      ],
    );
  });
}
