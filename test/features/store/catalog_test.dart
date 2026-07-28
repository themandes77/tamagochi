import 'package:flutter_application_1/features/customization/data/default_customizations.dart';
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
        ShopItemKind.skin => defaultPetSkins.any(
          (skin) => skin.id == item.customizationId,
        ),
        ShopItemKind.theme => defaultThemeOptions.any(
          (theme) => theme.id == item.customizationId,
        ),
      };

      expect(exists, isTrue, reason: 'Missing customization for ${item.id}');
    }
  });
}
