import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/domain/shop_item.dart';
import 'package:flutter_application_1/features/store/presentation/store_catalog_hint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses the generated star with dynamic catalog text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StoreCatalogHint(
            selectedKind: ShopItemKind.outfit,
            isStorePage: true,
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(
      find.byKey(const ValueKey('store_catalog_hint_star_asset')),
    );

    expect(
      (image.image as AssetImage).assetName,
      StoreCatalogHint.starAssetPath,
    );
    expect(
      find.text('Los trajes cambian la apariencia de tu NTI.'),
      findsOneWidget,
    );
  });
}
