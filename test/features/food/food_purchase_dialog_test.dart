import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/food/presentation/food_purchase_dialog.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/data/in_memory_store_repository.dart';
import 'package:flutter_application_1/features/store/domain/store_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('purchase dialog hides food names and satiety', (tester) async {
    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FoodPurchaseDialog(storeController: controller)),
      ),
    );
    await tester.pump();

    expect(find.text('Hashtag'), findsNothing);
    expect(find.text('Like'), findsNothing);
    expect(find.text('Pastel aniversario'), findsNothing);
    expect(find.textContaining('saciedad'), findsNothing);
    expect(find.text('x0'), findsNWidgets(3));
  });

  testWidgets('one tap buys one unit and dialog stays mounted', (tester) async {
    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FoodPurchaseDialog(storeController: controller)),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('food_purchase_buy_food_1')));
    await tester.pumpAndSettle();

    expect(controller.foodQuantity('food_1'), 1);
    expect(find.byKey(const ValueKey('food_purchase_dialog')), findsOneWidget);
    expect(find.text('x1'), findsOneWidget);
  });

  testWidgets('food at 99 cannot be purchased again', (tester) async {
    final initial = StoreSnapshot.initial(coins: 500).copyWith(
      foodInventory: const <String, int>{
        'food_1': 99,
        'food_2': 0,
        'food_3': 0,
      },
    );
    final controller = StoreController(
      repository: InMemoryStoreRepository(initialSnapshot: initial),
    );
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FoodPurchaseDialog(storeController: controller)),
      ),
    );
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('food_purchase_buy_food_1')),
    );
    expect(button.onPressed, isNull);
    expect(controller.foodQuantity('food_1'), 99);
  });
  testWidgets(
    'short screens scroll food cards without moving header',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = StoreController(
        repository: InMemoryStoreRepository(),
      );
      await controller.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FoodPurchaseDialog(storeController: controller),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);

      final header = find.byKey(const ValueKey('food_purchase_header'));
      final list = find.byKey(const ValueKey('food_purchase_list'));
      final headerTopBefore = tester.getTopLeft(header).dy;

      await tester.drag(list, const Offset(0, -220));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('food_purchase_card_food_3')),
        findsOneWidget,
      );
      expect(tester.getTopLeft(header).dy, headerTopBefore);
      expect(tester.takeException(), isNull);
    },
  );

}
