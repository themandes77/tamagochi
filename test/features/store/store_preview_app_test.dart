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

    expect(find.text('500'), findsWidgets);
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
}
