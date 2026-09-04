import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/presentation/store_item_card_frame.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses the generated item card behind dynamic content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 220,
            child: StoreItemCardFrame(
              selected: false,
              child: Text('Artículo dinámico'),
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(
      find.byKey(const ValueKey('store_item_card_frame_asset')),
    );
    final provider = image.image as AssetImage;

    expect(provider.assetName, StoreItemCardFrame.assetPath);
    expect(find.text('Artículo dinámico'), findsOneWidget);
  });
}
