import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/presentation/store_showcase_room.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses the generated store showcase room', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StoreShowcaseRoom())),
    );

    final image = tester.widget<Image>(
      find.byKey(const ValueKey('store_showcase_room_asset')),
    );

    expect((image.image as AssetImage).assetName, StoreShowcaseRoom.assetPath);
  });
}
