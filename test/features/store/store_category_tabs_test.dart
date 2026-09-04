import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/domain/shop_item.dart';
import 'package:flutter_application_1/features/store/presentation/store_category_tabs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('category tabs use selected and inactive generated assets', (
    tester,
  ) async {
    var selectedKind = ShopItemKind.outfit;

    await tester.pumpWidget(
      MaterialApp(
        home: StoreCategoryTabs(
          selectedKind: selectedKind,
          onSelected: (kind) => selectedKind = kind,
        ),
      ),
    );

    final outfitsBackground = tester.widget<Image>(
      find.byKey(const ValueKey('category_tab_trajes_background')),
    );
    final themesBackground = tester.widget<Image>(
      find.byKey(const ValueKey('category_tab_fondos_background')),
    );

    expect(
      (outfitsBackground.image as AssetImage).assetName,
      'assets/images/ui/category_tab_selected_v1.png',
    );
    expect(
      (themesBackground.image as AssetImage).assetName,
      'assets/images/ui/category_tab_inactive_v1.png',
    );

    await tester.tap(find.byKey(const ValueKey('category_fondos')));
    expect(selectedKind, ShopItemKind.theme);
  });
}
