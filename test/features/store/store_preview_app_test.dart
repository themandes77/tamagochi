import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/data/in_memory_store_repository.dart';
import 'package:flutter_application_1/features/store/presentation/store_preview_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders store balance and catalog', (tester) async {
    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();

    await tester.pumpWidget(StorePreviewApp(controller: controller));

    expect(find.text('Tienda'), findsWidgets);
    expect(find.text('200'), findsOneWidget);
    expect(find.text('Trajes'), findsOneWidget);
    expect(find.text('Aniversario'), findsOneWidget);
    expect(find.text('Techno'), findsOneWidget);

    await tester.tap(find.text('Fondos'));
    await tester.pump();

    expect(find.text('Fondo Original'), findsOneWidget);
    expect(find.text('Fondo Aniversario'), findsOneWidget);
  });

  testWidgets('buys and equips a real outfit from the catalog', (tester) async {
    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();

    await tester.pumpWidget(StorePreviewApp(controller: controller));

    await tester.tap(
      find.byKey(const ValueKey('store_item_outfit_anniversary')),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('100'));
    await tester.pump();

    expect(controller.coins, 100);
    expect(controller.ownedItemIds, contains('outfit_anniversary'));
    expect(find.text('Equipar'), findsOneWidget);

    await tester.tap(find.text('Equipar'));
    await tester.pump();

    expect(controller.equippedOutfitId, 'anniversary');
    expect(find.text('Equipado'), findsOneWidget);
  });
}
