import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/food/presentation/food_inventory_overlay.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/data/in_memory_store_repository.dart';
import 'package:flutter_application_1/features/store/domain/store_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('food quantities fit on a compact physical-phone layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = StoreController(
      repository: InMemoryStoreRepository(
        initialSnapshot: StoreSnapshot.initial(coins: 120).copyWith(
          foodInventory: const <String, int>{
            'food_1': 0,
            'food_2': 9,
            'food_3': 99,
          },
        ),
      ),
    );
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: <Widget>[
              FoodInventoryOverlay(
                storeController: controller,
                selectedFoodId: null,
                onFoodSelected: (_) {},
                onOpenPurchase: () {},
                onClose: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('x0'), findsOneWidget);
    expect(find.text('x9'), findsOneWidget);
    expect(find.text('x99'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
