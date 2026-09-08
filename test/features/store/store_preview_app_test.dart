import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/data/in_memory_store_repository.dart';
import 'package:flutter_application_1/features/store/domain/shop_item.dart';
import 'package:flutter_application_1/features/store/presentation/store_preview_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('store exposes only outfits and themes', (tester) async {
    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();

    await tester.pumpWidget(StorePreviewApp(controller: controller));
    await tester.pump();

    expect(find.text('250'), findsWidgets);
    expect(find.text('TRAJES'), findsOneWidget);
    expect(find.text('FONDOS'), findsOneWidget);
    expect(find.text('COMIDA'), findsNothing);
  });

  testWidgets('legacy food initial kind falls back to outfits', (tester) async {
    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        theme: storeThemeFrom(controller.selectedTheme),
        home: StoreScreen(
          controller: controller,
          initialKind: ShopItemKind.food,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('category_trajes')), findsOneWidget);
    expect(find.byKey(const ValueKey('category_fondos')), findsOneWidget);
    expect(find.byKey(const ValueKey('category_comida')), findsNothing);
    expect(find.text('Original'), findsWidgets);
  });

  testWidgets('store header stays anchored to the top safe area on tall screens', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();
    await tester.pumpWidget(StorePreviewApp(controller: controller));
    await tester.pump();

    final back = find.byKey(const ValueKey('store_header_back_slot'));
    final shortTop = tester.getTopLeft(back).dy;

    tester.view.physicalSize = const Size(360, 860);
    await tester.pump();
    final tallTop = tester.getTopLeft(back).dy;

    expect(tallTop, closeTo(shortTop, 0.01));
    expect(tester.takeException(), isNull);
  });
}
