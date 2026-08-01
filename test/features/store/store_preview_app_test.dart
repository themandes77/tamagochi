import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/data/in_memory_store_repository.dart';
import 'package:flutter_application_1/features/store/presentation/store_preview_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders store balance and catalog', (tester) async {
    _useMobileViewport(tester);
    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();

    await tester.pumpWidget(StorePreviewApp(controller: controller));

    expect(find.text('TIENDA'), findsOneWidget);
    expect(find.text('200'), findsOneWidget);
    expect(find.text('TRAJES'), findsOneWidget);
    expect(find.text('Aniversario'), findsOneWidget);
    expect(find.text('Techno'), findsOneWidget);

    await tester.tap(find.text('FONDOS'));
    await tester.pump();

    expect(find.text('Fondo Original'), findsOneWidget);
    expect(find.text('Fondo Aniversario'), findsOneWidget);
  });

  testWidgets('opens the owned-items personalization screen', (tester) async {
    _useMobileViewport(tester);
    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();

    await tester.pumpWidget(StorePreviewApp(controller: controller));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open_inventory')),
      300,
    );
    await tester.tap(find.byKey(const ValueKey('open_inventory')));
    await tester.pump();

    expect(find.text('PERSONALIZACIÓN'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open_store')),
      300,
    );
    expect(find.byKey(const ValueKey('open_store')), findsOneWidget);
    expect(find.text('Original'), findsWidgets);
  });

  testWidgets('buys and equips a real outfit from the catalog', (tester) async {
    _useMobileViewport(tester);
    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();

    await tester.pumpWidget(StorePreviewApp(controller: controller));

    final anniversaryAction = find.byKey(
      const ValueKey('store_action_outfit_anniversary'),
    );
    await tester.ensureVisible(anniversaryAction);
    await tester.tap(anniversaryAction);
    await tester.pump();

    expect(controller.coins, 100);
    expect(controller.ownedItemIds, contains('outfit_anniversary'));
    expect(find.text('Equipar'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.ensureVisible(anniversaryAction);
    await tester.tap(anniversaryAction);
    await tester.pump();

    expect(controller.equippedOutfitId, 'anniversary');
    expect(find.text('Equipado'), findsOneWidget);
  });
}

void _useMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
