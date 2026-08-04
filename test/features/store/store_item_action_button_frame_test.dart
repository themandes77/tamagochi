import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/presentation/store_item_action_button_frame.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses the generated price and status button backgrounds', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            SizedBox(
              width: 180,
              height: 40,
              child: StoreItemActionButtonFrame(
                isPrice: true,
                child: Text('100'),
              ),
            ),
            SizedBox(
              width: 180,
              height: 40,
              child: StoreItemActionButtonFrame(
                isPrice: false,
                child: Text('Equipado'),
              ),
            ),
          ],
        ),
      ),
    );

    final priceImage = tester.widget<Image>(
      find.byKey(const ValueKey('store_price_button_frame_asset')),
    );
    final statusImage = tester.widget<Image>(
      find.byKey(const ValueKey('store_status_button_frame_asset')),
    );

    expect(
      (priceImage.image as AssetImage).assetName,
      StoreItemActionButtonFrame.priceAssetPath,
    );
    expect(
      (statusImage.image as AssetImage).assetName,
      StoreItemActionButtonFrame.statusAssetPath,
    );
  });
}
